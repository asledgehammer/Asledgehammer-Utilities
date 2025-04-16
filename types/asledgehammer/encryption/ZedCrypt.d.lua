--- @meta asledgehammer_utilities.encrypt.ZedCrypt

---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

--- @class ZedCrypt A simple key-shift string-encryptor for Project Zomboid mods.
ZedCrypt = {};

--- Immediately encrypts a string with a given key.
---
--- @param data string The string to encrypt.
--- @param key string The key used to encrypt the data.
---
--- @return string encryptedData The encrypted data.
function ZedCrypt.encrypt(data, key) end

--- Immediately decrypts a string with a given key.
---
--- @param data string The encrypted string.
--- @param key string The key used to decrypt the data.
---
--- @return string decryptedData The decrypted data.
function ZedCrypt.decrypt(data, key) end

--- Passively encrypts a string with a given key over a period of tick(s).
---
--- @param data string The string to encrypt.
--- @param key string The key used to encrypt the data.
--- @param steps? number (Default: 128 steps per tick)
---
--- @return thread encryptThread The thread that is resumed until complete. Run over tick(s).
function ZedCrypt.encryptAsync(data, key, steps) end

--- Passively decrypts a string with a given key over a period of tick(s).
---
--- @param data string The encrypted string.
--- @param key string The key used to decrypt the data.
--- @param steps? number (Default: 128 steps per tick)
---
--- @return thread decryptThread The thread that is resumed until complete. Run over tick(s).
function ZedCrypt.decryptAsync(data, key, steps) end
