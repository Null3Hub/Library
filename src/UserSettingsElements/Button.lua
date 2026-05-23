--[[
    Apex UI Library - UserSettings Element: Button (compact)
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)

local Create       = Util.Create
local SafeCallback = Util.SafeCallback
local THEME        = Theme.THEME
local FONT_BOLD    = Theme.FONT_BOLD
local TW_FAST      = Theme.TW_FAST

local Button = {}

function Button.Build(section, text, callback, desc)
	local args = type(text) == "table" and text or nil
	local title = args and (args.Title or args.Name or args.Text or "Button") or (text or "Button")
	local cb = args and (args.Callback or callback) or callback
	local descText = args and (args.Description or args.Desc) or desc

	local element, buttonStroke = section:_BaseElement("SettingsButton", descText and 40 or 34)
	section:_Title(element, title, descText)

	local interact = Create("TextButton", {
		Name = "Interact",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 144,
		Parent = element,
	})
	local icon = Create("TextLabel", {
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -36, 0.5, -12),
		BackgroundTransparency = 1,
		Text = "",
		Font = FONT_BOLD,
		TextSize = 17,
		TextColor3 = Color3.fromRGB(178, 170, 210),
		ZIndex = 143,
		Parent = element,
	})
	interact.MouseButton1Click:Connect(function()
		TweenService:Create(buttonStroke, TW_FAST, { Color = Color3.fromRGB(136, 131, 163) }):Play()
		TweenService:Create(icon, TW_FAST, { TextColor3 = Color3.fromRGB(236, 232, 255) }):Play()
		task.delay(0.18, function()
			if buttonStroke.Parent then
				TweenService:Create(buttonStroke, TW_FAST, { Color = THEME.BORDER }):Play()
				TweenService:Create(icon, TW_FAST, { TextColor3 = Color3.fromRGB(178, 170, 210) }):Play()
			end
		end)
		SafeCallback(cb)
	end)
	section:_UpdateSize()
	return {
		Instance = element,
		SetText = function(_, value)
			local t = element:FindFirstChild("Title")
			if t then t.Text = tostring(value) end
		end,
	}
end

return Button
