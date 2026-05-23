--[[
    Apex UI Library - UserSettings Element: Special
    Free-form element. Calls a render function so the user can put anything inside.
]]

local Util = require(script.Parent.Parent.Util)
local SafeCallback = Util.SafeCallback

local Special = {}

function Special.Build(section, first)
	local args = type(first) == "table" and first or { Title = first }
	args.Title = tostring(args.Title or args.Name or "Special")

	local element = section:_BaseElement(args.Name or "SettingsSpecial", tonumber(args.Height) or 34)
	if type(args.Render) == "function" then
		SafeCallback(args.Render, element, section.Window, section)
	else
		section:_Title(element, args.Title, args.Description)
	end
	section:_UpdateSize()
	return element
end

return Special
