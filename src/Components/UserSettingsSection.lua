--[[
    Apex UI Library - UserSettingsSection class
    Compact section used inside the UserSettings popup. It mirrors Section's
    surface API but renders denser visuals at higher Z indexes so it stays on
    top of the page content.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)
local UserSettingsElements = require(script.Parent.Parent.UserSettingsElements)

local Create       = Util.Create
local Corner       = Util.Corner
local Stroke       = Util.Stroke
local ResolveIcon  = Util.ResolveIcon
local IsForegroundInputBlocked = Util.IsForegroundInputBlocked

local THEME       = Theme.THEME
local FONT_REG    = Theme.FONT_REG
local FONT_SEMI   = Theme.FONT_SEMI
local TW_FAST     = Theme.TW_FAST

local UserSettingsSection = {}
UserSettingsSection.__index = UserSettingsSection

function UserSettingsSection:_UpdateSize()
	local h = self.ElementsLayout.AbsoluteContentSize.Y
	self.ElementsList.Size = UDim2.new(1, 0, 0, h)
	self.ElementsClip.Size = UDim2.new(1, -32, 0, h)
	self.Container.Size = UDim2.new(1, 0, 0, 46 + h + 14)

	local window = self.Window
	if window and window.UserSettingsBody and window.UserSettingsBodyLayout then
		local bodyHeight = window.UserSettingsBodyLayout.AbsoluteContentSize.Y
		window.UserSettingsBody.CanvasSize = UDim2.new(0, 0, 0, bodyHeight + 28)
	end
end

function UserSettingsSection:_BaseElement(name, height)
	local element = Create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, height or 34),
		BackgroundColor3 = THEME.BG_BUTTON,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 142,
		Parent = self.ElementsList,
	})
	Corner(8, element)
	local elStroke = Stroke(element, THEME.BORDER, 1)
	elStroke.Transparency = 0.25
	element.MouseEnter:Connect(function()
		if IsForegroundInputBlocked(element) then return end
		TweenService:Create(elStroke, TW_FAST, { Color = Color3.fromRGB(87, 84, 104) }):Play()
		TweenService:Create(element, TW_FAST, { BackgroundTransparency = 0.04 }):Play()
	end)
	element.MouseLeave:Connect(function()
		TweenService:Create(elStroke, TW_FAST, { Color = THEME.BORDER }):Play()
		TweenService:Create(element, TW_FAST, { BackgroundTransparency = 0.12 }):Play()
	end)
	return element, elStroke
end

function UserSettingsSection:_Title(parent, title, desc)
	Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -108, 0, desc and 14 or 18),
		Position = UDim2.new(0, 11, 0, desc and 5 or 8),
		BackgroundTransparency = 1,
		Text = tostring(title or "Element"),
		Font = FONT_SEMI,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(235, 231, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = parent.ZIndex + 1,
		Parent = parent,
	})
	if desc then
		Create("TextLabel", {
			Name = "Desc",
			Size = UDim2.new(1, -108, 0, 12),
			Position = UDim2.new(0, 11, 0, 20),
			BackgroundTransparency = 1,
			Text = tostring(desc),
			Font = FONT_REG,
			TextSize = 9,
			TextColor3 = Color3.fromRGB(145, 139, 170),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = parent.ZIndex + 1,
			Parent = parent,
		})
	end
end

-- Configuration helpers (post-creation tweaks)
function UserSettingsSection:SetTitle(value)
	if self.TitleLabel then
		self.TitleLabel.Text = tostring(value or "Section")
	end
	return self
end

function UserSettingsSection:SetDescription(value)
	if self.SubtitleLabel then
		self.SubtitleLabel.Text = tostring(value or "")
	end
	return self
end

function UserSettingsSection:SetIcon(icon, iconType)
	if not self.Header then return self end

	local hasIcon = icon ~= nil and tostring(icon) ~= ""
	if not hasIcon then
		if self.SectionIcon then
			self.SectionIcon:Destroy()
			self.SectionIcon = nil
		end
		if self.TitleLabel then
			self.TitleLabel.Position = UDim2.new(0, 0, 0, 10)
			self.TitleLabel.Size = UDim2.new(1, -88, 0, 17)
		end
		if self.SubtitleLabel then
			self.SubtitleLabel.Position = UDim2.new(0, 0, 0, 28)
			self.SubtitleLabel.Size = UDim2.new(1, -88, 0, 13)
		end
		return self
	end

	if not self.SectionIcon then
		self.SectionIcon = Create("ImageLabel", {
			Name = "SectionIcon",
			Size = UDim2.new(0, 19, 0, 19),
			Position = UDim2.new(0, 0, 0, 12),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(236, 232, 255),
			ImageTransparency = 0.03,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 142,
			Parent = self.Header,
		})
	end

	self.SectionIcon.Image = ResolveIcon(icon, iconType or (self.Window and self.Window.IconsType) or "lucide")
	if self.TitleLabel then
		self.TitleLabel.Position = UDim2.new(0, 27, 0, 10)
		self.TitleLabel.Size = UDim2.new(1, -115, 0, 17)
	end
	if self.SubtitleLabel then
		self.SubtitleLabel.Position = UDim2.new(0, 27, 0, 28)
		self.SubtitleLabel.Size = UDim2.new(1, -115, 0, 13)
	end
	return self
end

function UserSettingsSection:Configure(args)
	args = type(args) == "table" and args or {}
	if args.Name or args.Title then
		self:SetTitle(args.Name or args.Title)
	end
	if args.Description or args.Subtitle or args.Sub or args.Desc then
		self:SetDescription(args.Description or args.Subtitle or args.Sub or args.Desc)
	end
	if args.Icon ~= nil or args.Icone ~= nil or args.Image ~= nil then
		self:SetIcon(args.Icon or args.Icone or args.Image, args.IconType or args.IconsType)
	end
	return self
end

-- Element builders, simply forwarded
function UserSettingsSection:Label(text, desc)
	return UserSettingsElements.Label.Build(self, text, desc)
end

function UserSettingsSection:Button(text, callback, desc)
	return UserSettingsElements.Button.Build(self, text, callback, desc)
end

function UserSettingsSection:Toggle(text, default, callback, desc)
	return UserSettingsElements.Toggle.Build(self, text, default, callback, desc)
end

function UserSettingsSection:Keybind(text, default, callback, desc)
	return UserSettingsElements.Keybind.Build(self, text, default, callback, desc)
end

function UserSettingsSection:Dropdown(configOrTitle, values, default, callback)
	return UserSettingsElements.Dropdown.Build(self, configOrTitle, values, default, callback)
end

function UserSettingsSection:Special(first)
	return UserSettingsElements.Special.Build(self, first)
end

return UserSettingsSection
