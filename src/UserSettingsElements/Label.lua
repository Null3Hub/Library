--[[
    Apex UI Library - UserSettings Element: Label (compact)
]]

local Label = {}

function Label.Build(section, text, desc)
	local element = section:_BaseElement("SettingsLabel", desc and 40 or 34)
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
