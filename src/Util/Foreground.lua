--[[
    Apex UI Library - Foreground / hover utilities
    Functions used to detect when an input layer (UserSettings popup, etc.)
    is blocking the page below and to apply consistent hover transitions.
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Parent.Theme)

local Foreground = {}

function Foreground.IsInsideForegroundLayer(guiObject)
	local current = guiObject
	while current do
		if current.GetAttribute and current:GetAttribute("ApexForegroundLayer") == true then
			return true
		end
		current = current.Parent
	end
	return false
end

function Foreground.IsForegroundInputBlocked(guiObject)
	if Foreground.IsInsideForegroundLayer(guiObject) then
		return false
	end

	local current = guiObject
	while current do
		if current.GetAttribute and current:GetAttribute("ApexForegroundInputBlocked") == true then
			return true
		end
		current = current.Parent
	end
	return false
end

function Foreground.HoverColor(frame, normalColor, hoverColor, tweenInfo)
	if not frame or not frame:IsA("GuiObject") then
		return
	end

	tweenInfo = tweenInfo or Theme.TW_FAST
	normalColor = normalColor or frame.BackgroundColor3
	hoverColor = hoverColor or Theme.THEME.BG_HOVER

	frame.MouseEnter:Connect(function()
		if frame.Parent and not Foreground.IsForegroundInputBlocked(frame) then
			TweenService:Create(frame, tweenInfo, {
				BackgroundColor3 = hoverColor
			}):Play()
		end
	end)

	frame.MouseLeave:Connect(function()
		if frame.Parent then
			TweenService:Create(frame, tweenInfo, {
				BackgroundColor3 = normalColor
			}):Play()
		end
	end)
end

return Foreground
