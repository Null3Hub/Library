--[[
    Apex UI Library - Window methods: User Settings popup management
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Parent.Util)
local UserSettingsSection = require(script.Parent.Parent.UserSettingsSection)

local Create     = Util.Create
local Corner     = Util.Corner
local Padding    = Util.Padding
local ListLayout = Util.ListLayout
local ResolveIcon = Util.ResolveIcon

local THEME       = Theme.THEME
local FONT_REG    = Theme.FONT_REG
local FONT_BOLD   = Theme.FONT_BOLD
local CORNER_MD   = Theme.CORNER_MD

local UserSettings = {}

function UserSettings:UserSettingsSection(args)
	args = type(args) == "table" and args or { Name = args }
	local name = tostring(args.Name or args.Title or "Section")
	local description = tostring(args.Description or args.Subtitle or args.Sub or "")
	if not self.UserSettingsBody then return nil end

	-- Container (mirrors Page:Section sectionFrame)
	local container = Create("Frame", {
		Name = "UserSettingsSection_" .. name,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.BG_SIDEBAR,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 140,
		LayoutOrder = #self.UserSettingsSections + 1,
		Parent = self.UserSettingsBody,
	})
	Corner(CORNER_MD, container)

	local sectionStroke = Create("UIStroke", {
		Color = Color3.fromRGB(142, 142, 150),
		Transparency = 0,
		Thickness = 1.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = container,
	})
	Create("UIGradient", {
		Name = "SectionStrokeFade",
		Rotation = 55,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(72, 72, 78)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(150, 150, 158)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(72, 72, 78)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.00),
			NumberSequenceKeypoint.new(0.18, 0.34),
			NumberSequenceKeypoint.new(0.50, 0.06),
			NumberSequenceKeypoint.new(0.82, 0.34),
			NumberSequenceKeypoint.new(1.00, 1.00),
		}),
		Parent = sectionStroke,
	})

	-- Header (mirrors Page:Section header)
	local header = Create("Frame", {
		Name = "SectionHeader",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 141,
		Parent = container,
	})
	Padding(header, 0, 14, 0, 14)

	local sectionIconSource = args.Icon or args.Icone or args.Image
	local sectionIcon
	local textOffset = 0
	if sectionIconSource then
		sectionIcon = Create("ImageLabel", {
			Name = "SectionIcon",
			Size = UDim2.new(0, 19, 0, 19),
			Position = UDim2.new(0, 0, 0, 12),
			BackgroundTransparency = 1,
			Image = ResolveIcon(sectionIconSource, args.IconType or args.IconsType or self.IconsType or "lucide"),
			ImageColor3 = Color3.fromRGB(236, 232, 255),
			ImageTransparency = 0.03,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 142,
			Parent = header,
		})
		textOffset = 27
	end

	local titleLabel = Create("TextLabel", {
		Name = "TabSection",
		Size = UDim2.new(1, -(88 + textOffset), 0, 17),
		Position = UDim2.new(0, textOffset, 0, 10),
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT_BOLD,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(236, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 142,
		Parent = header,
	})
	local subtitleLabel = Create("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.new(1, -(88 + textOffset), 0, 13),
		Position = UDim2.new(0, textOffset, 0, 28),
		BackgroundTransparency = 1,
		Text = description ~= "" and description or "Settings controls",
		Font = FONT_REG,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(145, 139, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 142,
		Parent = header,
	})

	-- ElementsClip (mirrors Page:Section elementsClip)
	local elementsClip = Create("Frame", {
		Name = "ElementsClip",
		Size = UDim2.new(1, -32, 0, 0),
		Position = UDim2.new(0, 16, 0, 48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 141,
		Parent = container,
	})
	local elementsList = Create("Frame", {
		Name = "ElementsList",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 141,
		Parent = elementsClip,
	})
	local elementsLayout = ListLayout(elementsList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 7)

	local section = setmetatable({
		Window = self,
		Container = container,
		Header = header,
		TitleLabel = titleLabel,
		SubtitleLabel = subtitleLabel,
		SectionIcon = sectionIcon,
		ElementsClip = elementsClip,
		ElementsList = elementsList,
		ElementsLayout = elementsLayout,
	}, UserSettingsSection)

	table.insert(self.UserSettingsSections, section)

	local sizeConn = elementsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		section:_UpdateSize()
	end)
	if self.Connections then
		table.insert(self.Connections, sizeConn)
	end
	task.defer(function() section:_UpdateSize() end)

	return section
end

function UserSettings:GetUserSettingsSection()
	if not self.DefaultUserSettingsSection then
		self.DefaultUserSettingsSection = self:UserSettingsSection({
			Name = "Account",
			Description = "Profile panel ready",
		})
	end
	return self.DefaultUserSettingsSection
end

function UserSettings:ClearUserSettings()
	for _, section in ipairs(self.UserSettingsSections or {}) do
		if section.Container then section.Container:Destroy() end
	end
	self.UserSettingsSections = {}
	self.DefaultUserSettingsSection = nil
	if self.UserSettingsBody then
		self.UserSettingsBody.CanvasSize = UDim2.new(0, 0, 0, 0)
	end
	return self
end

function UserSettings:SetUserSettingsVisible(opened, instant)
	if self.Destroyed then return end
	local settings = self.UserSettings
	local scale = self.UserSettingsScale
	local stroke = self.UserSettingsStroke
	local blocker = self.UserSettingsInputBlocker
	if not settings or not settings.Parent or not scale then return end

	opened = opened == true
	if self.UserSettingsOpened == opened and not instant then
		return
	end

	self.UserSettingsOpened = opened
	self._UserSettingsTweenToken = (self._UserSettingsTweenToken or 0) + 1
	local token = self._UserSettingsTweenToken
	local targetTransparency = self.UserSettingsBackgroundTransparency or 0.4
	local targetStrokeTransparency = self.UserSettingsStrokeTransparency or 0.18
	local basePosition = self.UserSettingsBasePosition or settings.Position

	if opened then
		-- Only mark the active page viewport as input-blocked for hover guards.
		-- Do not mark the whole window, otherwise the topbar/sidebar/drag region
		-- behaves like it is behind a modal layer.
		if self.CurrentPage and self.CurrentPage.Viewport and self.CurrentPage.Viewport.Parent then
			self.CurrentPage.Viewport:SetAttribute("ApexForegroundInputBlocked", true)
		end
		if blocker and blocker.Parent then
			blocker.Visible = true
			blocker.Active = true
		end
		settings.Visible = true
		settings.Position = basePosition + UDim2.new(0, 0, 0, -10)

		if instant then
			settings.BackgroundTransparency = targetTransparency
			if stroke then stroke.Transparency = targetStrokeTransparency end
			scale.Scale = 1
			settings.Position = basePosition
			if self.UserSettingsWelcomeLabel then
				self.UserSettingsWelcomeLabel.Text = self.UserSettingsWelcomeText or self.UserSettingsWelcomeLabel.Text
			end
			return
		end

		settings.BackgroundTransparency = 1
		if stroke then stroke.Transparency = 1 end
		scale.Scale = 0.86

		TweenService:Create(settings, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = targetTransparency,
			Position = basePosition,
		}):Play()

		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = targetStrokeTransparency,
			}):Play()
		end

		TweenService:Create(scale, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()

		local label = self.UserSettingsWelcomeLabel
		local fullText = self.UserSettingsWelcomeText or "Welcome to User Settings"
		if label then
			self._UserSettingsTypingToken = (self._UserSettingsTypingToken or 0) + 1
			local typingToken = self._UserSettingsTypingToken
			label.Text = ""
			task.spawn(function()
				task.wait(0.08)
				for i = 1, #fullText do
					if self._UserSettingsTypingToken ~= typingToken or not self.UserSettingsOpened or not label.Parent then
						return
					end
					label.Text = string.sub(fullText, 1, i)
					task.wait(0.018)
				end
			end)
		end
	else
		if instant then
			settings.BackgroundTransparency = 1
			if stroke then stroke.Transparency = 1 end
			scale.Scale = 0.9
			settings.Position = basePosition + UDim2.new(0, 0, 0, -8)
			settings.Visible = false
			if blocker and blocker.Parent then
				blocker.Visible = false
				blocker.Active = false
			end
			for _, page in ipairs(self.Pages or {}) do
				if page.Viewport and page.Viewport.Parent then
					page.Viewport:SetAttribute("ApexForegroundInputBlocked", false)
				end
			end
			return
		end

		local fadeTween = TweenService:Create(settings, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			Position = basePosition + UDim2.new(0, 0, 0, -8),
		})

		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1,
			}):Play()
		end

		TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Scale = 0.9,
		}):Play()

		fadeTween:Play()
		fadeTween.Completed:Once(function()
			if self._UserSettingsTweenToken == token and not self.UserSettingsOpened and settings and settings.Parent then
				settings.Visible = false
				settings.Position = basePosition
				if blocker and blocker.Parent then
					blocker.Visible = false
					blocker.Active = false
				end
				for _, page in ipairs(self.Pages or {}) do
					if page.Viewport and page.Viewport.Parent then
						page.Viewport:SetAttribute("ApexForegroundInputBlocked", false)
					end
				end
			end
		end)
	end
end

function UserSettings:ToggleUserSettings()
	self:SetUserSettingsVisible(not self.UserSettingsOpened)
end

return UserSettings
