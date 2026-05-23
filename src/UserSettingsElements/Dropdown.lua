--[[
    Apex UI Library - UserSettings Element: Dropdown (compact, no search)
]]

local TweenService = game:GetService("TweenService")

local Theme   = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local OptionsRegistry = require(script.Parent.Parent.OptionsRegistry)

local Create       = Util.Create
local Corner       = Util.Corner
local Stroke       = Util.Stroke
local Padding      = Util.Padding
local ListLayout   = Util.ListLayout
local SafeCallback = Util.SafeCallback
local ResolveIcon  = Util.ResolveIcon
local THEME        = Theme.THEME
local FONT_REG     = Theme.FONT_REG
local TW_FAST      = Theme.TW_FAST
local TW_DROPDOWN  = Theme.TW_DROPDOWN
local CORNER_MD    = Theme.CORNER_MD

local Dropdown = {}

function Dropdown.Build(section, configOrTitle, values, default, callback)
	local config = {}
	if type(configOrTitle) == "table" then
		config = configOrTitle
	else
		config.Title = tostring(configOrTitle or "Dropdown")
		config.Values = values or {}
		config.Default = default
		config.Callback = callback
	end

	local listValues = config.Values or config.Options or {}
	local selected = config.Default or listValues[1] or "None"
	local opened = false
	local setOpen
	local baseH = 34
	local itemH = 24
	local itemGap = 4
	local menuPad = 6

	local element = section:_BaseElement("SettingsDropdown", baseH)
	element.ClipsDescendants = true
	element.ZIndex = 142
	section:_Title(element, config.Title or "Dropdown", config.Description)

	local valueLabel = Create("TextLabel", {
		Size = UDim2.new(0, 116, 0, 20),
		Position = UDim2.new(1, -150, 0, 7),
		BackgroundTransparency = 1,
		Text = tostring(selected),
		Font = FONT_REG,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(178, 170, 210),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 146,
		Parent = element,
	})

	local control -- forward decl, populated near the end

	local arrow = Create("ImageLabel", {
		Name = "Chevron",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(1, -28, 0, 9),
		BackgroundTransparency = 1,
		Image = ResolveIcon("solar:alt-arrow-up-linear"),
		ImageColor3 = Color3.fromRGB(178, 170, 210),
		ImageTransparency = 0.08,
		Rotation = 180,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 146,
		Parent = element,
	})

	local menu = Create("Frame", {
		Name = "Menu",
		Size = UDim2.new(1, -8, 0, 0),
		Position = UDim2.new(0, 4, 0, baseH + 8),
		BackgroundColor3 = THEME.BG_SEARCH,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 147,
		Parent = element,
	})
	Corner(CORNER_MD, menu)

	local menuStroke = Stroke(menu, THEME.BORDER, 1)
	menuStroke.Transparency = 1
	Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, THEME.BORDER),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(87, 84, 104)),
			ColorSequenceKeypoint.new(1.00, THEME.BORDER),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.00),
			NumberSequenceKeypoint.new(0.18, 0.34),
			NumberSequenceKeypoint.new(0.50, 0.08),
			NumberSequenceKeypoint.new(0.82, 0.34),
			NumberSequenceKeypoint.new(1.00, 1.00),
		}),
		Parent = menuStroke,
	})

	Padding(menu, menuPad, menuPad, menuPad, menuPad)
	ListLayout(menu, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, itemGap)

	local function calcMenuHeight()
		local count = math.min(#listValues, 4)
		if count <= 0 then
			return menuPad * 2 + itemH
		end
		return (menuPad * 2) + (count * itemH) + (math.max(0, count - 1) * itemGap)
	end

	setOpen = function(state)
		if opened == state then return end
		opened = state
		local menuH = opened and calcMenuHeight() or 0
		local totalH = baseH + (opened and (menuH + 14) or 0)

		element.ZIndex = opened and 160 or 142
		menu.ZIndex = opened and 161 or 147

		TweenService:Create(element, TW_DROPDOWN, {
			Size = UDim2.new(1, 0, 0, totalH),
		}):Play()
		TweenService:Create(menu, TW_DROPDOWN, {
			Size = UDim2.new(1, -8, 0, menuH),
			BackgroundTransparency = opened and 0 or 1,
		}):Play()
		TweenService:Create(menuStroke, TW_FAST, { Transparency = opened and 0 or 1 }):Play()
		TweenService:Create(arrow, TW_DROPDOWN, {
			Rotation = opened and 0 or 180,
			ImageColor3 = opened and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(178, 170, 210),
			ImageTransparency = opened and 0 or 0.08,
		}):Play()

		task.delay(0.03, function()
			if section and section._UpdateSize then section:_UpdateSize() end
		end)
		task.delay(0.24, function()
			if section and section._UpdateSize then section:_UpdateSize() end
		end)
	end

	for _, valueItem in ipairs(listValues) do
		local item = Create("TextButton", {
			Name = "Item",
			Size = UDim2.new(1, 0, 0, itemH),
			BackgroundColor3 = THEME.BG_BUTTON,
			BackgroundTransparency = 0.03,
			BorderSizePixel = 0,
			Text = tostring(valueItem),
			TextColor3 = THEME.TEXT_SECONDARY,
			Font = FONT_REG,
			TextSize = 11,
			AutoButtonColor = false,
			ZIndex = 162,
			Parent = menu,
		})
		Corner(7, item)
		local itemStroke = Stroke(item, THEME.BORDER, 1)
		itemStroke.Transparency = 0.72
		item.MouseEnter:Connect(function()
			TweenService:Create(item, TW_FAST, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(itemStroke, TW_FAST, { Transparency = 0.38 }):Play()
		end)
		item.MouseLeave:Connect(function()
			TweenService:Create(item, TW_FAST, { BackgroundTransparency = 0.03 }):Play()
			TweenService:Create(itemStroke, TW_FAST, { Transparency = 0.72 }):Play()
		end)
		item.MouseButton1Click:Connect(function()
			selected = valueItem
			valueLabel.Text = tostring(selected)
			setOpen(false)
			if control then control.Value = selected end
			SafeCallback(config.Callback, selected)
			if control then
				for _, fn in ipairs(control._changedListeners) do SafeCallback(fn, selected) end
			end
		end)
	end

	local trigger = Create("TextButton", {
		Name = "Trigger",
		Size = UDim2.new(1, 0, 0, baseH),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 165,
		Parent = element,
	})
	trigger.MouseButton1Click:Connect(function() setOpen(not opened) end)

	control = {
		Type = "Dropdown",
		Flag = config.Flag,
		Instance = element,
		Value = selected,
		_changedListeners = {},
	}

	function control:Set(newValue, silent)
		selected = newValue
		self.Value = selected
		valueLabel.Text = tostring(selected)
		if not silent then
			SafeCallback(config.Callback, selected)
			for _, fn in ipairs(self._changedListeners) do SafeCallback(fn, selected) end
		end
	end

	function control:Get() return selected end
	function control:Open() setOpen(true) end
	function control:Close() setOpen(false) end
	function control:OnChanged(fn)
		if type(fn) == "function" then table.insert(self._changedListeners, fn) end
	end

	if config.Flag then OptionsRegistry.Register(config.Flag, control) end

	section:_UpdateSize()
	return control
end

return Dropdown
