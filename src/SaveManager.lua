--[[
    Apex UI Library - SaveManager
    Handles config persistence: save, load, delete, refresh, autoload.

    Usage:
        Library.SaveManager:SetFolder("MyHub")
        Library.SaveManager:BuildConfigPage(window)
        Library.SaveManager:LoadAutoload()

    Depends on executor filesystem APIs: writefile, readfile, isfile, isfolder,
    makefolder, listfiles, delfile. Falls back gracefully in Studio where these
    don't exist.
]]

local HttpService = game:GetService("HttpService")

-- Filesystem API guards: if running in Studio (no executor), stub them out
-- so the SaveManager doesn't crash. Operations will simply no-op.
local _writefile  = typeof(writefile) == "function" and writefile or nil
local _readfile   = typeof(readfile) == "function" and readfile or nil
local _isfile     = typeof(isfile) == "function" and isfile or nil
local _isfolder   = typeof(isfolder) == "function" and isfolder or nil
local _makefolder = typeof(makefolder) == "function" and makefolder or nil
local _listfiles  = typeof(listfiles) == "function" and listfiles or nil
local _delfile    = typeof(delfile) == "function" and delfile or nil

local FileSystemAPIs = {
	writefile = _writefile,
	readfile = _readfile,
	isfile = _isfile,
	isfolder = _isfolder,
	makefolder = _makefolder,
	listfiles = _listfiles,
	delfile = _delfile,
}

