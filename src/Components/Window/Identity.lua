--[[
    Apex UI Library - Window methods: Identity (hidden mode), notifications
]]

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer

local Theme    = require(script.Parent.Parent.Parent.Theme)
local Util     = require(script.Parent.Parent.Parent.Util)
local Constants = require(script.Parent.Parent.Parent.Constants)

local ResolveIcon = Util.ResolveIcon
local GetLocalPlayerHeadshot = Util.GetLocalPlayerHeadshot
local TW_FAST = Theme.TW_FAST

local HIDDEN_DEFAULT_NAME = Constants.HIDDEN_DEFAULT_NAME
local HIDDEN_AVATAR       = Constants.HIDDEN_AVATAR

local Identity = {}

function Identity:SetNotificationsEnabled(state)
	local enabled = state and true or false
	self.NotificationsEnabled = enabled
	if self.NotificationIcon then
		TweenService:Create(self.NotificationIcon, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
			Rotation = enabled and -8 or 8,
		}):Play()
		task.delay(0.09, function()
			if not self.NotificationIcon or not self.NotificationIcon.Parent then return end
			self.NotificationIcon.Image = ResolveIcon(enabled and "solar:bell-outline" or "solar:bell-off-line-duotone")
			self.NotificationIcon.Rotation = enabled and 8 or -8
			TweenService:Create(self.NotificationIcon, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0,
				Rotation = 0,
			}):Play()
		end)
	end
	return enabled
end

function Identity:ToggleNotifications()
	return self:SetNotificationsEnabled(not self.NotificationsEnabled)
end

function Identity:_GetIdentity()
	local hiddenEnabled = self.HiddenMode == true
	local hiddenName = tostring(self.HiddenName or HIDDEN_DEFAULT_NAME)
	local visualName = hiddenEnabled and hiddenName or tostring(self.RealDisplayName or LocalPlayer.DisplayName or LocalPlayer.Name)
	local userName = hiddenEnabled and hiddenName or tostring(self.RealUserName or LocalPlayer.Name)
	local avatar = hiddenEnabled and (self.HiddenAvatar or HIDDEN_AVATAR) or (self.RealAvatar or GetLocalPlayerHeadshot())
	return visualName, userName, avatar, hiddenEnabled
end

function Identity:_ApplyIdentity(animate)
	local visualName, userName, avatar, hiddenEnabled = self:_GetIdentity()
	local usernameText = "@" .. tostring(userName)

	if self.TopbarVisualNick then
		self.TopbarVisualNick.Text = visualName
		self.TopbarVisualNick.TextSize = hiddenEnabled and 14 or 13
		self.TopbarVisualNick.TextYAlignment = hiddenEnabled and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top
		self.TopbarVisualNick.Size = hiddenEnabled and UDim2.new(0, 0, 0, 24) or UDim2.new(0, 0, 0, 18)
	end
	if self.TopbarRealNick then
		self.TopbarRealNick.Text = usernameText
		self.TopbarRealNick.Visible = not hiddenEnabled
	end
	if self.TopbarAvatarImage then
		if animate then
			TweenService:Create(self.TopbarAvatarImage, TW_FAST, { ImageTransparency = 1 }):Play()
			task.delay(0.12, function()
				if self.TopbarAvatarImage and self.TopbarAvatarImage.Parent then
					self.TopbarAvatarImage.Image = avatar
					TweenService:Create(self.TopbarAvatarImage, TW_FAST, { ImageTransparency = 0 }):Play()
				end
			end)
		else
			self.TopbarAvatarImage.Image = avatar
			self.TopbarAvatarImage.ImageTransparency = 0
		end
	end
	if self.UserSettingsAvatarImage then
		self.UserSettingsAvatarImage.Image = avatar
	end
	if self.UserSettingsUsernameLabel then
		self.UserSettingsUsernameLabel.Text = hiddenEnabled and "Hidden Mode" or usernameText
	end

	self.UserSettingsWelcomeText = "Welcome to User Settings, " .. tostring(visualName)
	if self.UserSettingsWelcomeLabel and not self.UserSettingsOpened then
		self.UserSettingsWelcomeLabel.Text = self.UserSettingsWelcomeText
	end
end

function Identity:SetHiddenMode(enabled, nick)
	self.HiddenMode = enabled == true
	if nick ~= nil then
		self.HiddenName = tostring(nick)
	end
	self:_ApplyIdentity(true)
	return self
end

function Identity:ToggleHiddenMode(nick)
	return self:SetHiddenMode(not self.HiddenMode, nick)
end

function Identity:SetHiddenName(nick)
	self.HiddenName = tostring(nick or HIDDEN_DEFAULT_NAME)
	if self.HiddenMode then
		self:_ApplyIdentity(true)
	end
	return self
end

return Identity
