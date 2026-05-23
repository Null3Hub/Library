--[[
    Apex UI Library - Player utilities
    Helpers for fetching the local player avatar and parsing keybind input.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerUtil = {}

function PlayerUtil.GetLocalPlayerHeadshot()
	local placeholder = "rbxassetid://0"
	if not LocalPlayer then
		return placeholder
	end

	local ok, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if ok and type(thumbnail) == "string" and thumbnail ~= "" then
		return thumbnail
	end

	return placeholder
end

function PlayerUtil.GetKeyCode(value, fallback)
	fallback = fallback or Enum.KeyCode.LeftAlt
	if typeof(value) == "EnumItem" then return value end
	if type(value) == "string" and Enum.KeyCode[value] then return Enum.KeyCode[value] end
	return fallback
end

return PlayerUtil
