--- @meta asledgehammer_utilities.network.packet

---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

--- @class Packet TODO: Document.
--- @field module string
--- @field command string
--- @field data table | nil
--- @field encrypted table | nil
--- @field valid boolean
local Packet = {};

--- @param player IsoPlayer
function Packet:sendToPlayer(player) end

function Packet:sendToServer() end

--- @param key string
--- @param player IsoPlayer
function Packet:encryptAndSendToPlayer(key, player) end

--- @param key string
function Packet:encryptAndSendToServer(key) end

--- @param key string
--- @param callback PacketCallback | nil
--- @param options PacketEncryptionOptions | nil
function Packet:encrypt(key, callback, options) end

--- @param key string
--- @param callback PacketCallback | nil
function Packet:decrypt(key, callback) end

--- Prints a JSON string or the packet.
---
--- @return void
function Packet:toJSON() end
