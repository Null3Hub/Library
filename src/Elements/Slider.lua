--[[
    Apex UI Library - Section Element: Slider
    Numeric slider with gradient fill and live value label.

    Positional or config-table API. When `Flag` is provided the control is
    registered in Library.Options so it can be saved/loaded.
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme   = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local OptionsRegistry = require(script.Parent.Parent.OptionsRegistry)

local Create       = Util.Create
local Corner       = Util.Corner
local SafeCallback = Util.SafeCallback
local THEME        = Theme.THEME
local FONT_SEMI    = Theme.FONT_SEMI
local TW_FAST      = Theme.TW_FAST

local Slider = {}

function Slider.Build(section, textOrCfg, min, max, default, callback, desc)
	local cfg
	if type(textOrCfg) == "table" then
		cfg = textOrCfg
	else
		cfg = {
			Title = textOrCfg, Min = min, Max = max,
			Default = default, Callback = callback, Description = desc,
		}
	end

	local mn = tonumber(cfg.Min) or 0
	local mx = tonumber(cfg.Max) or 100
	if mn > mx then mn, mx = mx, mn end
	local value = math.clamp(tonumber(cfg.Default) or mn, mn, mx)
	local range = math.max(mx - mn, 1)

	local element = section:_BaseElement("ApexSlider", cfg.Description and 54 or 52)
	section:_Title(element, cfg.Title or "Slider", cfg.Description)
	local valueLabel = Create("TextLabel", {
		Name = "Value",
		Size = UDim2.new(0, 40, 0, 18),
		Position = UDim2.new(1, -52, 0, 7),
		BackgroundTransparency = 1,
		Text = tostring(value),
		Font = FONT_SEMI,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(236, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 11,
		Parent = element,
	})
	local bar = Create("Frame", {
		Name = "Bar",
		Size = UDim2.new(1, -24, 0, 5),
		Position = UDim2.new(0, 12, 1, -13),
		BackgroundColor3 = THEME.BG_ACTIVE,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = element,
	})
	Corner(3, bar)
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.new((value - mn) / range, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(136, 131, 163),
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = bar,
	})
	Corner(3, fill)
	Create("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new(Color3.fromRGB(92, 84, 130), Color3.fromRGB(198, 189, 255)),
		Parent = fill,
	})

	local sliding = false
	local control = {
		Type = "Slider",
		Flag = cfg.Flag,
		Instance = element,
		Value = value,
		Min = mn,
		Max = mx,
		Connections = {},
		_changedListeners = {},
	}
	local function track(conn)
		table.insert(control.Connections, conn)
		local window = section.Page and section.Page.Window
		if window and window.Connections then
			table.insert(window.Connections, conn)
		end
		return conn
	end

	function control:Set(newValue, silent)
		value = math.clamp(tonumber(newValue) or mn, mn, mx)
		self.Value = value
		local alpha = (value - mn) / range
		valueLabel.Text = tostring(value)
		TweenService:Create(fill, TW_FAST, { Size = UDim2.new(alpha, 0, 1, 0) }):Play()
		if not silent then
			SafeCallback(cfg.Callback, value)
			for _, fn in ipairs(self._changedListeners) do SafeCallback(fn, value) end
		end
	end
	control.SetValue = control.Set
	function control:Get() return value end
	function control:OnChanged(fn)
		if type(fn) == "function" then table.insert(self._changedListeners, fn) end
	end

	local function updateFromX(x)
		local width = math.max(bar.AbsoluteSize.X, 1)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
		local newValue = math.floor((mn + range * alpha) + 0.5)
		control:Set(newValue)
	end

	track(element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateFromX(input.Position.X)
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end))
	function control:Disconnect()
		for _, conn in ipairs(self.Connections) do
			pcall(function() conn:Disconnect() end)
		end
	end

	if cfg.Flag then OptionsRegistry.Register(cfg.Flag, control) end

	section:_UpdateSize()
	return control
end

return Slider
