--[[
    Apex UI Library - UserSettings Element: Toggle (compact)
]]

local TweenService = game:GetService("TweenService")

local Theme   = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local OptionsRegistry = require(script.Parent.Parent.OptionsRegistry)

local Create       = Util.Create
local Corner       = Util.Corner
local Stroke       = Util.Stroke
local SafeCallback = Util.SafeCallback
local THEME        = Theme.THEME
local TW_MED       = Theme.TW_MED

local Toggle = {}

function Toggle.Build(section, textOrCfg, default, callback, desc)
	local cfg
	if type(textOrCfg) == "table" then
		cfg = textOrCfg
	else
		cfg = {
			Title = textOrCfg, Default = default,
			Callback = callback, Description = desc,
		}
	end

	local title = cfg.Title or "Toggle"
	local enabled = cfg.Default and true or false
	local element = section:_BaseElement("SettingsToggle", cfg.Description and 40 or 34)
	section:_Title(element, title, cfg.Description)

	local track = Create("Frame", {
		Name = "ToggleTrack",
		Size = UDim2.new(0, 38, 0, 20),
		Position = UDim2.new(1, -50, 0.5, -10),
		BackgroundColor3 = enabled and Color3.fromRGB(82, 74, 118) or Color3.fromRGB(42, 39, 50),
		BorderSizePixel = 0,
		ZIndex = 143,
		Parent = element,
	})
	Corner(10, track)
	Stroke(track, THEME.BORDER, 1)
	local knob = Create("Frame", {
		Name = "ToggleKnob",
		Size = UDim2.new(0, 14, 0, 14),
		Position = enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = enabled and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(145, 139, 170),
		BorderSizePixel = 0,
		ZIndex = 144,
		Parent = track,
	})
	Corner(7, knob)
	local button = Create("TextButton", {
		Name = "Interact",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 145,
		Parent = element,
	})

	local control = {
		Type = "Toggle",
		Flag = cfg.Flag,
		Instance = element,
		Value = enabled,
		_changedListeners = {},
	}

	function control:Set(newValue, silent)
		enabled = newValue and true or false
		self.Value = enabled
		TweenService:Create(track, TW_MED, {
			BackgroundColor3 = enabled and Color3.fromRGB(82, 74, 118) or Color3.fromRGB(42, 39, 50),
		}):Play()
		TweenService:Create(knob, TW_MED, {
			Position = enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
			BackgroundColor3 = enabled and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(145, 139, 170),
		}):Play()
		if not silent then
			SafeCallback(cfg.Callback, enabled)
			for _, fn in ipairs(self._changedListeners) do SafeCallback(fn, enabled) end
		end
	end
	control.SetValue = control.Set
	function control:Get() return enabled end
	function control:OnChanged(fn)
		if type(fn) == "function" then table.insert(self._changedListeners, fn) end
	end

	button.MouseButton1Click:Connect(function() control:Set(not enabled) end)

	if cfg.Flag then OptionsRegistry.Register(cfg.Flag, control) end

	section:_UpdateSize()
	return control
end

return Toggle
