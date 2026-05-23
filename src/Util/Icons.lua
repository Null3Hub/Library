--[[
    Apex UI Library - Icons module

    Native icon resolver powered by Footagesus/Icons Main-v2.
    Supports raw image ids and named icon keys:
        Icone = "rbxassetid://123"
        Icone = "house"
        Icone = "lucide:house"
        Icone = "geist:accessibility-unread"
        Icone = "sfsymbols:HouseFill"

    The module exposes a small API:
        Icons.Resolve(icon, iconType) -> image (string), isImage (boolean)
        Icons.SetIconsType(iconType)
        Icons.GetIcon(icon, iconType)   -> image (string only)
        Icons.GetModule()               -> raw IconsV2 module (or nil)
]]

local Icons = {}

local ICONS_V2_URL = "https://raw.githubusercontent.com/Footagesus/Icons/58f2a4994f75d035472bdeb0ca276bd5bafc3282/Main-v2.lua"

local IconsV2
local IconsV2Loaded = false
Icons.DefaultIconsType = "lucide"

local function IsImageSource(value)
	if type(value) ~= "string" then return false end
	return string.find(value, "rbxassetid://", 1, true) ~= nil
		or string.find(value, "rbxthumb://", 1, true) ~= nil
		or string.find(value, "http://", 1, true) ~= nil
		or string.find(value, "https://", 1, true) ~= nil
end
Icons.IsImageSource = IsImageSource

local function LoadIconsV2()
	if IconsV2Loaded then return IconsV2 end
	IconsV2Loaded = true

	local ok, result = pcall(function()
		local source
		if game.HttpGetAsync then
			source = game:HttpGetAsync(ICONS_V2_URL)
		else
			source = game:HttpGet(ICONS_V2_URL)
		end
		local loader = loadstring(source)
		return loader and loader()
	end)

	if ok and type(result) == "table" then
		IconsV2 = result
		if type(IconsV2.SetIconsType) == "function" then
			pcall(IconsV2.SetIconsType, Icons.DefaultIconsType)
		end
	else
		warn("[ApexLibrary] Failed to load IconsV2:", result)
	end

	return IconsV2
end
Icons.LoadIconsV2 = LoadIconsV2

function Icons.Resolve(icon, iconType)
	if icon == nil then
		return "⊞", false
	end

	local raw = tostring(icon)
	if raw == "" then
		return "⊞", false
	end

	if IsImageSource(raw) then
		return raw, true
	end

	local mod = LoadIconsV2()
	if mod and type(mod.GetIcon) == "function" then
		local query = raw
		if iconType and iconType ~= "" and not string.find(raw, ":", 1, true) then
			query = tostring(iconType) .. ":" .. raw
		end

		local ok, image = pcall(mod.GetIcon, query)
		if ok and type(image) == "string" and image ~= "" then
			return image, true
		end
	end

	-- Fallback: use the Apex logo when icon name can't be resolved
	return "rbxassetid://94586681223401", true
end

function Icons.SetIconsType(iconType)
	Icons.DefaultIconsType = tostring(iconType or "lucide")
	local mod = LoadIconsV2()
	if mod and type(mod.SetIconsType) == "function" then
		pcall(mod.SetIconsType, Icons.DefaultIconsType)
	end
end

function Icons.GetIcon(icon, iconType)
	local image = Icons.Resolve(icon, iconType or Icons.DefaultIconsType)
	return image
end

function Icons.GetModule()
	return LoadIconsV2()
end

return Icons
