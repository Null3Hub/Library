--[[
    Apex UI Library - Section class
    A "Section" lives inside a Page and hosts the interactive elements
    (Label, Button, Toggle, Slider, Dropdown, Input, Keybind).
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)
local Elements = require(script.Parent.Parent.Elements)

local Create        = Util.Create
local Stroke        = Util.Stroke
local IsForegroundInputBlocked = Util.IsForegroundInputBlocked

local THEME       = Theme.THEME
local FONT_REG    = Theme.FONT_REG
local FONT_SEMI   = Theme.FONT_SEMI
local TW_FAST     = Theme.TW_FAST
local Corner      = Util.Corner

local Section = {}
Section.__index = Section

function Section:_UpdateSize()
	local h = self.ElementsLayout.AbsoluteContentSize.Y
	self.ElementsList.Size = UDim2.new(1, 0, 0, h)
	self.ElementsClip.Size = UDim2.new(1, -36, 0, h)
	-- Store the desired height; Page:_ReflowSections() applies the X size
	-- according to the section's Mode (full width or 50%).
	self._BaseHeight = 52 + h + 18
	if self.Page and self.Page._ReflowSections then
		self.Page:_ReflowSections()
	elseif self.Page and self.Page.UpdateCanvas then
		self.Container.Size = UDim2.new(1, 0, 0, self._BaseHeight)
		self.Page:UpdateCanvas()
	end
end

function Section:_BaseElement(name, height)
	local elementHeight = height or 38
	local element = Create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, elementHeight),
		BackgroundColor3 = THEME.BG_BUTTON,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 10,
		Parent = self.ElementsList,
	})
	Corner(9, element)
	local elStroke = Stroke(element, THEME.BORDER, 1)

	local normalColor = THEME.BORDER
	local hoverColor = Color3.fromRGB(87, 84, 104)
	local normalAlpha = 0.12
	local hoverAlpha = 0.04

	self.Elements = self.Elements or {}
	table.insert(self.Elements, element)
	element:SetAttribute("ApexSearchable", true)
	element:SetAttribute("ApexBaseHeight", elementHeight)
	element:SetAttribute("ApexBaseBackgroundColor", THEME.BG_BUTTON)
	element:SetAttribute("ApexBaseBackgroundTransparency", normalAlpha)
	element:SetAttribute("ApexBaseStrokeColor", normalColor)
	element:SetAttribute("ApexBaseStrokeTransparency", 0)

	local function hasSearchStyle()
		local state = element:GetAttribute("ApexSearchState")
		return state ~= nil and state ~= "normal"
	end

	element.MouseEnter:Connect(function()
		if not element.Parent then return end
		if IsForegroundInputBlocked(element) then return end
		if hasSearchStyle() then return end
		TweenService:Create(elStroke, TW_FAST, { Color = hoverColor }):Play()
		TweenService:Create(element, TW_FAST, { BackgroundTransparency = hoverAlpha }):Play()
	end)

	element.MouseLeave:Connect(function()
		if not element.Parent then return end
		if hasSearchStyle() then return end
		TweenService:Create(elStroke, TW_FAST, { Color = normalColor }):Play()
		TweenService:Create(element, TW_FAST, { BackgroundTransparency = normalAlpha }):Play()
	end)

	return element, elStroke
end

function Section:_Title(parent, title, desc)
	parent:SetAttribute("ApexSearchTitle", tostring(title or "Element"))
	parent:SetAttribute("ApexSearchDescription", tostring(desc or ""))

	Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -118, 0, desc and 15 or 20),
		Position = UDim2.new(0, 12, 0, desc and 6 or 9),
		BackgroundTransparency = 1,
		Text = tostring(title or "Element"),
		Font = FONT_SEMI,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(235, 231, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = parent.ZIndex + 1,
		Parent = parent,
	})
	if desc then
		Create("TextLabel", {
			Name = "Desc",
			Size = UDim2.new(1, -118, 0, 13),
			Position = UDim2.new(0, 12, 0, 22),
			BackgroundTransparency = 1,
			Text = tostring(desc),
			Font = FONT_REG,
			TextSize = 10,
			TextColor3 = Color3.fromRGB(145, 139, 170),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = parent.ZIndex + 1,
			Parent = parent,
		})
	end
end

-- Public element builders. They simply forward to the matching module under Elements/.
function Section:Label(text, desc)
	return Elements.Label.Build(self, text, desc)
end

function Section:Button(text, callback, desc)
	return Elements.Button.Build(self, text, callback, desc)
end

function Section:Toggle(text, default, callback, desc)
	return Elements.Toggle.Build(self, text, default, callback, desc)
end

function Section:Slider(text, min, max, default, callback, desc)
	return Elements.Slider.Build(self, text, min, max, default, callback, desc)
end

function Section:Dropdown(configOrTitle, values, default, callback)
	return Elements.Dropdown.Build(self, configOrTitle, values, default, callback)
end

function Section:Input(text, default, callback, desc)
	return Elements.Input.Build(self, text, default, callback, desc)
end

function Section:Keybind(text, default, callback, desc)
	return Elements.Keybind.Build(self, text, default, callback, desc)
end

return Section
