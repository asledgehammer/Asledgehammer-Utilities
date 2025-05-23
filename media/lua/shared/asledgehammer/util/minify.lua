--[[

! Improved code from n1tehawk. (https://github.com/n1tehawk/lua-minify) !

MIT License

Copyright (c) 2017 Mark Langen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local readonly = require 'asledgehammer/util/readonly';

-- eyecandy to increase readability for empty if branches and keep luacheck happy
local function do_nothing() end

local function lookupify(tb)
	local t = {}
	for _, v in pairs(tb) do
		t[v] = true
	end
	return t
end

local function CountTable(tb, limit)
	local c, k = 0, next(tb, nil)
	while k ~= nil do
		c = c + 1
		if limit and (c >= limit) then
			break
		end
		k = next(tb, k)
	end
	return c
end

local indentation = '    ' -- normally either multiple spaces or "\t"
local function indentStr(level)
	return string.rep(indentation, level or 0)
end

local function FormatTable(tb, atIndent, ignoreFunc)
	-- Note: This is currently unused,
	-- and it might be better to check for a __tostring metamethod instead
	if type(tb.Print) == 'function' then
		return tb.Print()
	end
	-- set parameter defaults
	atIndent = atIndent or 0
	ignoreFunc = ignoreFunc or function()
		return false
	end

	local consecutiveIndex, useNewlines = 1, CountTable(tb, 2) > 1
	local baseIndent = indentStr(atIndent + 1)
	local out = {'{'} -- table of output strings
	if useNewlines then
		table.insert(out, '\n')
	end

	for k, v in pairs(tb) do
		local type_k, type_v = type(k), type(v) -- cache types, used multiple times
		if type_v ~= 'function' and not ignoreFunc(k) then
			if useNewlines then
				table.insert(out, baseIndent)
			end

			-- key
			if type_k == 'string' then
				if k:match("^[A-Za-z_][A-Za-z0-9_]*$") then
					table.insert(out, k) -- plain identifier key, no need to quote
				else
					-- bracket and quote key
					table.insert(out, '["')
					table.insert(out, k)
					table.insert(out, '"]')
				end
				table.insert(out, " = ")
			elseif type_k == 'number' and k == consecutiveIndex then
				-- as long as a "list"-type table has consecutive entries,
				-- there's no need to output the key
				consecutiveIndex = consecutiveIndex + 1
			else
				-- non-consecutive indices and non-string keys
				table.insert(out, '[')
				table.insert(out, tostring(k))
				table.insert(out, '] = ')
			end

			-- value
			if type_v == 'string' then
				table.insert(out, '"')
				table.insert(out, v)
				table.insert(out, '"')
			elseif type_v == 'table' then
				-- recursive output of table-type values
				table.insert(out,
					FormatTable(v, atIndent + (useNewlines and 1 or 0), ignoreFunc))
			else
				table.insert(out, tostring(v))
			end
			if next(tb, k) then
				table.insert(out, ',')
			end
			if useNewlines then
				table.insert(out, '\n')
			end
		end
	end
	if useNewlines then
		table.insert(out, indentStr(atIndent))
	end
	table.insert(out, '}')
	return table.concat(out)
end

local WhiteChars = lookupify{' ', '\n', '\t', '\r'}

local EscapeForCharacter = {['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'", ['\\'] = '\\'}

local CharacterForEscape = {['r'] = '\r', ['n'] = '\n', ['t'] = '\t', ['"'] = '"', ["'"] = "'", ['\\'] = '\\'}

local AllIdentStartChars = lookupify{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
                                     'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                                     's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                                     'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
                                     'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
                                     'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '_'}

local AllIdentChars = lookupify{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
                                'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                                's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                                'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
                                'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
                                'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '_',
                                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

local Digits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

local HexDigits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                            'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'}

local Symbols = lookupify{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#', '.', ':'}

local EqualSymbols = lookupify{'~', '=', '>', '<'}

local Keywords = lookupify{
    'and', 'break', 'do', 'else', 'elseif',
    'end', 'false', 'for', 'function', 'goto', 'if',
    'in', 'local', 'nil', 'not', 'or', 'repeat',
    'return', 'then', 'true', 'until', 'while',
}

local BlockFollowKeyword = lookupify{'else', 'elseif', 'until', 'end'}

local UnopSet = lookupify{'-', 'not', '#'}

local BinopSet = lookupify{
	'+', '-', '*', '/', '%', '^', '#',
	'..', '.', ':',
	'>', '<', '<=', '>=', '~=', '==',
	'and', 'or'
}

local GlobalRenameIgnore = lookupify{

}

local BinaryPriority = {
   ['+'] = {6, 6};
   ['-'] = {6, 6};
   ['*'] = {7, 7};
   ['/'] = {7, 7};
   ['%'] = {7, 7};
   ['^'] = {10, 9};
   ['..'] = {5, 4};
   ['=='] = {3, 3};
   ['~='] = {3, 3};
   ['>'] = {3, 3};
   ['<'] = {3, 3};
   ['>='] = {3, 3};
   ['<='] = {3, 3};
   ['and'] = {2, 2};
   ['or'] = {1, 1};
}
local UnaryPriority = 8

-- Eof, Ident, Keyword, Number, String, Symbol

-- decode string position to line and column number, with optional start values
local function _decode_position(text, pos, line, col)
	line, col = line or 1, col or 0
	if pos > 0 then
		if pos > text:len() then
			pos = text:len()
		end
		for i = 1, pos do
			col = col + 1
			if text:sub(i, i) == '\n' then
				line = line + 1
				col = 0
			end
		end
		if col == 0 then
			col = 1
		end
	end
	return line, col
end

local function CreateLuaTokenStream(text)
	-- Tracking for the current position in the buffer, and
	-- the current line / character we are on.
	local p = 1

	-- Output buffer for tokens
	local tokenBuffer = {}

	-- Get a character, or '' if at eof
	local function look(n)
		n = p + (n or 0)
		return text:sub(n, n)
	end
	local function get()
		local c = text:sub(p, p)
		p = p + 1
		return c
	end

	-- Error
	local function _error(str)
		local line, col = _decode_position(text, p)
		for _, token in pairs(tokenBuffer) do
			print(token.Type.."<"..token.Source..">")
		end
		error("file<"..line..":"..col..">: "..str)
	end

	-- Consume a long data with equals count of `eqcount'
	local function longdata(eqcount)
		while true do
			local c = get()
			if c == '' then
				_error("Unfinished long string.")
			elseif c == ']' then
				local done = true -- Until contested
				for _ = 1, eqcount do
					if look() == '=' then
						p = p + 1
					else
						done = false
						break
					end
				end
				if done and get() == ']' then
					return
				end
			end
		end
	end

	-- Get the opening part for a long data `[` `=`* `[`
	-- Precondition: The first `[` has been consumed
	-- Return: nil or the equals count
	local function getopen()
		local eqcount = 0
		while look(eqcount) == '=' do
			eqcount = eqcount + 1
		end
		if look(eqcount) == '[' then
			p = p + eqcount + 1
			return eqcount
		end
		return nil
	end

	local whiteStart, tokenStart -- used in main loop, upvalues for token()

	-- Add token
	local function token(type)
		local tk = {
			Type = type;
			LeadingWhite = text:sub(whiteStart, tokenStart-1);
			Source = text:sub(tokenStart, p-1);
		}
		table.insert(tokenBuffer, tk)
		return tk
	end

	-- Parse tokens loop
	while true do
		-- Mark the whitespace start
		whiteStart = p

		-- Get the leading whitespace + comments
		while true do
			local c = look()
			if c == '' then
				break
			elseif c == '-' then
				if look(1) == '-' then
					p = p + 2
					-- Consume comment body
					if look() == '[' then
						p = p + 1
						local eqcount = getopen()
						if eqcount then
							-- Long comment body
							longdata(eqcount)
						else
							-- Normal comment body
							local c2
							repeat
								c2 = get()
							until c2 == '' or c2 == '\n'
						end
					else
						-- Normal comment body
						local c2
						repeat
							c2 = get()
						until c2 == '' or c2 == '\n'
					end
				else
					break
				end
			elseif WhiteChars[c] then
				p = p + 1
			else
				break
			end
		end

		-- Mark the token start
		tokenStart = p

		-- Switch on token type
		local c1 = get()
		if c1 == '' then
			-- End of file
			token('Eof')
			break
		elseif c1 == '\'' or c1 == '\"' then
			-- String constant
			local c2
			repeat
				c2 = get()
				if c2 == '' then
					_error("Unfinished string.")
				elseif c2 == '\\' then
					local c3 = get()
					if not(Digits[c3] or CharacterForEscape[c3]) then
						_error("Invalid Escape Sequence `"..c3.."`.")
					end
				end
			until c2 == c1
			token('String')
		elseif AllIdentStartChars[c1] then
			-- Ident or Keyword
			while AllIdentChars[look()] do
				p = p + 1
			end
			if Keywords[text:sub(tokenStart, p-1)] then
				token('Keyword')
			else
				token('Ident')
			end
		elseif Digits[c1] or (c1 == '.' and Digits[look()]) then
			-- Number
			if c1 == '0' and look() == 'x' then
				p = p + 1
				-- Hex number
				while HexDigits[look()] do
					p = p + 1
				end
			else
				-- Normal Number
				while Digits[look()] do
					p = p + 1
				end
				if look() == '.' then
					-- With decimal point
					p = p + 1
					while Digits[look()] do
						p = p + 1
					end
				end
				if look() == 'e' or look() == 'E' then
					-- With exponent
					p = p + 1
					if look() == '-' then
						p = p + 1
					end
					while Digits[look()] do
						p = p + 1
					end
				end
			end
			token('Number')
		elseif c1 == '[' then
			-- '[' Symbol or Long String
			local eqCount = getopen()
			if eqCount then
				-- Long string
				longdata(eqCount)
				token('String')
			else
				-- Symbol
				token('Symbol')
			end
		elseif c1 == '.' then
			-- Greedily consume up to 3 `.` for . / .. / ... tokens
			if look() == '.' then
				get()
				if look() == '.' then
					get()
				end
			end
			token('Symbol')
		elseif EqualSymbols[c1] then
			if look() == '=' then
				p = p + 1
			end
			token('Symbol')
		elseif Symbols[c1] then
			token('Symbol')
		else
			_error("Bad symbol `"..c1.."` in source.")
		end
	end
	return tokenBuffer
end

local function CreateLuaParser(tokens)
	if type(tokens) == "string" then
		-- tokenize from string first
		tokens = CreateLuaTokenStream(tokens)
	end
	-- Token stream and pointer into it
	assert(type(tokens) == "table")
	-- for _, tok in pairs(tokens) do
	-- 	print(tok.Type..": "..tok.Source)
	-- end
	local p = 1

	local function get()
		local tok = tokens[p]
		if p < #tokens then
			p = p + 1
		end
		return tok
	end
	local function peek(n)
		n = p + (n or 0)
		return tokens[n] or tokens[#tokens]
	end

	local function getTokenStartPosition(token)
		local line, col = 1, 0
		local tkNum = 1
		repeat
			local tk = tokens[tkNum]
			tkNum = tkNum + 1
			local text = tk.LeadingWhite
			if tk ~= token then
				text = text .. tk.Source
			end
			line, col = _decode_position(text, #text, line, col)
		until tk == token
		return line..":"..(col+1)
	end
	local function debugMark()
		local tk = peek()
		return "<"..tk.Type.." `"..tk.Source.."`> at: "..getTokenStartPosition(tk)
	end

	local function isBlockFollow()
		local tok = peek()
		return tok.Type == 'Eof' or (tok.Type == 'Keyword' and BlockFollowKeyword[tok.Source])
	end
	local function isUnop()
		return UnopSet[peek().Source] or false
	end
	local function isBinop()
		return BinopSet[peek().Source] or false
	end
	local function expect(type, source, type2, source2)
		local tk = peek()
		if tk.Type == type and (source == nil or tk.Source == source) then
			return get()
		elseif tk.Type == type2 and (source2 == nil or tk.Source == source2) then
			return get()
		else
			for i = -3, 3 do
				print("Tokens["..i.."] = `"..peek(i).Source.."`")
			end
			if source then
				error(getTokenStartPosition(tk)..": `"..source.."` expected.")
			else
				error(getTokenStartPosition(tk)..": "..type
					  ..(type2 and (" or "..type2) or "")
					  .." expected.")
			end
		end
	end

	local function MkNode(node)
		local function _GetSelfToken(self)
			return self.Token
		end

		local getf = node.GetFirstToken or _GetSelfToken
		local getl = node.GetLastToken or _GetSelfToken
		function node:GetFirstToken()
			local t = getf(self)
			assert(t)
			return t
		end
		function node:GetLastToken()
			local t = getl(self)
			assert(t)
			return t
		end
		return node
	end

	-- Forward decls
	local block, expr

	-- Expression list
	local function exprlist()
		local exprList = {}
		local commaList = {}
		table.insert(exprList, expr())
		while peek().Source == ',' do
			table.insert(commaList, get())
			table.insert(exprList, expr())
		end
		return exprList, commaList
	end

	local function prefixexpr()
		local tk = peek()
		if tk.Source == '(' then
			local oparenTk = get()
			local inner = expr()
			local cparenTk = expect('Symbol', ')')
			return MkNode{
				Type = 'ParenExpr';
				Expression = inner;
				Token_OpenParen = oparenTk;
				Token_CloseParen = cparenTk;
				GetFirstToken = function(self)
					return self.Token_OpenParen
				end;
				GetLastToken = function(self)
					return self.Token_CloseParen
				end;
			}
		elseif tk.Type == 'Ident' then
			return MkNode{
				Type = 'VariableExpr';
				Token = get();
			}
		else
			print(debugMark())
			error(getTokenStartPosition(tk)..": Unexpected symbol")
		end
	end

	local function tableexpr()
		local obrace = expect('Symbol', '{')
		local entries = {}
		local separators = {}
		while peek().Source ~= '}' do
			if peek().Source == '[' then
				-- Index
				local obrac = get()
				local index = expr()
				local cbrac = expect('Symbol', ']')
				local eq = expect('Symbol', '=')
				local value = expr()
				table.insert(entries, {
					EntryType = 'Index';
					Index = index;
					Value = value;
					Token_OpenBracket = obrac;
					Token_CloseBracket = cbrac;
					Token_Equals = eq;
				})
			elseif peek().Type == 'Ident' and peek(1).Source == '=' then
				-- Field
				local field = get()
				local eq = get()
				local value = expr()
				table.insert(entries, {
					EntryType = 'Field';
					Field = field;
					Value = value;
					Token_Equals = eq;
				})
			else
				-- Value
				local value = expr()
				table.insert(entries, {
					EntryType = 'Value';
					Value = value;
				})
			end

			-- Comma or Semicolon separator
			if peek().Source == ',' or peek().Source == ';' then
				table.insert(separators, get())
			else
				break
			end
		end
		local cbrace = expect('Symbol', '}')
		return MkNode{
			Type = 'TableLiteral';
			EntryList = entries;
			Token_SeparatorList = separators;
			Token_OpenBrace = obrace;
			Token_CloseBrace = cbrace;
			GetFirstToken = function(self)
				return self.Token_OpenBrace
			end;
			GetLastToken = function(self)
				return self.Token_CloseBrace
			end;
		}
	end

	-- List of identifiers
	local function varlist(isFuncDecl)
		local varList, commaList, token = {}, {}, peek()
		if token.Type == 'Ident' then
			table.insert(varList, get())
		elseif isFuncDecl and (token.Source == '...') then
			table.insert(varList, get())
		end
		while peek().Source == ',' do
			table.insert(commaList, get())
			if isFuncDecl then
				token = expect('Ident', nil, 'Symbol', '...')
			else
				token = expect('Ident')
			end
			table.insert(varList, token)
		end
		return varList, commaList
	end

	-- Body
	local function blockbody(terminator)
		local body = block()
		local after = peek()
		if after.Type == 'Keyword' and after.Source == terminator then
			get()
			return body, after
		else
			print(after.Type, after.Source)
			error(getTokenStartPosition(after)..": "..terminator.." expected.")
		end
	end

	-- Function declaration
	local function funcdecl(isAnonymous)
		local functionKw = get()
		--
		local nameChain, nameChainSeparator
		--
		if not isAnonymous then
			nameChain = {}
			nameChainSeparator = {}
			--
			table.insert(nameChain, expect('Ident'))
			--
			while peek().Source == '.' do
				table.insert(nameChainSeparator, get())
				table.insert(nameChain, expect('Ident'))
			end
			if peek().Source == ':' then
				table.insert(nameChainSeparator, get())
				table.insert(nameChain, expect('Ident'))
			end
		end
		--
		local oparenTk = expect('Symbol', '(')
		local argList, argCommaList = varlist(true)
		local cparenTk = expect('Symbol', ')')
		local fbody, enTk = blockbody('end')
		--
		return MkNode{
			Type = (isAnonymous and 'FunctionLiteral' or 'FunctionStat');
			NameChain = nameChain;
			ArgList = argList;
			Body = fbody;
			--
			Token_Function = functionKw;
			Token_NameChainSeparator = nameChainSeparator;
			Token_OpenParen = oparenTk;
			Token_ArgCommaList = argCommaList;
			Token_CloseParen = cparenTk;
			Token_End = enTk;
			GetFirstToken = function(self)
				return self.Token_Function
			end;
			GetLastToken = function(self)
				return self.Token_End;
			end;
		}
	end

	-- Argument list passed to a function
	local function functionargs()
		local tk = peek()
		if tk.Source == '(' then
			local oparenTk = get()
			local argList = {}
			local argCommaList = {}
			while peek().Source ~= ')' do
				table.insert(argList, expr())
				if peek().Source == ',' then
					table.insert(argCommaList, get())
				else
					break
				end
			end
			local cparenTk = expect('Symbol', ')')
			return MkNode{
				CallType = 'ArgCall';
				ArgList = argList;
				--
				Token_CommaList = argCommaList;
				Token_OpenParen = oparenTk;
				Token_CloseParen = cparenTk;
				GetFirstToken = function(self)
					return self.Token_OpenParen
				end;
				GetLastToken = function(self)
					return self.Token_CloseParen
				end;
			}
		elseif tk.Source == '{' then
			return MkNode{
				CallType = 'TableCall';
				TableExpr = expr();
				GetFirstToken = function(self)
					return self.TableExpr:GetFirstToken()
				end;
				GetLastToken = function(self)
					return self.TableExpr:GetLastToken()
				end;
			}
		elseif tk.Type == 'String' then
			return MkNode{
				CallType = 'StringCall';
				Token = get();
			}
		else
			error("Function arguments expected.")
		end
	end

	local function callexpr(base)
		return MkNode{
			Type = 'CallExpr';
			Base = base;
			FunctionArguments = functionargs();
			GetFirstToken = function(self)
				return self.Base:GetFirstToken()
			end;
			GetLastToken = function(self)
				return self.FunctionArguments:GetLastToken()
			end;
		}
	end

	local function primaryexpr()
		local base = prefixexpr()
		assert(base, "nil prefixexpr")
		while true do
			local tk = peek()
			if tk.Source == '.' then
				local dotTk = get()
				local fieldName = expect('Ident')
				base = MkNode{
					Type = 'FieldExpr';
					Base = base;
					Field = fieldName;
					Token_Dot = dotTk;
					GetFirstToken = function(self)
						return self.Base:GetFirstToken()
					end;
					GetLastToken = function(self)
						return self.Field
					end;
				}
			elseif tk.Source == ':' then
				local colonTk = get()
				local methodName = expect('Ident')
				local fargs = functionargs()
				base = MkNode{
					Type = 'MethodExpr';
					Base = base;
					Method = methodName;
					FunctionArguments = fargs;
					Token_Colon = colonTk;
					GetFirstToken = function(self)
						return self.Base:GetFirstToken()
					end;
					GetLastToken = function(self)
						return self.FunctionArguments:GetLastToken()
					end;
				}
			elseif tk.Source == '[' then
				local obrac = get()
				local index = expr()
				local cbrac = expect('Symbol', ']')
				base = MkNode{
					Type = 'IndexExpr';
					Base = base;
					Index = index;
					Token_OpenBracket = obrac;
					Token_CloseBracket = cbrac;
					GetFirstToken = function(self)
						return self.Base:GetFirstToken()
					end;
					GetLastToken = function(self)
						return self.Token_CloseBracket
					end;
				}
			elseif tk.Source == '{' then
				base = callexpr(base) -- TableCall
			elseif tk.Source == '(' then
				base = callexpr(base) -- ArgCall
			elseif tk.Type == 'String' then
				base = callexpr(base) -- StringCall
			else
				return base
			end
		end
	end

	-- Create a "literal" node with a given type (string)
	local function literal(_type)
		return MkNode{
			Type = _type;
			Token = get();
		}
	end

	local function simpleexpr()
		local tk = peek()
		if tk.Type == 'Number' then
			return literal('NumberLiteral')
		elseif tk.Type == 'String' then
			return literal('StringLiteral')
		elseif tk.Source == 'nil' then
			return literal('NilLiteral')
		elseif tk.Source == 'true' or tk.Source == 'false' then
			return literal('BooleanLiteral')
		elseif tk.Source == '...' then
			return literal('VargLiteral')
		elseif tk.Source == '{' then
			return tableexpr()
		elseif tk.Source == 'function' then
			return funcdecl(true)
		else
			return primaryexpr()
		end
	end

	local function subexpr(limit)
		local curNode

		-- Initial Base Expression
		if isUnop() then
			local opTk = get()
			local ex = subexpr(UnaryPriority)
			curNode = MkNode{
				Type = 'UnopExpr';
				Token_Op = opTk;
				Rhs = ex;
				GetFirstToken = function(self)
					return self.Token_Op
				end;
				GetLastToken = function(self)
					return self.Rhs:GetLastToken()
				end;
			}
		else
			curNode = simpleexpr()
			assert(curNode, "nil simpleexpr")
		end

		-- Apply Precedence Recursion Chain
		while isBinop() and BinaryPriority[peek().Source][1] > limit do
			local opTk = get()
			local rhs = subexpr(BinaryPriority[opTk.Source][2])
			assert(rhs, "RhsNeeded")
			curNode = MkNode{
				Type = 'BinopExpr';
				Lhs = curNode;
				Rhs = rhs;
				Token_Op = opTk;
				GetFirstToken = function(self)
					return self.Lhs:GetFirstToken()
				end;
				GetLastToken = function(self)
					return self.Rhs:GetLastToken()
				end;
			}
		end

		-- Return result
		return curNode
	end

	-- Expression
	expr = function()
		return subexpr(0)
	end

	-- Expression statement
	local function exprstat()
		local ex = primaryexpr()
		if ex.Type == 'MethodExpr' or ex.Type == 'CallExpr' then
			-- all good, calls can be statements
			return MkNode{
				Type = 'CallExprStat';
				Expression = ex;
				GetFirstToken = function(self)
					return self.Expression:GetFirstToken()
				end;
				GetLastToken = function(self)
					return self.Expression:GetLastToken()
				end;
			}
		else
			-- Assignment expr
			local lhs = {ex}
			local lhsSeparator = {}
			while peek().Source == ',' do
				table.insert(lhsSeparator, get())
				local lhsPart = primaryexpr()
				if lhsPart.Type == 'MethodExpr' or lhsPart.Type == 'CallExpr' then
					error("Bad left hand side of assignment")
				end
				table.insert(lhs, lhsPart)
			end
			local eq = expect('Symbol', '=')
			local rhs = {expr()}
			local rhsSeparator = {}
			while peek().Source == ',' do
				table.insert(rhsSeparator, get())
				table.insert(rhs, expr())
			end
			return MkNode{
				Type = 'AssignmentStat';
				Rhs = rhs;
				Lhs = lhs;
				Token_Equals = eq;
				Token_LhsSeparatorList = lhsSeparator;
				Token_RhsSeparatorList = rhsSeparator;
				GetFirstToken = function(self)
					return self.Lhs[1]:GetFirstToken()
				end;
				GetLastToken = function(self)
					return self.Rhs[#self.Rhs]:GetLastToken()
				end;
			}
		end
	end

	-- If statement
	local function ifstat()
		local ifKw = get()
		local condition = expr()
		local thenKw = expect('Keyword', 'then')
		local ifBody = block()
		local elseClauses = {}
		while peek().Source == 'elseif' or peek().Source == 'else' do
			local elseifKw = get()
			local elseifCondition, elseifThenKw
			if elseifKw.Source == 'elseif' then
				elseifCondition = expr()
				elseifThenKw = expect('Keyword', 'then')
			end
			local elseifBody = block()
			table.insert(elseClauses, {
				Condition = elseifCondition;
				Body = elseifBody;
				--
				ClauseType = elseifKw.Source;
				Token = elseifKw;
				Token_Then = elseifThenKw;
			})
			if elseifKw.Source == 'else' then
				break
			end
		end
		local enKw = expect('Keyword', 'end')
		return MkNode{
			Type = 'IfStat';
			Condition = condition;
			Body = ifBody;
			ElseClauseList = elseClauses;
			--
			Token_If = ifKw;
			Token_Then = thenKw;
			Token_End = enKw;
			GetFirstToken = function(self)
				return self.Token_If
			end;
			GetLastToken = function(self)
				return self.Token_End
			end;
		}
	end

	-- Do statement
	local function dostat()
		local doKw = get()
		local body, enKw = blockbody('end')
		--
		return MkNode{
			Type = 'DoStat';
			Body = body;
			--
			Token_Do = doKw;
			Token_End = enKw;
			GetFirstToken = function(self)
				return self.Token_Do
			end;
			GetLastToken = function(self)
				return self.Token_End
			end;
		}
	end

	-- While statement
	local function whilestat()
		local whileKw = get()
		local condition = expr()
		local doKw = expect('Keyword', 'do')
		local body, enKw = blockbody('end')
		--
		return MkNode{
			Type = 'WhileStat';
			Condition = condition;
			Body = body;
			--
			Token_While = whileKw;
			Token_Do = doKw;
			Token_End = enKw;
			GetFirstToken = function(self)
				return self.Token_While
			end;
			GetLastToken = function(self)
				return self.Token_End
			end;
		}
	end

	-- For statement
	local function forstat()
		local forKw = get()
		local loopVars, loopVarCommas = varlist()
		if peek().Source == '=' then
			local eqTk = get()
			local exprList, exprCommaList = exprlist()
			if #exprList < 2 or #exprList > 3 then
				error("expected 2 or 3 values for range bounds")
			end
			local doTk = expect('Keyword', 'do')
			local body, enTk = blockbody('end')
			return MkNode{
				Type = 'NumericForStat';
				VarList = loopVars;
				RangeList = exprList;
				Body = body;
				--
				Token_For = forKw;
				Token_VarCommaList = loopVarCommas;
				Token_Equals = eqTk;
				Token_RangeCommaList = exprCommaList;
				Token_Do = doTk;
				Token_End = enTk;
				GetFirstToken = function(self)
					return self.Token_For
				end;
				GetLastToken = function(self)
					return self.Token_End
				end;
			}
		elseif peek().Source == 'in' then
			local inTk = get()
			local exprList, exprCommaList = exprlist()
			local doTk = expect('Keyword', 'do')
			local body, enTk = blockbody('end')
			return MkNode{
				Type = 'GenericForStat';
				VarList = loopVars;
				GeneratorList = exprList;
				Body = body;
				--
				Token_For = forKw;
				Token_VarCommaList = loopVarCommas;
				Token_In = inTk;
				Token_GeneratorCommaList = exprCommaList;
				Token_Do = doTk;
				Token_End = enTk;
				GetFirstToken = function(self)
					return self.Token_For
				end;
				GetLastToken = function(self)
					return self.Token_End
				end;
			}
		else
			error("`=` or in expected")
		end
	end

	-- Repeat statement
	local function repeatstat()
		local repeatKw = get()
		local body, untilTk = blockbody('until')
		local condition = expr()
		return MkNode{
			Type = 'RepeatStat';
			Body = body;
			Condition = condition;
			--
			Token_Repeat = repeatKw;
			Token_Until = untilTk;
			GetFirstToken = function(self)
				return self.Token_Repeat
			end;
			GetLastToken = function(self)
				return self.Condition:GetLastToken()
			end;
		}
	end

	-- Local var declaration
	local function localdecl()
		local localKw = get()
		if peek().Source == 'function' then
			-- Local function def
			local funcStat = funcdecl(false)
			if #funcStat.NameChain > 1 then
				error(getTokenStartPosition(funcStat.Token_NameChainSeparator[1])..": `(` expected.")
			end
			return MkNode{
				Type = 'LocalFunctionStat';
				FunctionStat = funcStat;
				Token_Local = localKw;
				GetFirstToken = function(self)
					return self.Token_Local
				end;
				GetLastToken = function(self)
					return self.FunctionStat:GetLastToken()
				end;
			}
		elseif peek().Type == 'Ident' then
			-- Local variable declaration
			local varList, varCommaList = varlist()
			local exprList, exprCommaList = {}, {}
			local eqToken
			if peek().Source == '=' then
				eqToken = get()
				exprList, exprCommaList = exprlist()
			end
			return MkNode{
				Type = 'LocalVarStat';
				VarList = varList;
				ExprList = exprList;
				Token_Local = localKw;
				Token_Equals = eqToken;
				Token_VarCommaList = varCommaList;
				Token_ExprCommaList = exprCommaList;
				GetFirstToken = function(self)
					return self.Token_Local
				end;
				GetLastToken = function(self)
					if #self.ExprList > 0 then
						return self.ExprList[#self.ExprList]:GetLastToken()
					else
						return self.VarList[#self.VarList]
					end
				end;
			}
		else
			error("`function` or ident expected")
		end
	end

	-- Return statement
	local function retstat()
		local returnKw = get()
		local exprList, commaList
		if isBlockFollow() or peek().Source == ';' then
			exprList = {}
			commaList = {}
		else
			exprList, commaList = exprlist()
		end
		return {
			Type = 'ReturnStat';
			ExprList = exprList;
			Token_Return = returnKw;
			Token_CommaList = commaList;
			GetFirstToken = function(self)
				return self.Token_Return
			end;
			GetLastToken = function(self)
				if #self.ExprList > 0 then
					return self.ExprList[#self.ExprList]:GetLastToken()
				else
					return self.Token_Return
				end
			end;
		}
	end

	-- Break statement
	local function breakstat()
		local breakKw = get()
		return {
			Type = 'BreakStat';
			Token_Break = breakKw;
			GetFirstToken = function(self)
				return self.Token_Break
			end;
			GetLastToken = function(self)
				return self.Token_Break
			end;
		}
	end

	-- Expression
	local function statement()
		local tok = peek()
		if tok.Source == 'if' then
			return false, ifstat()
		elseif tok.Source == 'while' then
			return false, whilestat()
		elseif tok.Source == 'do' then
			return false, dostat()
		elseif tok.Source == 'for' then
			return false, forstat()
		elseif tok.Source == 'repeat' then
			return false, repeatstat()
		elseif tok.Source == 'function' then
			return false, funcdecl(false)
		elseif tok.Source == 'local' then
			return false, localdecl()
		elseif tok.Source == 'return' then
			return true, retstat()
		elseif tok.Source == 'break' then
			return true, breakstat()
		else
			return false, exprstat()
		end
	end

	-- Chunk
	block = function()
		local statements = {}
		local semicolons = {}
		local isLast = false
		while not isLast and not isBlockFollow() do
			-- Parse statement
			local stat
			isLast, stat = statement()
			table.insert(statements, stat)
			local next = peek()
			if next.Type == 'Symbol' and next.Source == ';' then
				semicolons[#statements] = get()
			end
		end
		return {
			Type = 'StatList';
			StatementList = statements;
			SemicolonList = semicolons;
			GetFirstToken = function(self)
				if #self.StatementList == 0 then
					return nil
				else
					return self.StatementList[1]:GetFirstToken()
				end
			end;
			GetLastToken = function(self)
				if #self.StatementList == 0 then
					return nil
				elseif self.SemicolonList[#self.StatementList] then
					-- Last token may be one of the semicolon separators
					return self.SemicolonList[#self.StatementList]
				else
					return self.StatementList[#self.StatementList]:GetLastToken()
				end
			end;
		}
	end

	return block()
end

local function VisitAst(ast, visitors)
	local ExprType = lookupify{
		'BinopExpr'; 'UnopExpr';
		'NumberLiteral'; 'StringLiteral'; 'NilLiteral'; 'BooleanLiteral'; 'VargLiteral';
		'FieldExpr'; 'IndexExpr';
		'MethodExpr'; 'CallExpr';
		'FunctionLiteral';
		'VariableExpr';
		'ParenExpr';
		'TableLiteral';
	}

	local StatType = lookupify{
		'StatList';
		'BreakStat';
		'ReturnStat';
		'LocalVarStat';
		'LocalFunctionStat';
		'FunctionStat';
		'RepeatStat';
		'GenericForStat';
		'NumericForStat';
		'WhileStat';
		'DoStat';
		'IfStat';
		'CallExprStat';
		'AssignmentStat';
	}

	-- Check for typos in visitor construction
	for visitorSubject, _ in pairs(visitors) do
		if not StatType[visitorSubject] and not ExprType[visitorSubject] then
			error("Invalid visitor target: `"..visitorSubject.."`")
		end
	end

	-- Helpers to call visitors on a node
	local function preVisit(exprOrStat)
		local visitor = visitors[exprOrStat.Type]
		if type(visitor) == 'function' then
			return visitor(exprOrStat)
		elseif visitor and visitor.Pre then
			return visitor.Pre(exprOrStat)
		end
	end
	local function postVisit(exprOrStat)
		local visitor = visitors[exprOrStat.Type]
		if visitor and type(visitor) == 'table' and visitor.Post then
			return visitor.Post(exprOrStat)
		end
	end

	local visitExpr, visitStat

	visitExpr = function(expr)
		if preVisit(expr) then
			-- Handler did custom child iteration or blocked child iteration
			return
		end
		if expr.Type == 'BinopExpr' then
			visitExpr(expr.Lhs)
			visitExpr(expr.Rhs)
		elseif expr.Type == 'UnopExpr' then
			visitExpr(expr.Rhs)
		elseif expr.Type == 'NumberLiteral' or expr.Type == 'StringLiteral' or
			expr.Type == 'NilLiteral' or expr.Type == 'BooleanLiteral' or
			expr.Type == 'VargLiteral'
		then
			do_nothing() -- No children to visit, single token literals
		elseif expr.Type == 'FieldExpr' then
			visitExpr(expr.Base)
		elseif expr.Type == 'IndexExpr' then
			visitExpr(expr.Base)
			visitExpr(expr.Index)
		elseif expr.Type == 'MethodExpr' or expr.Type == 'CallExpr' then
			visitExpr(expr.Base)
			if expr.FunctionArguments.CallType == 'ArgCall' then
				for _, argExpr in pairs(expr.FunctionArguments.ArgList) do
					visitExpr(argExpr)
				end
			elseif expr.FunctionArguments.CallType == 'TableCall' then
				visitExpr(expr.FunctionArguments.TableExpr)
			end
		elseif expr.Type == 'FunctionLiteral' then
			visitStat(expr.Body)
		elseif expr.Type == 'VariableExpr' then
			do_nothing() -- No children to visit
		elseif expr.Type == 'ParenExpr' then
			visitExpr(expr.Expression)
		elseif expr.Type == 'TableLiteral' then
			for _, entry in pairs(expr.EntryList) do
				if entry.EntryType == 'Field' then
					visitExpr(entry.Value)
				elseif entry.EntryType == 'Index' then
					visitExpr(entry.Index)
					visitExpr(entry.Value)
				elseif entry.EntryType == 'Value' then
					visitExpr(entry.Value)
				else
					assert(false, "unreachable")
				end
			end
		else
			assert(false, "unreachable, type: "..expr.Type..":"..FormatTable(expr))
		end
		postVisit(expr)
	end

	visitStat = function(stat)
		if preVisit(stat) then
			-- Handler did custom child iteration or blocked child iteration
			return
		end
		if stat.Type == 'StatList' then
			for _, ch in pairs(stat.StatementList) do
				visitStat(ch)
			end
		elseif stat.Type == 'BreakStat' then
			do_nothing() -- No children to visit
		elseif stat.Type == 'ReturnStat' then
			for _, expr in pairs(stat.ExprList) do
				visitExpr(expr)
			end
		elseif stat.Type == 'LocalVarStat' then
			if stat.Token_Equals then
				for _, expr in pairs(stat.ExprList) do
					visitExpr(expr)
				end
			end
		elseif stat.Type == 'LocalFunctionStat' then
			visitStat(stat.FunctionStat.Body)
		elseif stat.Type == 'FunctionStat' then
			visitStat(stat.Body)
		elseif stat.Type == 'RepeatStat' then
			visitStat(stat.Body)
			visitExpr(stat.Condition)
		elseif stat.Type == 'GenericForStat' then
			for _, expr in pairs(stat.GeneratorList) do
				visitExpr(expr)
			end
			visitStat(stat.Body)
		elseif stat.Type == 'NumericForStat' then
			for _, expr in pairs(stat.RangeList) do
				visitExpr(expr)
			end
			visitStat(stat.Body)
		elseif stat.Type == 'WhileStat' then
			visitExpr(stat.Condition)
			visitStat(stat.Body)
		elseif stat.Type == 'DoStat' then
			visitStat(stat.Body)
		elseif stat.Type == 'IfStat' then
			visitExpr(stat.Condition)
			visitStat(stat.Body)
			for _, clause in pairs(stat.ElseClauseList) do
				if clause.Condition then
					visitExpr(clause.Condition)
				end
				visitStat(clause.Body)
			end
		elseif stat.Type == 'CallExprStat' then
			visitExpr(stat.Expression)
		elseif stat.Type == 'AssignmentStat' then
			for _, ex in pairs(stat.Lhs) do
				visitExpr(ex)
			end
			for _, ex in pairs(stat.Rhs) do
				visitExpr(ex)
			end
		else
			assert(false, "unreachable")
		end
		postVisit(stat)
	end

	if StatType[ast.Type] then
		visitStat(ast)
	else
		visitExpr(ast)
	end
end

local function AddVariableInfo(ast)
	local globalVars = {}
	local currentScope = nil

	-- Numbering generator for variable lifetimes
	local locationGenerator = 0
	local function markLocation()
		locationGenerator = locationGenerator + 1
		return locationGenerator
	end

	-- Scope management
	local function pushScope()
		currentScope = {
			ParentScope = currentScope;
			ChildScopeList = {};
			VariableList = {};
			BeginLocation = markLocation();
		}
		if currentScope.ParentScope then
			currentScope.Depth = currentScope.ParentScope.Depth + 1
			table.insert(currentScope.ParentScope.ChildScopeList, currentScope)
		else
			currentScope.Depth = 1
		end
		function currentScope:GetVar(varName)
			for _, var in pairs(self.VariableList) do
				if var.Name == varName then
					return var
				end
			end
			if self.ParentScope then
				return self.ParentScope:GetVar(varName)
			else
				for _, var in pairs(globalVars) do
					if var.Name == varName then
						return var
					end
				end
			end
		end
	end
	local function popScope()
		local scope = currentScope

		-- Mark where this scope ends
		scope.EndLocation = markLocation()

		-- Mark all of the variables in the scope as ending there
		for _, var in pairs(scope.VariableList) do
			var.ScopeEndLocation = scope.EndLocation
		end

		-- Move to the parent scope
		currentScope = scope.ParentScope

		return scope
	end
	pushScope() -- push initial scope

	-- Add / reference variables
	local function addLocalVar(name, setNameFunc, localInfo)
		assert(localInfo, "Missing localInfo")
		assert(name, "Missing local var name")
		local var = {
			Type = 'Local';
			Name = name;
			RenameList = {setNameFunc};
			AssignedTo = false;
			Info = localInfo;
			UseCount = 0;
			Scope = currentScope;
			BeginLocation = markLocation();
			EndLocation = markLocation();
			ReferenceLocationList = {markLocation()};
		}
		function var:Rename(newName)
			self.Name = newName
			for _, renameFunc in pairs(self.RenameList) do
				renameFunc(newName)
			end
		end
		function var:Reference()
			self.UseCount = self.UseCount + 1
		end
		table.insert(currentScope.VariableList, var)
		return var
	end
	local function getGlobalVar(name)
		for _, var in pairs(globalVars) do
			if var.Name == name then
				return var
			end
		end
		local var = {
			Type = 'Global';
			Name = name;
			RenameList = {};
			AssignedTo = false;
			UseCount = 0;
			Scope = nil; -- Globals have no scope
			BeginLocation = markLocation();
			EndLocation = markLocation();
			ReferenceLocationList = {};
		}
		function var:Rename(newName)
			self.Name = newName
			for _, renameFunc in pairs(self.RenameList) do
				renameFunc(newName)
			end
		end
		function var:Reference()
			self.UseCount = self.UseCount + 1
		end
		table.insert(globalVars, var)
		return var
	end
	local function addGlobalReference(name, setNameFunc)
		assert(name, "Missing var name")
		local var = getGlobalVar(name)
		table.insert(var.RenameList, setNameFunc)
		return var
	end
	local function getLocalVar(scope, name)
		-- First search this scope
		-- Note: Reverse iterate here because Lua does allow shadowing a local
		--       within the same scope, and the later defined variable should
		--       be the one referenced.
		for i = #scope.VariableList, 1, -1 do
			if scope.VariableList[i].Name == name then
				return scope.VariableList[i]
			end
		end

		-- Then search parent scope
		if scope.ParentScope then
			local var = getLocalVar(scope.ParentScope, name)
			if var then
				return var
			end
		end

		-- Then 
		return nil
	end
	local function referenceVariable(name, setNameFunc)
		assert(name, "Missing var name")
		local var = getLocalVar(currentScope, name)
		if var then
			table.insert(var.RenameList, setNameFunc)
		else
			var = addGlobalReference(name, setNameFunc)
		end
		-- Update the end location of where this variable is used, and
		-- add this location to the list of references to this variable.
		local curLocation = markLocation()
		var.EndLocation = curLocation
		table.insert(var.ReferenceLocationList, var.EndLocation)
		return var
	end

	local visitor = {}
	visitor.FunctionLiteral = {
		-- Function literal adds a new scope and adds the function literal arguments
		-- as local variables in the scope.
		Pre = function(expr)
			pushScope()
			for index, ident in pairs(expr.ArgList) do
				-- Note: Beware ident.Type == 'Symbol', it may be "..." here!
				if ident.Type == 'Ident' then
					addLocalVar(ident.Source,
						function(name)
							ident.Source = name
						end,
						{ Type = 'Argument';  Index = index; })
				end
			end
		end;
		Post = function()
			popScope()
		end;
	}
	visitor.VariableExpr = function(expr)
		-- Variable expression references from existing local variables
		-- in the current scope, annotating the variable usage with variable
		-- information.
		expr.Variable = referenceVariable(expr.Token.Source, function(newName)
			expr.Token.Source = newName
		end)
	end
	visitor.StatList = {
		-- StatList adds a new scope
		Pre = function()
			pushScope()
		end;
		Post = function()
			popScope()
		end;
	}
	visitor.LocalVarStat = {
		Post = function(stat)
			-- Local var stat adds the local variables to the current scope as locals
			-- We need to visit the subexpressions first, because these new locals
			-- will not be in scope for the initialization value expressions. That is:
			--  `local bar = bar + 1`
			-- Is valid code
			for varNum, ident in pairs(stat.VarList) do
				addLocalVar(ident.Source, function(name)
					stat.VarList[varNum].Source = name
				end, {
					Type = 'Local';
				})
			end
		end;
	}
	visitor.LocalFunctionStat = {
		Pre = function(stat)
			-- Local function stat adds the function itself to the current scope as
			-- a local variable, and creates a new scope with the function arguments
			-- as local variables.
			addLocalVar(stat.FunctionStat.NameChain[1].Source, function(name)
				stat.FunctionStat.NameChain[1].Source = name
			end, {
				Type = 'LocalFunction';
			})
			pushScope()
			for index, ident in pairs(stat.FunctionStat.ArgList) do
				-- Note: Beware ident.Type == 'Symbol', it may be "..." here!
				if ident.Type == 'Ident' then
					addLocalVar(ident.Source, function(name)
						ident.Source = name
					end, {
						Type = 'Argument';
						Index = index;
					})
				end
			end
		end;
		Post = function()
			popScope()
		end;
	}
	visitor.FunctionStat = {
		Pre = function(stat)
			-- Function stat adds a new scope containing the function arguments
			-- as local variables.
			-- A function stat may also assign to a global variable if it is in
			-- the form `function foo()` with no additional dots/colons in the 
			-- name chain.
			local nameChain = stat.NameChain
			local var
			if #nameChain == 1 then
				-- If there is only one item in the name chain, then the first item
				-- is a reference to a global variable.
				var = addGlobalReference(nameChain[1].Source, function(name)
					nameChain[1].Source = name
				end)
			else
				var = referenceVariable(nameChain[1].Source, function(name)
					nameChain[1].Source = name
				end)
			end
			var.AssignedTo = true
			pushScope()
			for index, ident in pairs(stat.ArgList) do
				-- Note: Beware ident.Type == 'Symbol', it may be "..." here!
				if ident.Type == 'Ident' then
					addLocalVar(ident.Source, function(name)
						ident.Source = name
					end, {
						Type = 'Argument';
						Index = index;
					})
				end
			end
		end;
		Post = function()
			popScope()
		end;
	}
	visitor.GenericForStat = {
		Pre = function(stat)
			-- Generic fors need an extra scope holding the range variables
			-- Need a custom visitor so that the generator expressions can be
			-- visited before we push a scope, but the body can be visited
			-- after we push a scope.
			for _, ex in pairs(stat.GeneratorList) do
				VisitAst(ex, visitor)
			end
			pushScope()
			for index, ident in pairs(stat.VarList) do
				addLocalVar(ident.Source, function(name)
					ident.Source = name
				end, {
					Type = 'ForRange';
					Index = index;
				})
			end
			VisitAst(stat.Body, visitor)
			popScope()
			return true -- Custom visit
		end;
	}
	visitor.NumericForStat = {
		Pre = function(stat)
			-- Numeric fors need an extra scope holding the range variables
			-- Need a custom visitor so that the generator expressions can be
			-- visited before we push a scope, but the body can be visited
			-- after we push a scope.
			for _, ex in pairs(stat.RangeList) do
				VisitAst(ex, visitor)
			end
			pushScope()
			for index, ident in pairs(stat.VarList) do
				addLocalVar(ident.Source, function(name)
					ident.Source = name
				end, {
					Type = 'ForRange';
					Index = index;
				})
			end
			VisitAst(stat.Body, visitor)
			popScope()
			return true	-- Custom visit
		end;
	}
	visitor.AssignmentStat = {
		Post = function(stat)
			-- For an assignment statement we need to mark the
			-- "assigned to" flag on variables.
			for _, ex in pairs(stat.Lhs) do
				if ex.Variable then
					ex.Variable.AssignedTo = true
				end
			end
		end;
	}

	VisitAst(ast, visitor)

	return globalVars, popScope()
end

-- Prints out an AST to stdout, or emits it by appending to a table
local function PrintAst(ast, tbl_out)
    local s = '';
	local printStat, printExpr

	local function printt(tk)
		if not tk.LeadingWhite or not tk.Source then
			error("Bad token: "..FormatTable(tk))
		end
		if tbl_out then
			table.insert(tbl_out, tk.LeadingWhite)
			table.insert(tbl_out, tk.Source)
		else
			s = s..tk.LeadingWhite
			s = s..tk.Source
		end
	end

	printExpr = function(expr)
		if expr.Type == 'BinopExpr' then
			printExpr(expr.Lhs)
			printt(expr.Token_Op)
			printExpr(expr.Rhs)
		elseif expr.Type == 'UnopExpr' then
			printt(expr.Token_Op)
			printExpr(expr.Rhs)
		elseif expr.Type == 'NumberLiteral' or expr.Type == 'StringLiteral' or
			expr.Type == 'NilLiteral' or expr.Type == 'BooleanLiteral' or
			expr.Type == 'VargLiteral'
		then
			-- Just print the token
			printt(expr.Token)
		elseif expr.Type == 'FieldExpr' then
			printExpr(expr.Base)
			printt(expr.Token_Dot)
			printt(expr.Field)
		elseif expr.Type == 'IndexExpr' then
			printExpr(expr.Base)
			printt(expr.Token_OpenBracket)
			printExpr(expr.Index)
			printt(expr.Token_CloseBracket)
		elseif expr.Type == 'MethodExpr' or expr.Type == 'CallExpr' then
			printExpr(expr.Base)
			if expr.Type == 'MethodExpr' then
				printt(expr.Token_Colon)
				printt(expr.Method)
			end
			if expr.FunctionArguments.CallType == 'StringCall' then
				printt(expr.FunctionArguments.Token)
			elseif expr.FunctionArguments.CallType == 'ArgCall' then
				printt(expr.FunctionArguments.Token_OpenParen)
				for index, argExpr in pairs(expr.FunctionArguments.ArgList) do
					printExpr(argExpr)
					local sep = expr.FunctionArguments.Token_CommaList[index]
					if sep then
						printt(sep)
					end
				end
				printt(expr.FunctionArguments.Token_CloseParen)
			elseif expr.FunctionArguments.CallType == 'TableCall' then
				printExpr(expr.FunctionArguments.TableExpr)
			end
		elseif expr.Type == 'FunctionLiteral' then
			printt(expr.Token_Function)
			printt(expr.Token_OpenParen)
			for index, arg in pairs(expr.ArgList) do
				printt(arg)
				local comma = expr.Token_ArgCommaList[index]
				if comma then
					printt(comma)
				end
			end
			printt(expr.Token_CloseParen)
			printStat(expr.Body)
			printt(expr.Token_End)
		elseif expr.Type == 'VariableExpr' then
			printt(expr.Token)
		elseif expr.Type == 'ParenExpr' then
			printt(expr.Token_OpenParen)
			printExpr(expr.Expression)
			printt(expr.Token_CloseParen)
		elseif expr.Type == 'TableLiteral' then
			printt(expr.Token_OpenBrace)
			for index, entry in pairs(expr.EntryList) do
				if entry.EntryType == 'Field' then
					printt(entry.Field)
					printt(entry.Token_Equals)
					printExpr(entry.Value)
				elseif entry.EntryType == 'Index' then
					printt(entry.Token_OpenBracket)
					printExpr(entry.Index)
					printt(entry.Token_CloseBracket)
					printt(entry.Token_Equals)
					printExpr(entry.Value)
				elseif entry.EntryType == 'Value' then
					printExpr(entry.Value)
				else
					assert(false, "unreachable")
				end
				local sep = expr.Token_SeparatorList[index]
				if sep then
					printt(sep)
				end
			end
			printt(expr.Token_CloseBrace)
		else
			assert(false, "unreachable, type: "..expr.Type..":"..FormatTable(expr))
		end
	end

	printStat = function(stat)
		if stat.Type == 'StatList' then
			for index, ch in pairs(stat.StatementList) do
				printStat(ch)
				if stat.SemicolonList[index] then
					printt(stat.SemicolonList[index])
				end
			end
		elseif stat.Type == 'BreakStat' then
			printt(stat.Token_Break)
		elseif stat.Type == 'ReturnStat' then
			printt(stat.Token_Return)
			for index, expr in pairs(stat.ExprList) do
				printExpr(expr)
				if stat.Token_CommaList[index] then
					printt(stat.Token_CommaList[index])
				end
			end
		elseif stat.Type == 'LocalVarStat' then
			printt(stat.Token_Local)
			for index, var in pairs(stat.VarList) do
				printt(var)
				local comma = stat.Token_VarCommaList[index]
				if comma then
					printt(comma)
				end
			end
			if stat.Token_Equals then
				printt(stat.Token_Equals)
				for index, expr in pairs(stat.ExprList) do
					printExpr(expr)
					local comma = stat.Token_ExprCommaList[index]
					if comma then
						printt(comma)
					end
				end
			end
		elseif stat.Type == 'LocalFunctionStat' then
			printt(stat.Token_Local)
			printt(stat.FunctionStat.Token_Function)
			printt(stat.FunctionStat.NameChain[1])
			printt(stat.FunctionStat.Token_OpenParen)
			for index, arg in pairs(stat.FunctionStat.ArgList) do
				printt(arg)
				local comma = stat.FunctionStat.Token_ArgCommaList[index]
				if comma then
					printt(comma)
				end
			end
			printt(stat.FunctionStat.Token_CloseParen)
			printStat(stat.FunctionStat.Body)
			printt(stat.FunctionStat.Token_End)
		elseif stat.Type == 'FunctionStat' then
			printt(stat.Token_Function)
			for index, part in pairs(stat.NameChain) do
				printt(part)
				local sep = stat.Token_NameChainSeparator[index]
				if sep then
					printt(sep)
				end
			end
			printt(stat.Token_OpenParen)
			for index, arg in pairs(stat.ArgList) do
				printt(arg)
				local comma = stat.Token_ArgCommaList[index]
				if comma then
					printt(comma)
				end
			end
			printt(stat.Token_CloseParen)
			printStat(stat.Body)
			printt(stat.Token_End)
		elseif stat.Type == 'RepeatStat' then
			printt(stat.Token_Repeat)
			printStat(stat.Body)
			printt(stat.Token_Until)
			printExpr(stat.Condition)
		elseif stat.Type == 'GenericForStat' then
			printt(stat.Token_For)
			for index, var in pairs(stat.VarList) do
				printt(var)
				local sep = stat.Token_VarCommaList[index]
				if sep then
					printt(sep)
				end
			end
			printt(stat.Token_In)
			for index, expr in pairs(stat.GeneratorList) do
				printExpr(expr)
				local sep = stat.Token_GeneratorCommaList[index]
				if sep then
					printt(sep)
				end
			end
			printt(stat.Token_Do)
			printStat(stat.Body)
			printt(stat.Token_End)
		elseif stat.Type == 'NumericForStat' then
			printt(stat.Token_For)
			for index, var in pairs(stat.VarList) do
				printt(var)
				local sep = stat.Token_VarCommaList[index]
				if sep then
					printt(sep)
				end
			end
			printt(stat.Token_Equals)
			for index, expr in pairs(stat.RangeList) do
				printExpr(expr)
				local sep = stat.Token_RangeCommaList[index]
				if sep then
					printt(sep)
				end
			end
			printt(stat.Token_Do)
			printStat(stat.Body)
			printt(stat.Token_End)
		elseif stat.Type == 'WhileStat' then
			printt(stat.Token_While)
			printExpr(stat.Condition)
			printt(stat.Token_Do)
			printStat(stat.Body)
			printt(stat.Token_End)
		elseif stat.Type == 'DoStat' then
			printt(stat.Token_Do)
			printStat(stat.Body)
			printt(stat.Token_End)
		elseif stat.Type == 'IfStat' then
			printt(stat.Token_If)
			printExpr(stat.Condition)
			printt(stat.Token_Then)
			printStat(stat.Body)
			for _, clause in pairs(stat.ElseClauseList) do
				printt(clause.Token)
				if clause.Condition then
					printExpr(clause.Condition)
					printt(clause.Token_Then)
				end
				printStat(clause.Body)
			end
			printt(stat.Token_End)
		elseif stat.Type == 'CallExprStat' then
			printExpr(stat.Expression)
		elseif stat.Type == 'AssignmentStat' then
			for index, ex in pairs(stat.Lhs) do
				printExpr(ex)
				local sep = stat.Token_LhsSeparatorList[index]
				if sep then
					printt(sep)
				end
			end
			printt(stat.Token_Equals)
			for index, ex in pairs(stat.Rhs) do
				printExpr(ex)
				local sep = stat.Token_RhsSeparatorList[index]
				if sep then
					printt(sep)
				end
			end
		else
			assert(false, "unreachable")
		end
	end

	printStat(ast);
    return s;
end

-- Get an actual string representation of the AST
local function AstToString(ast)
	local output = {}
	PrintAst(ast, output)
	return table.concat(output)
end

-- Adds / removes whitespace in an AST to put it into a "standard formatting"
local function FormatAst(ast)
	local formatStat, formatExpr

	local currentIndent = 0

	local function applyIndent(token)
		local indentString = '\n'..('\t'):rep(currentIndent)
		if token.LeadingWhite == '' or (token.LeadingWhite:sub(-#indentString, -1) ~= indentString) then
			-- Trim existing trailing whitespace on LeadingWhite
			-- Trim trailing tabs and spaces, and up to one newline
			token.LeadingWhite = token.LeadingWhite:gsub("\n?[\t ]*$", "")
			token.LeadingWhite = token.LeadingWhite..indentString
		end
	end

	local function indent()
		currentIndent = currentIndent + 1
	end

	local function undent()
		currentIndent = currentIndent - 1
		assert(currentIndent >= 0, "Undented too far")
	end

	local function leadingChar(tk)
		if #tk.LeadingWhite > 0 then
			return tk.LeadingWhite:sub(1,1)
		else
			return tk.Source:sub(1,1)
		end
	end

	local function padToken(tk)
		if not WhiteChars[leadingChar(tk)] then
			tk.LeadingWhite = ' '..tk.LeadingWhite
		end
	end

	local function padExpr(expr)
		padToken(expr:GetFirstToken())
	end

	local function formatBody(openToken, bodyStat, closeToken) -- luacheck: ignore 212
		indent()
		formatStat(bodyStat)
		undent()
		applyIndent(closeToken)
	end

	formatExpr = function(expr)
		if expr.Type == 'BinopExpr' then
			formatExpr(expr.Lhs)
			formatExpr(expr.Rhs)
			if expr.Token_Op.Source ~= '..' then -- No padding on ..
				padExpr(expr.Rhs)
				padToken(expr.Token_Op)
			end
		elseif expr.Type == 'UnopExpr' then
			formatExpr(expr.Rhs)
			--(expr.Token_Op)
		elseif expr.Type == 'NumberLiteral' or expr.Type == 'StringLiteral' or
			expr.Type == 'NilLiteral' or expr.Type == 'BooleanLiteral' or
			expr.Type == 'VargLiteral'
		then
			do_nothing()
			--(expr.Token)
		elseif expr.Type == 'FieldExpr' then
			formatExpr(expr.Base)
			--(expr.Token_Dot)
			--(expr.Field)
		elseif expr.Type == 'IndexExpr' then
			formatExpr(expr.Base)
			formatExpr(expr.Index)
			--(expr.Token_OpenBracket)
			--(expr.Token_CloseBracket)
		elseif expr.Type == 'MethodExpr' or expr.Type == 'CallExpr' then
			formatExpr(expr.Base)
			if expr.Type == 'MethodExpr' then
				do_nothing()
				--(expr.Token_Colon)
				--(expr.Method)
			end
			if expr.FunctionArguments.CallType == 'StringCall' then
				do_nothing() --(expr.FunctionArguments.Token)
			elseif expr.FunctionArguments.CallType == 'ArgCall' then
				--(expr.FunctionArguments.Token_OpenParen)
				for index, argExpr in pairs(expr.FunctionArguments.ArgList) do
					formatExpr(argExpr)
					if index > 1 then
						padExpr(argExpr)
					end
					--[[
					local sep = expr.FunctionArguments.Token_CommaList[index]
					if sep then
						--(sep)
					end
					--]]
				end
				--(expr.FunctionArguments.Token_CloseParen)
			elseif expr.FunctionArguments.CallType == 'TableCall' then
				formatExpr(expr.FunctionArguments.TableExpr)
			end
		elseif expr.Type == 'FunctionLiteral' then
			--(expr.Token_Function)
			--(expr.Token_OpenParen)
			for index, arg in pairs(expr.ArgList) do
				--(arg)
				if index > 1 then
					padToken(arg)
				end
				--[[
				local comma = expr.Token_ArgCommaList[index]
				if comma then
					--(comma)
				end
				--]]
			end
			--(expr.Token_CloseParen)
			formatBody(expr.Token_CloseParen, expr.Body, expr.Token_End)
		elseif expr.Type == 'VariableExpr' then
			do_nothing() --(expr.Token)
		elseif expr.Type == 'ParenExpr' then
			formatExpr(expr.Expression)
			--(expr.Token_OpenParen)
			--(expr.Token_CloseParen)
		elseif expr.Type == 'TableLiteral' then
			--(expr.Token_OpenBrace)
			if #expr.EntryList > 0 then
				indent()
				for _, entry in pairs(expr.EntryList) do
					if entry.EntryType == 'Field' then
						applyIndent(entry.Field)
						padToken(entry.Token_Equals)
						formatExpr(entry.Value)
						padExpr(entry.Value)
					elseif entry.EntryType == 'Index' then
						applyIndent(entry.Token_OpenBracket)
						formatExpr(entry.Index)
						--(entry.Token_CloseBracket)
						padToken(entry.Token_Equals)
						formatExpr(entry.Value)
						padExpr(entry.Value)
					elseif entry.EntryType == 'Value' then
						formatExpr(entry.Value)
						applyIndent(entry.Value:GetFirstToken())
					else
						assert(false, "unreachable")
					end
					--[[
					local sep = expr.Token_SeparatorList[index]
					if sep then
						--(sep)
					end
					--]]
				end
				undent()
				applyIndent(expr.Token_CloseBrace)
			end
			--(expr.Token_CloseBrace)
		else
			assert(false, "unreachable, type: "..expr.Type..":"..FormatTable(expr))
		end
	end

	formatStat = function(stat)
		if stat.Type == 'StatList' then
			for _, _stat in pairs(stat.StatementList) do
				formatStat(_stat)
				applyIndent(_stat:GetFirstToken())
			end

		elseif stat.Type == 'BreakStat' then
			do_nothing() --(stat.Token_Break)

		elseif stat.Type == 'ReturnStat' then
			--(stat.Token_Return)
			for index, expr in pairs(stat.ExprList) do
				formatExpr(expr)
				padExpr(expr)
				if stat.Token_CommaList[index] then
					do_nothing() --(stat.Token_CommaList[index])
				end
			end
		elseif stat.Type == 'LocalVarStat' then
			--(stat.Token_Local)
			for _, var in pairs(stat.VarList) do
				padToken(var)
				--[[
				local comma = stat.Token_VarCommaList[index]
				if comma then
					--(comma)
				end
				--]]
			end
			if stat.Token_Equals then
				padToken(stat.Token_Equals)
				for _, expr in pairs(stat.ExprList) do
					formatExpr(expr)
					padExpr(expr)
					--[[
					local comma = stat.Token_ExprCommaList[index]
					if comma then
						--(comma)
					end
					--]]
				end
			end
		elseif stat.Type == 'LocalFunctionStat' then
			--(stat.Token_Local)
			padToken(stat.FunctionStat.Token_Function)
			padToken(stat.FunctionStat.NameChain[1])
			--(stat.FunctionStat.Token_OpenParen)
			for index, arg in pairs(stat.FunctionStat.ArgList) do
				if index > 1 then
					padToken(arg)
				end
				--[[
				local comma = stat.FunctionStat.Token_ArgCommaList[index]
				if comma then
					--(comma)
				end
				--]]
			end
			--(stat.FunctionStat.Token_CloseParen)
			formatBody(stat.FunctionStat.Token_CloseParen, stat.FunctionStat.Body, stat.FunctionStat.Token_End)
		elseif stat.Type == 'FunctionStat' then
			--(stat.Token_Function)
			for index, part in pairs(stat.NameChain) do
				if index == 1 then
					padToken(part)
				end
				--[[
				local sep = stat.Token_NameChainSeparator[index]
				if sep then
					--(sep)
				end
				--]]
			end
			--(stat.Token_OpenParen)
			for index, arg in pairs(stat.ArgList) do
				if index > 1 then
					padToken(arg)
				end
				--[[
				local comma = stat.Token_ArgCommaList[index]
				if comma then
					--(comma)
				end
				--]]
			end
			--(stat.Token_CloseParen)
			formatBody(stat.Token_CloseParen, stat.Body, stat.Token_End)
		elseif stat.Type == 'RepeatStat' then
			--(stat.Token_Repeat)
			formatBody(stat.Token_Repeat, stat.Body, stat.Token_Until)
			formatExpr(stat.Condition)
			padExpr(stat.Condition)
		elseif stat.Type == 'GenericForStat' then
			--(stat.Token_For)
			for _, var in pairs(stat.VarList) do
				padToken(var)
				--[[
				local sep = stat.Token_VarCommaList[index]
				if sep then
					--(sep)
				end
				--]]
			end
			padToken(stat.Token_In)
			for _, expr in pairs(stat.GeneratorList) do
				formatExpr(expr)
				padExpr(expr)
				--[[
				local sep = stat.Token_GeneratorCommaList[index]
				if sep then
					--(sep)
				end
				--]]
			end
			padToken(stat.Token_Do)
			formatBody(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'NumericForStat' then
			--(stat.Token_For)
			for _, var in pairs(stat.VarList) do
				padToken(var)
				--[[
				local sep = stat.Token_VarCommaList[index]
				if sep then
					--(sep)
				end
				--]]
			end
			padToken(stat.Token_Equals)
			for _, expr in pairs(stat.RangeList) do
				formatExpr(expr)
				padExpr(expr)
				--[[
				local sep = stat.Token_RangeCommaList[index]
				if sep then
					--(sep)
				end
				--]]
			end
			padToken(stat.Token_Do)
			formatBody(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'WhileStat' then
			--(stat.Token_While)
			formatExpr(stat.Condition)
			padExpr(stat.Condition)
			padToken(stat.Token_Do)
			formatBody(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'DoStat' then
			--(stat.Token_Do)
			formatBody(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'IfStat' then
			--(stat.Token_If)
			formatExpr(stat.Condition)
			padExpr(stat.Condition)
			padToken(stat.Token_Then)
			--
			local lastBodyOpen = stat.Token_Then
			local lastBody = stat.Body
			--
			for _, clause in pairs(stat.ElseClauseList) do
				formatBody(lastBodyOpen, lastBody, clause.Token)
				lastBodyOpen = clause.Token
				--
				if clause.Condition then
					formatExpr(clause.Condition)
					padExpr(clause.Condition)
					padToken(clause.Token_Then)
					lastBodyOpen = clause.Token_Then
				end
				lastBody = clause.Body
			end
			--
			formatBody(lastBodyOpen, lastBody, stat.Token_End)

		elseif stat.Type == 'CallExprStat' then
			formatExpr(stat.Expression)
		elseif stat.Type == 'AssignmentStat' then
			for index, ex in pairs(stat.Lhs) do
				formatExpr(ex)
				if index > 1 then
					padExpr(ex)
				end
				--[[
				local sep = stat.Token_LhsSeparatorList[index]
				if sep then
					--(sep)
				end
				--]]
			end
			padToken(stat.Token_Equals)
			for _, ex in pairs(stat.Rhs) do
				formatExpr(ex)
				padExpr(ex)
				--[[
				local sep = stat.Token_RhsSeparatorList[index]
				if sep then
					--(sep)
				end
				--]]
			end
		else
			assert(false, "unreachable")
		end
	end

	formatStat(ast)
end

-- Strips as much whitespace off of tokens in an AST as possible without causing problems
local function StripAst(ast)
	local stripStat, stripExpr

	local function stript(token)
		token.LeadingWhite = ''
	end

	-- Make to adjacent tokens as close as possible
	local function joint(tokenA, tokenB)
		-- Strip the second token's whitespace
		stript(tokenB)

		-- Get the trailing A <-> leading B character pair
		local lastCh = tokenA.Source:sub(-1, -1)
		local firstCh = tokenB.Source:sub(1, 1)

		-- Cases to consider:
		--  Touching minus signs -> comment: `- -42` -> `--42' is invalid
		--  Touching words: `a b` -> `ab` is invalid
		--  Touching digits: `2 3`, can't occur in the Lua syntax as number literals aren't a primary expression
		--  Ambiguous syntax: `f(x)\n(x)()` is already disallowed, we can't cause a problem by removing newlines

		-- Figure out what separation is needed
		if
			(lastCh == '-' and firstCh == '-') or
			(AllIdentChars[lastCh] and AllIdentChars[firstCh])
		then
			tokenB.LeadingWhite = ' ' -- Use a separator
		else
			tokenB.LeadingWhite = '' -- Don't use a separator
		end
	end

	-- Join up a statement body and it's opening / closing tokens
	local function bodyjoint(open, body, close)
		stripStat(body)
		stript(close)
		local bodyFirst = body:GetFirstToken()
		local bodyLast = body:GetLastToken()
		if bodyFirst then
			-- Body is non-empty, join body to open / close
			joint(open, bodyFirst)
			joint(bodyLast, close)
		else
			-- Body is empty, just join open and close token together
			joint(open, close)
		end
	end

	stripExpr = function(expr)
		if expr.Type == 'BinopExpr' then
			stripExpr(expr.Lhs)
			stript(expr.Token_Op)
			stripExpr(expr.Rhs)
			-- Handle the `a - -b` -/-> `a--b` case which would otherwise incorrectly generate a comment
			-- Also handles operators "or" / "and" which definitely need joining logic in a bunch of cases
			joint(expr.Token_Op, expr.Rhs:GetFirstToken())
			joint(expr.Lhs:GetLastToken(), expr.Token_Op)
		elseif expr.Type == 'UnopExpr' then
			stript(expr.Token_Op)
			stripExpr(expr.Rhs)
			-- Handle the `- -b` -/-> `--b` case which would otherwise incorrectly generate a comment
			joint(expr.Token_Op, expr.Rhs:GetFirstToken())
		elseif expr.Type == 'NumberLiteral' or expr.Type == 'StringLiteral' or
			expr.Type == 'NilLiteral' or expr.Type == 'BooleanLiteral' or
			expr.Type == 'VargLiteral'
		then
			-- Just print the token
			stript(expr.Token)
		elseif expr.Type == 'FieldExpr' then
			stripExpr(expr.Base)
			stript(expr.Token_Dot)
			stript(expr.Field)
		elseif expr.Type == 'IndexExpr' then
			stripExpr(expr.Base)
			stript(expr.Token_OpenBracket)
			stripExpr(expr.Index)
			stript(expr.Token_CloseBracket)
		elseif expr.Type == 'MethodExpr' or expr.Type == 'CallExpr' then
			stripExpr(expr.Base)
			if expr.Type == 'MethodExpr' then
				stript(expr.Token_Colon)
				stript(expr.Method)
			end
			if expr.FunctionArguments.CallType == 'StringCall' then
				stript(expr.FunctionArguments.Token)
			elseif expr.FunctionArguments.CallType == 'ArgCall' then
				stript(expr.FunctionArguments.Token_OpenParen)
				for index, argExpr in pairs(expr.FunctionArguments.ArgList) do
					stripExpr(argExpr)
					local sep = expr.FunctionArguments.Token_CommaList[index]
					if sep then
						stript(sep)
					end
				end
				stript(expr.FunctionArguments.Token_CloseParen)
			elseif expr.FunctionArguments.CallType == 'TableCall' then
				stripExpr(expr.FunctionArguments.TableExpr)
			end
		elseif expr.Type == 'FunctionLiteral' then
			stript(expr.Token_Function)
			stript(expr.Token_OpenParen)
			for index, arg in pairs(expr.ArgList) do
				stript(arg)
				local comma = expr.Token_ArgCommaList[index]
				if comma then
					stript(comma)
				end
			end
			stript(expr.Token_CloseParen)
			bodyjoint(expr.Token_CloseParen, expr.Body, expr.Token_End)
		elseif expr.Type == 'VariableExpr' then
			stript(expr.Token)
		elseif expr.Type == 'ParenExpr' then
			stript(expr.Token_OpenParen)
			stripExpr(expr.Expression)
			stript(expr.Token_CloseParen)
		elseif expr.Type == 'TableLiteral' then
			stript(expr.Token_OpenBrace)
			for index, entry in pairs(expr.EntryList) do
				if entry.EntryType == 'Field' then
					stript(entry.Field)
					stript(entry.Token_Equals)
					stripExpr(entry.Value)
				elseif entry.EntryType == 'Index' then
					stript(entry.Token_OpenBracket)
					stripExpr(entry.Index)
					stript(entry.Token_CloseBracket)
					stript(entry.Token_Equals)
					stripExpr(entry.Value)
				elseif entry.EntryType == 'Value' then
					stripExpr(entry.Value)
				else
					assert(false, "unreachable")
				end
				local sep = expr.Token_SeparatorList[index]
				if sep then
					stript(sep)
				end
			end
			stript(expr.Token_CloseBrace)
		else
			assert(false, "unreachable, type: "..expr.Type..":"..FormatTable(expr))
		end
	end

	stripStat = function(stat)
		if stat.Type == 'StatList' then
			-- Strip all surrounding whitespace on statement lists along with separating whitespace
			for i = 1, #stat.StatementList do
				local chStat = stat.StatementList[i]

				-- Strip the statement and it's whitespace
				stripStat(chStat)
				stript(chStat:GetFirstToken())

				-- If there was a last statement, join them appropriately
				local lastChStat = stat.StatementList[i-1]
				if lastChStat then
					-- See if we can remove a semi-colon, the only case where we can't is if
					-- this and the last statement have a `);(` pair, where removing the semi-colon
					-- would introduce ambiguous syntax.
					if stat.SemicolonList[i-1] and
						(lastChStat:GetLastToken().Source ~= ')' or chStat:GetFirstToken().Source ~= '(')
					then
						stat.SemicolonList[i-1] = nil
					end

					-- If there isn't a semi-colon, we should safely join the two statements
					-- (If there is one, then no whitespace leading chStat is always okay)
					if not stat.SemicolonList[i-1] then
						joint(lastChStat:GetLastToken(), chStat:GetFirstToken())
					end
				end
			end

			-- A semi-colon is never needed on the last stat in a statlist:
			stat.SemicolonList[#stat.StatementList] = nil

			-- The leading whitespace on the statlist should be stripped
			if #stat.StatementList > 0 then
				stript(stat.StatementList[1]:GetFirstToken())
			end

		elseif stat.Type == 'BreakStat' then
			stript(stat.Token_Break)

		elseif stat.Type == 'ReturnStat' then
			stript(stat.Token_Return)
			for index, expr in pairs(stat.ExprList) do
				stripExpr(expr)
				if stat.Token_CommaList[index] then
					stript(stat.Token_CommaList[index])
				end
			end
			if #stat.ExprList > 0 then
				joint(stat.Token_Return, stat.ExprList[1]:GetFirstToken())
			end
		elseif stat.Type == 'LocalVarStat' then
			stript(stat.Token_Local)
			for index, var in pairs(stat.VarList) do
				if index == 1 then
					joint(stat.Token_Local, var)
				else
					stript(var)
				end
				local comma = stat.Token_VarCommaList[index]
				if comma then
					stript(comma)
				end
			end
			if stat.Token_Equals then
				stript(stat.Token_Equals)
				for index, expr in pairs(stat.ExprList) do
					stripExpr(expr)
					local comma = stat.Token_ExprCommaList[index]
					if comma then
						stript(comma)
					end
				end
			end
		elseif stat.Type == 'LocalFunctionStat' then
			stript(stat.Token_Local)
			joint(stat.Token_Local, stat.FunctionStat.Token_Function)
			joint(stat.FunctionStat.Token_Function, stat.FunctionStat.NameChain[1])
			joint(stat.FunctionStat.NameChain[1], stat.FunctionStat.Token_OpenParen)
			for index, arg in pairs(stat.FunctionStat.ArgList) do
				stript(arg)
				local comma = stat.FunctionStat.Token_ArgCommaList[index]
				if comma then
					stript(comma)
				end
			end
			stript(stat.FunctionStat.Token_CloseParen)
			bodyjoint(stat.FunctionStat.Token_CloseParen, stat.FunctionStat.Body, stat.FunctionStat.Token_End)
		elseif stat.Type == 'FunctionStat' then
			stript(stat.Token_Function)
			for index, part in pairs(stat.NameChain) do
				if index == 1 then
					joint(stat.Token_Function, part)
				else
					stript(part)
				end
				local sep = stat.Token_NameChainSeparator[index]
				if sep then
					stript(sep)
				end
			end
			stript(stat.Token_OpenParen)
			for index, arg in pairs(stat.ArgList) do
				stript(arg)
				local comma = stat.Token_ArgCommaList[index]
				if comma then
					stript(comma)
				end
			end
			stript(stat.Token_CloseParen)
			bodyjoint(stat.Token_CloseParen, stat.Body, stat.Token_End)
		elseif stat.Type == 'RepeatStat' then
			stript(stat.Token_Repeat)
			bodyjoint(stat.Token_Repeat, stat.Body, stat.Token_Until)
			stripExpr(stat.Condition)
			joint(stat.Token_Until, stat.Condition:GetFirstToken())
		elseif stat.Type == 'GenericForStat' then
			stript(stat.Token_For)
			for index, var in pairs(stat.VarList) do
				if index == 1 then
					joint(stat.Token_For, var)
				else
					stript(var)
				end
				local sep = stat.Token_VarCommaList[index]
				if sep then
					stript(sep)
				end
			end
			joint(stat.VarList[#stat.VarList], stat.Token_In)
			for index, expr in pairs(stat.GeneratorList) do
				stripExpr(expr)
				if index == 1 then
					joint(stat.Token_In, expr:GetFirstToken())
				end
				local sep = stat.Token_GeneratorCommaList[index]
				if sep then
					stript(sep)
				end
			end
			joint(stat.GeneratorList[#stat.GeneratorList]:GetLastToken(), stat.Token_Do)
			bodyjoint(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'NumericForStat' then
			stript(stat.Token_For)
			for index, var in pairs(stat.VarList) do
				if index == 1 then
					joint(stat.Token_For, var)
				else
					stript(var)
				end
				local sep = stat.Token_VarCommaList[index]
				if sep then
					stript(sep)
				end
			end
			joint(stat.VarList[#stat.VarList], stat.Token_Equals)
			for index, expr in pairs(stat.RangeList) do
				stripExpr(expr)
				if index == 1 then
					joint(stat.Token_Equals, expr:GetFirstToken())
				end
				local sep = stat.Token_RangeCommaList[index]
				if sep then
					stript(sep)
				end
			end
			joint(stat.RangeList[#stat.RangeList]:GetLastToken(), stat.Token_Do)
			bodyjoint(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'WhileStat' then
			stript(stat.Token_While)
			stripExpr(stat.Condition)
			stript(stat.Token_Do)
			joint(stat.Token_While, stat.Condition:GetFirstToken())
			joint(stat.Condition:GetLastToken(), stat.Token_Do)
			bodyjoint(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'DoStat' then
			stript(stat.Token_Do)
			stript(stat.Token_End)
			bodyjoint(stat.Token_Do, stat.Body, stat.Token_End)
		elseif stat.Type == 'IfStat' then
			stript(stat.Token_If)
			stripExpr(stat.Condition)
			joint(stat.Token_If, stat.Condition:GetFirstToken())
			joint(stat.Condition:GetLastToken(), stat.Token_Then)
			--
			local lastBodyOpen = stat.Token_Then
			local lastBody = stat.Body
			--
			for _, clause in pairs(stat.ElseClauseList) do
				bodyjoint(lastBodyOpen, lastBody, clause.Token)
				lastBodyOpen = clause.Token
				--
				if clause.Condition then
					stripExpr(clause.Condition)
					joint(clause.Token, clause.Condition:GetFirstToken())
					joint(clause.Condition:GetLastToken(), clause.Token_Then)
					lastBodyOpen = clause.Token_Then
				end
				stripStat(clause.Body)
				lastBody = clause.Body
			end
			--
			bodyjoint(lastBodyOpen, lastBody, stat.Token_End)

		elseif stat.Type == 'CallExprStat' then
			stripExpr(stat.Expression)
		elseif stat.Type == 'AssignmentStat' then
			for index, ex in pairs(stat.Lhs) do
				stripExpr(ex)
				local sep = stat.Token_LhsSeparatorList[index]
				if sep then
					stript(sep)
				end
			end
			stript(stat.Token_Equals)
			for index, ex in pairs(stat.Rhs) do
				stripExpr(ex)
				local sep = stat.Token_RhsSeparatorList[index]
				if sep then
					stript(sep)
				end
			end
		else
			assert(false, "unreachable")
		end
	end

	stripStat(ast)
end

local VarDigits = {}
for i = ('a'):byte(), ('z'):byte() do table.insert(VarDigits, string.char(i)) end
for i = ('A'):byte(), ('Z'):byte() do table.insert(VarDigits, string.char(i)) end
for i = ('0'):byte(), ('9'):byte() do table.insert(VarDigits, string.char(i)) end
table.insert(VarDigits, '_')
local VarStartDigits = {}
for i = ('a'):byte(), ('z'):byte() do table.insert(VarStartDigits, string.char(i)) end
for i = ('A'):byte(), ('Z'):byte() do table.insert(VarStartDigits, string.char(i)) end
local function indexToVarName(index)
	local id = ''
	local d = index % #VarStartDigits
	index = (index - d) / #VarStartDigits
	id = id..VarStartDigits[d+1]
	while index > 0 do
		d = index % #VarDigits
		index = (index - d) / #VarDigits
		id = id..VarDigits[d+1]
	end
	return id
end
local function MinifyVariables(globalScope, rootScope)
	-- externalGlobals is a set of global variables that have not been assigned to, that is
	-- global variables defined "externally to the script". We are not going to be renaming 
	-- those, and we have to make sure that we don't collide with them when renaming 
	-- things so we keep track of them in this set.
	local externalGlobals = {}

	-- First we want to rename all of the variables to unique temporaries, so that we can
	-- easily use the scope::GetVar function to check whether renames are valid.
	local temporaryIndex = 0
	for _, var in pairs(globalScope) do
		if var.AssignedTo then
			var:Rename('_TMP_'..temporaryIndex..'_')
			temporaryIndex = temporaryIndex + 1
		else
			-- Not assigned to, external global
			externalGlobals[var.Name] = true
		end
	end

	-- Now we go through renaming, first do globals, we probably want them
	-- to have shorter names in general.
	-- TODO: Rename all vars based on frequency patterns, giving variables
	--       used more shorter names.
	local nextFreeNameIndex = 0
	for _, var in pairs(globalScope) do
		if var.AssignedTo then
			local varName
			repeat
				varName = indexToVarName(nextFreeNameIndex)
				nextFreeNameIndex = nextFreeNameIndex + 1
			until not Keywords[varName] and not externalGlobals[varName]
			var:Rename(varName)
		end
	end

	-- Now rename all local vars
	rootScope.FirstFreeName = nextFreeNameIndex
	local function doRenameScope(scope)
		for _, var in pairs(scope.VariableList) do
			local varName
			repeat
				varName = indexToVarName(scope.FirstFreeName)
				scope.FirstFreeName = scope.FirstFreeName + 1
			until not Keywords[varName] and not externalGlobals[varName]
			var:Rename(varName)
		end
		for _, childScope in pairs(scope.ChildScopeList) do
			childScope.FirstFreeName = scope.FirstFreeName
			doRenameScope(childScope)
		end
	end
	doRenameScope(rootScope)
end

local function BeautifyVariables(globalScope, rootScope)

	local localNumber = 1
	local globalNumber = 1

	local function setVarName(var, name)
		var.Name = name
		for _, setter in pairs(var.RenameList) do
			setter(name)
		end
	end

	for _, var in pairs(globalScope) do
		if var.AssignedTo then
			setVarName(var, 'G_'..globalNumber)
			globalNumber = globalNumber + 1
		end
	end

	local function modify(scope)
		for _, var in pairs(scope.VariableList) do
			local name = 'L_'..localNumber..'_'
			if var.Info.Type == 'Argument' then
				name = name..'arg'..var.Info.Index
			elseif var.Info.Type == 'LocalFunction' then
				name = name..'func'
			elseif var.Info.Type == 'ForRange' then
				name = name..'forvar'..var.Info.Index
			end
			setVarName(var, name)
			localNumber = localNumber + 1
		end
		for _, child in pairs(scope.ChildScopeList) do
			modify(child)
		end
	end
	modify(rootScope)
end

local minify = {};
--- @param code string
--- @return string
function minify.minify(code)
    local ast = CreateLuaParser(code);
    local global_scope, root_scope = AddVariableInfo(ast);
    MinifyVariables(global_scope, root_scope);
    StripAst(ast);
    return PrintAst(ast);
end

--- @param code string
--- @return string
function minify.beautify(code)
    local ast = CreateLuaParser(code);
    local global_scope, root_scope = AddVariableInfo(ast);
    BeautifyVariables(global_scope, root_scope);
    FormatAst(ast);
    return PrintAst(ast);
end

return readonly(minify);
