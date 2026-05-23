--[[
    Apex UI Library - Section Element: Button
    Compact button with an arrow icon. Visual matches the original Section:Button.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)

local THEME = Theme.THEME
local Create       = Util.Create
local SafeCallback = Util.SafeCallback
local FONT_BOLD    = Theme.FONT_BOLD
local TW_FAST      = Theme.TW_FAST

local Button = {}

function Button.Build(section, text, callback, desc)
	local element, buttonStroke = section:_BaseElement("ApexButton", desc and 44 or 38)
	section:_Title(element, text or "Button", desc)

	local interact = Create("TextButton", {
		Name = "Interact",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
		Parent = element,
	})
	local icon = Create("ImageLabel", {
		Name = "ButtonIcon",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(1, -30, 0.5, -9),
		BackgroundTransparency = 1,
		Image = "rbxassetid://94586681223401",
		ImageColor3 = Color3.fromRGB(178, 170, 210),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 12,
		Parent = element,
	})
	interact.MouseButton1Click:Connect(function()
		TweenService:Create(buttonStroke, TW_FAST, { Color = Color3.fromRGB(136, 131, 163) }):Play()
		TweenService:Create(icon, TW_FAST, { ImageColor3 = Color3.fromRGB(236, 232, 255) }):Play()
		task.delay(0.18, function()
			if buttonStroke.Parent then
				TweenService:Create(buttonStroke, TW_FAST, { Color = THEME.BORDER }):Play()
				TweenService:Create(icon, TW_FAST, { ImageColor3 = Color3.fromRGB(178, 170, 210) }):Play()
			end
		end)
		SafeCallback(callback)
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
