--[[
    Apex UI Library - Section Element: Label
    Read-only badge labelled "Apex" on the right side, mirroring the original.
]]

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)

local THEME = Theme.THEME
local Create     = Util.Create
local Corner     = Util.Corner
local Stroke     = Util.Stroke
local FONT_SEMI  = Theme.FONT_SEMI

local Label = {}

function Label.Build(section, text, desc)
	local element = section:_BaseElement("ApexLabel", desc and 44 or 38)
	section:_Title(element, text or "Label", desc)

	section:_UpdateSize()

	return {
		Instance = element,
		Set = function(_, value)
			local t = element:FindFirstChild("Title")
			if t then t.Text = tostring(value) end
		end,
	}
end

return Label
