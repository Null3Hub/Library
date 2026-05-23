--[[
    Apex UI Library - Section Element: Keybind
    Keyboard input binder; click to listen, then press a key.

    Positional or config-table API. When `Flag` is provided the control is
    registered in Library.Options for save/load.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")

local Theme   = require(script.Parent.Parent.Theme)
local Util    = require(script.Parent.Parent.Util)
local OptionsRegistry = require(script.Parent.Parent.OptionsRegistry)

local Create       = Util.Create
local Corner       = Util.Corner
local Stroke       = Util.Stroke
local SafeCallback = Util.SafeCallback
local GetKeyCode   = Util.GetKeyCode
local THEME        = Theme.THEME
local FONT_SEMI    = Theme.FONT_SEMI

local Keybind = {}

function Keybind.Build(section, textOrCfg, default, callback, desc)
	local cfg
	if type(textOrCfg) == "table" then
		cfg = textOrCfg
	else
		cfg = {
			Title = textOrCfg, Default = default,
			Callback = callback, Description = desc,
		}
	end

	local element = section:_BaseElement("ApexKeybind", cfg.Description and 44 or 38)
	section:_Title(element, cfg.Title or "Keybind", cfg.Description)
	local current = GetKeyCode(cfg.Default, Enum.KeyCode.LeftAlt)
	local listening = false
	local button = Create("TextButton", {
		Name = "BindButton",
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -100, 0.5, -12),
		BackgroundColor3 = THEME.BG_SEARCH,
		BorderSizePixel = 0,
		Text = current.Name,
		Font = FONT_SEMI,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(178, 170, 210),
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 12,
		Parent = element,
	})
	Create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = button,
	})
	-- Smooth reposition when button auto-sizes
	local function updateButtonPosition()
		local w = button.AbsoluteSize.X
		TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -(w + 12), 0.5, -12),
		}):Play()
	end
	local sizeConn = button:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateButtonPosition)
	task.defer(updateButtonPosition)

	Corner(7, button)
	Stroke(button, THEME.BORDER, 1)

	local control = {
		Type = "Keybind",
		Flag = cfg.Flag,
		Instance = element,
		Value = current,
		Connections = { sizeConn },
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
	local window = section.Page and section.Page.Window
	if window and window.Connections then
		table.insert(window.Connections, sizeConn)
	end

	function control:Set(keyCode, silent)
		current = GetKeyCode(keyCode, current)
		button.Text = current.Name
		self.Value = current
		if not silent then
			SafeCallback(cfg.Callback, current)
			for _, fn in ipairs(self._changedListeners) do SafeCallback(fn, current) end
		end
	end
	control.SetValue = control.Set
	function control:Get() return current end
	function control:Listening() return listening end
	function control:OnChanged(fn)
		if type(fn) == "function" then table.insert(self._changedListeners, fn) end
	end

	track(button.MouseButton1Click:Connect(function()
		listening = true
		button.Text = "..."
	end))

	track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			control:Set(input.KeyCode)
			listening = false
		end
	end))

	function control:Disconnect()
		for _, connection in ipairs(self.Connections) do
			pcall(function() connection:Disconnect() end)
		end
	end

	if cfg.Flag then OptionsRegistry.Register(cfg.Flag, control) end

	section:_UpdateSize()
	return control
end

return Keybind