local function hasFileSystem(required)
	required = required or { "writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "delfile" }
	for _, name in ipairs(required) do
		if FileSystemAPIs[name] == nil then
			return false, "missing filesystem api: " .. name
		end
	end
	return true
end

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function sanitizeConfigName(name)
	local value = trim(name)
	if value == "" then return nil, "no config name" end
	if value == "." or value == ".." then return nil, "invalid config name" end
	if string.find(value, "..", 1, true) then return nil, "invalid config name" end

	local invalidChars = { "/", "\\", ":", "*", "?", "\"", "<", ">", "|" }
	for _, char in ipairs(invalidChars) do
		if string.find(value, char, 1, true) then
			return nil, "invalid config name"
		end
	end

	return value
end

local OptionsRegistry = require(script.Parent.OptionsRegistry)

local SaveManager = {}
SaveManager.Folder = "ApexConfigs"
SaveManager.Ignore = {}
SaveManager._InternalFlags = {
	SM_ConfigName = true,
	SM_ConfigList = true,
	SM_AutoLoad = true,
}

-- Type-specific serializers/deserializers
SaveManager.Parsers = {
	Toggle = {
		Save = function(flag, control)
			return { type = "Toggle", flag = flag, value = control.Value }
		end,
		Load = function(flag, data)
			local control = OptionsRegistry.Options[flag]
			if control then control:Set(data.value, true) end
		end,
	},
	Slider = {
		Save = function(flag, control)
			return { type = "Slider", flag = flag, value = control.Value }
		end,
		Load = function(flag, data)
			local control = OptionsRegistry.Options[flag]
			if control then control:Set(data.value, true) end
		end,
	},
	Input = {
		Save = function(flag, control)
			return { type = "Input", flag = flag, value = control.Value }
		end,
		Load = function(flag, data)
			local control = OptionsRegistry.Options[flag]
			if control and type(data.value) == "string" then control:Set(data.value, true) end
		end,
	},
	Dropdown = {
		Save = function(flag, control)
			return { type = "Dropdown", flag = flag, value = control.Value, multi = control.Multi }
		end,
		Load = function(flag, data)
			local control = OptionsRegistry.Options[flag]
			if control then control:Set(data.value, true) end
		end,
	},
	Keybind = {
		Save = function(flag, control)
			local val = control.Value
			return { type = "Keybind", flag = flag, value = typeof(val) == "EnumItem" and val.Name or tostring(val) }
		end,
		Load = function(flag, data)
			local control = OptionsRegistry.Options[flag]
			if control and data.value then control:Set(data.value, true) end
		end,
	},
}

function SaveManager:SetFolder(folder)
	self.Folder = trim(folder)
	if self.Folder == "" then self.Folder = "ApexConfigs" end
	self:_EnsureFolders()
end

function SaveManager:SetIgnoreFlags(list)
	for _, flag in ipairs(list) do
		self.Ignore[flag] = true
	end
end

function SaveManager:_EnsureFolders()
	local ok, err = hasFileSystem({ "isfolder", "makefolder" })
	if not ok then return false, err end

	local paths = { self.Folder, self.Folder .. "/configs" }
	for _, path in ipairs(paths) do
		local existsOk, exists = pcall(_isfolder, path)
		if not existsOk then return false, tostring(exists) end
		if not exists then
			local makeOk, makeErr = pcall(_makefolder, path)
			if not makeOk then return false, tostring(makeErr) end
		end
	end

	return true
end

function SaveManager:_ShouldIgnore(flag)
	return self._InternalFlags[flag] or self.Ignore[flag]
end

function SaveManager:Save(name)
	local configName, nameErr = sanitizeConfigName(name)
	if not configName then return false, nameErr end
	local fsOk, fsErr = hasFileSystem({ "writefile", "isfolder", "makefolder" })
	if not fsOk then return false, fsErr end
	local folderOk, folderErr = self:_EnsureFolders()
	if not folderOk then return false, folderErr end

	local data = { objects = {} }
	for flag, control in pairs(OptionsRegistry.Options) do
		if self:_ShouldIgnore(flag) then continue end
		local parser = self.Parsers[control.Type]
		if parser then
			table.insert(data.objects, parser.Save(flag, control))
		end
	end

	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then return false, "encode error" end

	local path = self.Folder .. "/configs/" .. configName .. ".json"
	local writeOk, writeErr = pcall(_writefile, path, encoded)
	if not writeOk then return false, "write error: " .. tostring(writeErr) end
	return true
end

function SaveManager:Load(name)
	local configName, nameErr = sanitizeConfigName(name)
	if not configName then return false, nameErr end
	local fsOk, fsErr = hasFileSystem({ "readfile", "isfile" })
	if not fsOk then return false, fsErr end
	local path = self.Folder .. "/configs/" .. configName .. ".json"
	local existsOk, exists = pcall(_isfile, path)
	if not existsOk then return false, tostring(exists) end
	if not exists then return false, "file not found" end

	local readOk, raw = pcall(_readfile, path)
	if not readOk then return false, "read error: " .. tostring(raw) end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or not data or not data.objects then return false, "decode error" end

	for _, entry in ipairs(data.objects) do
		local parser = self.Parsers[entry.type]
		if parser and entry.flag then
			task.spawn(function()
				parser.Load(entry.flag, entry)
			end)
		end
	end
	return true
end

function SaveManager:Delete(name)
	local configName, nameErr = sanitizeConfigName(name)
	if not configName then return false, nameErr end
	local fsOk, fsErr = hasFileSystem({ "isfile", "delfile" })
	if not fsOk then return false, fsErr end
	local path = self.Folder .. "/configs/" .. configName .. ".json"
	local existsOk, exists = pcall(_isfile, path)
	if not existsOk then return false, tostring(exists) end
	if exists then
		local deleteOk, deleteErr = pcall(_delfile, path)
		if not deleteOk then return false, "delete error: " .. tostring(deleteErr) end
		return true
	end
	return false, "file not found"
end

function SaveManager:GetConfigList()
	local fsOk = hasFileSystem({ "listfiles", "isfolder", "makefolder" })
	if not fsOk then return {} end
	local folderOk = self:_EnsureFolders()
	if not folderOk then return {} end
	local list = {}
	local listOk, files = pcall(_listfiles, self.Folder .. "/configs")
	if not listOk or type(files) ~= "table" then return list end
	for _, file in ipairs(files) do
		if string.sub(file, -5) == ".json" then
			local name = string.match(file, "([^/\\]+)%.json$")
			if name then
				table.insert(list, name)
			end
		end
	end
	return list
end

function SaveManager:SetAutoload(name)
	local hasName = name and trim(name) ~= ""
	local required = hasName and { "writefile", "isfolder", "makefolder" } or { "isfile", "delfile" }
	local fsOk = hasFileSystem(required)
	if not fsOk then return end
	if hasName then
		local folderOk = self:_EnsureFolders()
		if not folderOk then return end
	end

	if name and name ~= "" then
		local configName = sanitizeConfigName(name)
		if configName then
			pcall(_writefile, self.Folder .. "/autoload.txt", configName)
		end
	else
		local path = self.Folder .. "/autoload.txt"
		local existsOk, exists = pcall(_isfile, path)
		if existsOk and exists then
			pcall(_delfile, path)
		end
	end
end

function SaveManager:GetAutoload()
	local fsOk = hasFileSystem({ "isfile", "readfile" })
	if not fsOk then return nil end
	local path = self.Folder .. "/autoload.txt"
	local existsOk, exists = pcall(_isfile, path)
	if existsOk and exists then
		local readOk, raw = pcall(_readfile, path)
		if readOk then return raw end
	end
	return nil
end

function SaveManager:LoadAutoload()
	local name = self:GetAutoload()
	if name and name ~= "" then
		return self:Load(name)
	end
	return false, "no autoload config"
end

--- Build the full SaveManager page inside the given window.
-- Creates a PageSection, a Page, and a Section with all the config controls.
function SaveManager:BuildConfigPage(window)
	if not window then return end

	window:PageSection({ Name = "SAVE MANAGER" })
	local configPage = window:Page({ Name = "Config", Icone = "rbxassetid://94586681223401" })

	local section = configPage:Section("Config Settings", "Save, load and manage your configurations")

	-- Config name input
	local nameInput = section:Input({
		Title = "Config Name",
		Default = "",
		Flag = "SM_ConfigName",
		Placeholder = "Enter config name...",
	})

	-- Config list dropdown
	local configList = section:Dropdown({
		Title = "Config List",
		Values = self:GetConfigList(),
		Flag = "SM_ConfigList",
	})

	-- Refresh button
	section:Button("Refresh", function()
		configList:Refresh(self:GetConfigList())
	end)

	-- Delete button
	section:Button("Delete", function()
		local name = configList:Get()
		local ok, err = self:Delete(name)
		if ok then
			configList:Refresh(self:GetConfigList())
		else
			warn("[SaveManager] Delete failed:", err)
		end
	end)

	-- Save button
	section:Button("Save", function()
		local name = nameInput:Get()
		if name == "" then
			name = configList:Get()
		end
		local ok, err = self:Save(name)
		if ok then
			configList:Refresh(self:GetConfigList())
		else
			warn("[SaveManager] Save failed:", err)
		end
	end)

	-- Load button
	section:Button("Load", function()
		local name = configList:Get()
		local ok, err = self:Load(name)
		if not ok then
			warn("[SaveManager] Load failed:", err)
		end
	end)

	-- Auto Load toggle
	local autoloadName = self:GetAutoload()
	section:Toggle({
		Title = "Auto Load",
		Description = autoloadName and ("Current: " .. autoloadName) or "No autoload set",
		Default = autoloadName ~= nil,
		Flag = "SM_AutoLoad",
		Callback = function(enabled)
			if enabled then
				local name = configList:Get()
				if name and name ~= "" and name ~= "None" then
					self:SetAutoload(name)
				end
			else
				self:SetAutoload(nil)
			end
		end,
	})

	return configPage
end

return SaveManager
