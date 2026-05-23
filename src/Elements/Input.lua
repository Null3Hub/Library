--[[
    Apex UI Library - Section Element: Input
    Right-aligned compact text box.
]]

local Theme   = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local OptionsRegistry = require(script.Parent.Parent.OptionsRegistry)

local Create       = Util.Create
local Corner       = Util.Corner
local Stroke       = Util.Stroke
local ListLayout   = Util.ListLayout
local SafeCallback = Util.SafeCallback
local THEME        = Theme.THEME
local FONT_REG     = Theme.FONT_REG

local Input = {}

function Input.Build(section, textOrCfg, default, callback, desc)
	local cfg
	if type(textOrCfg) == "table" then
		cfg = textOrCfg
	else
		cfg = {
			Title = textOrCfg, Default = default,
			Callback = callback, Description = desc,
		}
	end

	local element = section:_BaseElement("ApexInput", cfg.Description and 46 or 42)
	section:_Title(element, cfg.Title or "Input", cfg.Description)
	local inputContainer = Create("Frame", {
		Name = "InputContainer",
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ZIndex = 11,
		Parent = element,
	})
	ListLayout(inputContainer, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, 0)

	local holder = Create("Frame", {
		Name = "InputHolder",
		Size = UDim2.new(0.65, 0, 0, 26),
		BackgroundColor3 = THEME.BG_SEARCH,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 1,
		ZIndex = 11,
		Parent = inputContainer,
	})
	Create("UISizeConstraint", {
		MinSize = Vector2.new(96, 26),
		MaxSize = Vector2.new(220, 26),
		Parent = holder,
	})
	Corner(7, holder)
	Stroke(holder, THEME.BORDER, 1)
	local box = Create("TextBox", {
		Name = "InputBox",
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(cfg.Default or ""),
		PlaceholderText = cfg.Placeholder or "Type here...",
		PlaceholderColor3 = Color3.fromRGB(95, 90, 112),
		Font = FONT_REG,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(236, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 12,
		Parent = holder,
	})

	local control = {
		Type = "Input",
		Flag = cfg.Flag,
		Instance = element,
		Value = box.Text,
		_changedListeners = {},
	}

	function control:Set(value, silent)
		box.Text = tostring(value or "")
		self.Value = box.Text
		if not silent then
			SafeCallback(cfg.Callback, box.Text)
			for _, fn in ipairs(self._changedListeners) do SafeCallback(fn, box.Text) end
		end
	end
	control.SetValue = control.Set
	function control:Get() return box.Text end
	function control:OnChanged(fn)
		if type(fn) == "function" then table.insert(self._changedListeners, fn) end
	end

	box.FocusLost:Connect(function()
		control.Value = box.Text
		SafeCallback(cfg.Callback, box.Text)
		for _, fn in ipairs(control._changedListeners) do SafeCallback(fn, box.Text) end
	end)

	if cfg.Flag then OptionsRegistry.Register(cfg.Flag, control) end

	section:_UpdateSize()
	return control
end

return Input
