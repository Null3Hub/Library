--[[
    Apex UI Library - Section Element: Toggle
    Tracked switch with knob slide animation.

    Accepts either positional args:
        section:Toggle("Title", false, callback, "desc")
    or a single config table:
        section:Toggle({
            Title = "...", Description = "...",
            Default = false, Callback = function(v) end,
            Flag = "myToggle",   -- optional, registers in Library.Options
        })
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
			Title = textOrCfg,
			Default = default,
			Callback = callback,
			Description = desc,
		}
	end

	local element = section:_BaseElement("ApexToggle", cfg.Description and 44 or 38)
	section:_Title(element, cfg.Title or "Toggle", cfg.Description)
	local value = cfg.Default and true or false
	local trackOn = Color3.fromRGB(82, 74, 118)
	local trackOff = Color3.fromRGB(42, 39, 50)
	local knobOn = Color3.fromRGB(236, 232, 255)
	local knobOff = Color3.fromRGB(145, 139, 170)
	local knobStrokeOn = trackOn:Lerp(Color3.new(1, 1, 1), 0.45)
	local knobStrokeOff = Color3.fromRGB(236, 232, 255)
	local function trackStrokeTransparency(enabled)
		return enabled and 1 or 0
	end

	local track = Create("Frame", {
		Name = "ToggleTrack",
		Size = UDim2.new(0, 42, 0, 22),
		Position = UDim2.new(1, -54, 0.5, -11),
		BackgroundColor3 = value and trackOn or trackOff,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = element,
	})
	Corner(11, track)
	local trackStroke = Stroke(track, THEME.BORDER, 1)
	trackStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	trackStroke.Transparency = trackStrokeTransparency(value)
	local knob = Create("Frame", {
		Name = "ToggleKnob",
		Size = UDim2.new(0, 16, 0, 16),
		Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3 = value and knobOn or knobOff,
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = track,
	})
	Corner(8, knob)
	local knobStroke = Stroke(knob, value and knobStrokeOn or knobStrokeOff, 1)
	knobStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	local button = Create("TextButton", {
		Name = "Interact",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
		Parent = element,
	})

	local control = {
		Type = "Toggle",
		Flag = cfg.Flag,
		Instance = element,
		Value = value,
		_changedListeners = {},
	}

	function control:Set(newValue, silent)
		value = newValue and true or false
		self.Value = value
		TweenService:Create(track, TW_MED, {
			BackgroundColor3 = value and trackOn or trackOff,
		}):Play()
		TweenService:Create(trackStroke, TW_MED, {
			Transparency = trackStrokeTransparency(value),
		}):Play()
		TweenService:Create(knob, TW_MED, {
			Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
			BackgroundColor3 = value and knobOn or knobOff,
		}):Play()
		TweenService:Create(knobStroke, TW_MED, {
			Color = value and knobStrokeOn or knobStrokeOff,
		}):Play()
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

	button.MouseButton1Click:Connect(function() control:Set(not value) end)

	if cfg.Flag then OptionsRegistry.Register(cfg.Flag, control) end

	section:_UpdateSize()
	return control
end

return Toggle
