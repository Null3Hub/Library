--[[
    Apex UI Library - Window builder
    Constructs the entire visual tree (window, top bars, sidebar, content, user settings),
    wires every interaction, and returns the Window instance ready to use.

    The visuals here are an exact mirror of the original ApexL-test.lua
    Library.new function so the experience is preserved 1:1.
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Theme     = require(script.Parent.Parent.Theme)
local Util      = require(script.Parent.Parent.Util)
local Constants = require(script.Parent.Parent.Constants)
local WindowClass = require(script.Parent.Window)

local Create              = Util.Create
local Corner              = Util.Corner
local Stroke              = Util.Stroke
local Padding             = Util.Padding
local ListLayout          = Util.ListLayout
local GradientStrokeFrame = Util.GradientStrokeFrame
local ResolveIcon         = Util.ResolveIcon
local GetKeyCode          = Util.GetKeyCode
local GetLocalPlayerHeadshot = Util.GetLocalPlayerHeadshot

local THEME      = Theme.THEME
local FONT_BOLD  = Theme.FONT_BOLD
local FONT_SEMI  = Theme.FONT_SEMI
local FONT_REG   = Theme.FONT_REG
local CORNER_MD  = Theme.CORNER_MD
local CORNER_XL  = Theme.CORNER_XL
local SIDEBAR_EXPANDED = Theme.SIDEBAR_EXPANDED
local NEW_TOPBAR_H     = Theme.NEW_TOPBAR_H
local TOPBAR_H         = Theme.TOPBAR_H
local LOGO_ASSET       = Theme.LOGO_ASSET
local WINDOW_POS       = Theme.WINDOW_POS
local WINDOW_SIZE      = Theme.WINDOW_SIZE
local TW_FAST          = Theme.TW_FAST

local HIDDEN_DEFAULT_NAME = Constants.HIDDEN_DEFAULT_NAME
local HIDDEN_AVATAR       = Constants.HIDDEN_AVATAR

local Build = {}

function Build.New(Library, config)
	config = config or {}
	local title = tostring(config.Title or config.Name or "Apex")
	local topBarRightText = tostring(config.TopBarText or "@2026 - Apex L .")
	local logo = tostring(config.Logo or LOGO_ASSET)
	local sidebarLogoConfig = config.SideBarLogo or config.SidebarLogo or config.LogoConfig or {}
	if type(sidebarLogoConfig) ~= "table" then sidebarLogoConfig = {} end
	local sidebarLogoSize = tonumber(sidebarLogoConfig.Size or sidebarLogoConfig.BoxSize) or 36
	local sidebarLogoClosedSize = tonumber(sidebarLogoConfig.ClosedSize or sidebarLogoConfig.CollapsedSize) or math.max(sidebarLogoSize, 38)
	local sidebarLogoPadding = tonumber(sidebarLogoConfig.Padding or sidebarLogoConfig.IconPadding) or 5
	local sidebarLogoCorner = tonumber(sidebarLogoConfig.Corner or sidebarLogoConfig.CornerRadius) or 9
	local sidebarLogoBgEnabled = sidebarLogoConfig.Background ~= false and sidebarLogoConfig.BackgroundEnabled ~= false and sidebarLogoConfig.ShowBackground ~= false
	local sidebarLogoBgColor = sidebarLogoConfig.BackgroundColor or sidebarLogoConfig.Color or THEME.ACCENT_BLUE
	local keybind = GetKeyCode(config.Keybind or Enum.KeyCode.LeftAlt, Enum.KeyCode.LeftAlt)
	local iconsType = tostring(config.IconsType or config.IconType or Library.IconsType or "lucide")
	local hiddenName = tostring(config.HiddenName or HIDDEN_DEFAULT_NAME)
	local hiddenAvatar = tostring(config.HiddenAvatar or HIDDEN_AVATAR)
	local hiddenMode = (config.HiddenMode == true)
	Util.Icons.DefaultIconsType = iconsType
	Library.IconsType = iconsType

	local screenGui = Create("ScreenGui", {
		Name = config.GuiName or "ApexUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = PlayerGui,
	})

	local root = Create("Frame", {
		Name = "Window",
		Size = config.Size or WINDOW_SIZE,
		Position = config.Position or WINDOW_POS,
		BackgroundColor3 = THEME.BG_WINDOW,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 5,
		Parent = screenGui,
	})
	Corner(CORNER_XL, root)
	Create("UIGradient", {
		Rotation = 270,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.25) }),
		Color = ColorSequence.new(Color3.fromRGB(40, 40, 43), Color3.fromRGB(24, 24, 25)),
		Parent = root,
	})

	local lineBelowNewTopBar = Create("Frame", {
		Name = "LineBelowNewTopBar",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, NEW_TOPBAR_H),
		BackgroundColor3 = THEME.BORDER,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = root,
	})
	local lineBelowPageTopBar = Create("Frame", {
		Name = "LineBelowPageTopBar",
		Size = UDim2.new(1, -SIDEBAR_EXPANDED, 0, 1),
		Position = UDim2.new(0, SIDEBAR_EXPANDED, 0, NEW_TOPBAR_H + TOPBAR_H),
		BackgroundColor3 = THEME.BORDER,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = root,
	})
	local sidebarDivider = Create("Frame", {
		Name = "SidebarDivider",
		Size = UDim2.new(0, 1, 1, -NEW_TOPBAR_H),
		Position = UDim2.new(0, SIDEBAR_EXPANDED, 0, NEW_TOPBAR_H),
		BackgroundColor3 = THEME.BORDER,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = root,
	})

	-- ============================================================
	-- TOP BAR (window title bar with mac dots and right info text)
	-- ============================================================
	local newTopBar = Create("Frame", {
		Name = "NewTopBar",
		Size = UDim2.new(1, 0, 0, NEW_TOPBAR_H),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = THEME.BG_TOPBAR,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 10,
		Parent = root,
	})
	Corner(CORNER_XL, newTopBar)

	local sidebarToggle = Create("TextButton", { Name = "SidebarToggle", Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(0, 69, 0.5, -11), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 12, Parent = newTopBar })
	local sidebarToggleIcon = Create("ImageLabel", {
		Name = "SidebarToggleIcon",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0.5, -9, 0.5, -9),
		BackgroundTransparency = 1,
		Image = ResolveIcon("solar:double-alt-arrow-left-line-duotone"),
		ImageColor3 = THEME.TEXT_MUTED,
		ImageTransparency = 0,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 13,
		Parent = sidebarToggle,
	})

	sidebarToggle.MouseEnter:Connect(function()
		TweenService:Create(sidebarToggleIcon, TW_FAST, { ImageColor3 = THEME.TEXT_PRIMARY }):Play()
	end)
	sidebarToggle.MouseLeave:Connect(function()
		TweenService:Create(sidebarToggleIcon, TW_FAST, { ImageColor3 = THEME.TEXT_MUTED }):Play()
	end)

	-- macOS-style traffic-light dots (close, minimize, idle).
	local dotHolder = Create("Frame", { Name = "DotHolder", Size = UDim2.new(0, 52, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, ZIndex = 12, Parent = newTopBar })
	ListLayout(dotHolder, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, 8)
	local function macDot(name, color, symbol)
		local dot = Create("TextButton", {
			Name = name,
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundColor3 = THEME.DOT_GRAY,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 13,
			Parent = dotHolder,
		})
		Corner(6, dot)
		local lbl = Create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Font = FONT_BOLD, TextSize = 8, TextColor3 = Color3.fromRGB(40, 0, 0), TextTransparency = 1, ZIndex = 14, Parent = dot })
		dot.MouseEnter:Connect(function()
			TweenService:Create(dot, TW_FAST, { BackgroundColor3 = color }):Play()
			lbl.Text = symbol
			TweenService:Create(lbl, TW_FAST, { TextTransparency = 0 }):Play()
		end)
		dot.MouseLeave:Connect(function()
			TweenService:Create(dot, TW_FAST, { BackgroundColor3 = THEME.DOT_GRAY }):Play()
			TweenService:Create(lbl, TW_FAST, { TextTransparency = 1 }):Play()
		end)
		return dot
	end
	local closeDot = macDot("CloseButton", THEME.DOT_RED, "×")
	local minimizeDot = macDot("MinimizeButton", THEME.DOT_YELLOW, "−")
	local idleDot = macDot("IdleButton", THEME.DOT_GREEN, "+")

	local topBarRightInfo = Create("TextLabel", {
		Name = "TopBarRightInfo",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = topBarRightText,
		Font = FONT_REG,
		TextSize = 11,
		TextColor3 = THEME.TEXT_MUTED,
		TextTransparency = 0.22,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		Parent = newTopBar,
	})

	-- ============================================================
	-- SIDEBAR
	-- ============================================================
	local sidebar = Create("Frame", { Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_EXPANDED, 1, -NEW_TOPBAR_H), Position = UDim2.new(0, 0, 0, NEW_TOPBAR_H), BackgroundColor3 = THEME.BG_SIDEBAR, BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 6, Parent = root })
	Corner(CORNER_XL, sidebar)
	local sidebarTop = Create("Frame", { Name = "SidebarTop", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 7, Parent = sidebar })
	local logoBox = Create("Frame", {
		Name = "LogoBox",
		Size = UDim2.new(0, sidebarLogoSize, 0, sidebarLogoSize),
		Position = UDim2.new(0, 14, 0.5, -sidebarLogoSize / 2),
		BackgroundColor3 = sidebarLogoBgColor,
		BackgroundTransparency = sidebarLogoBgEnabled and 0 or 1,
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = sidebarTop,
	})
	Corner(sidebarLogoCorner, logoBox)
	Create("ImageLabel", {
		Name = "Logo",
		Size = UDim2.new(1, -(sidebarLogoPadding * 2), 1, -(sidebarLogoPadding * 2)),
		Position = UDim2.new(0, sidebarLogoPadding, 0, sidebarLogoPadding),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 9,
		Parent = logoBox,
	})
	local appNameOffset = 14 + sidebarLogoSize + (sidebarLogoBgEnabled and 8 or 5)
	local appNameLabel = Create("TextLabel", { Name = "AppName", Size = UDim2.new(1, -(appNameOffset + 8), 1, 0), Position = UDim2.new(0, appNameOffset, 0, 0), BackgroundTransparency = 1, Text = title, Font = FONT_BOLD, TextSize = 16, TextColor3 = THEME.TEXT_ACCENT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8, Parent = sidebarTop })

	local sidebarSearch = Create("Frame", { Name = "SidebarSearch", Size = UDim2.new(1, -28, 0, 32), Position = UDim2.new(0, 14, 0, 62), BackgroundColor3 = THEME.BG_SEARCH, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 7, Parent = sidebar })
	Corner(8, sidebarSearch)
	local sidebarSearchStroke = Stroke(sidebarSearch, THEME.BORDER, 1)
	Create("UIGradient", {
		Name = "SearchStrokeGradient",
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
		Parent = sidebarSearchStroke,
	})
	local searchIcon = Create("ImageLabel", {
		Name = "SearchIcon",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0, 10, 0.5, -8),
		BackgroundTransparency = 1,
		Image = ResolveIcon("solar:rounded-magnifer-linear"),
		ImageColor3 = THEME.TEXT_MUTED,
		ImageTransparency = 0,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 8,
		Parent = sidebarSearch,
	})
	local searchText = Create("TextBox", { Name = "SearchText", Size = UDim2.new(1, -46, 1, 0), Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search anything...", PlaceholderColor3 = THEME.TEXT_MUTED, ClearTextOnFocus = false, Font = FONT_REG, TextSize = 12, TextColor3 = THEME.TEXT_SECONDARY, TextTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = sidebarSearch })

	-- ============================================================
	-- CONTENT AREA + INNER PAGE TOPBAR
	-- ============================================================
	local contentArea = Create("Frame", { Name = "ContentArea", Size = UDim2.new(1, -SIDEBAR_EXPANDED, 1, -NEW_TOPBAR_H), Position = UDim2.new(0, SIDEBAR_EXPANDED, 0, NEW_TOPBAR_H), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6, Parent = root })
	local topBar = Create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, TOPBAR_H), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = THEME.BG_SIDEBAR, BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 7, Parent = contentArea })
	Corner(CORNER_MD, topBar)

	local topLeft = Create("Frame", { Name = "TopLeft", Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 8, Parent = topBar })
	Padding(topLeft, 6, 0, 0, 10)
	local pageTitle = Create("TextLabel", { Name = "PageTitle", Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "Dashboard", Font = FONT_BOLD, TextSize = 18, TextColor3 = THEME.TEXT_ACCENT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9, Parent = topLeft })
	local breadcrumbFrame = Create("Frame", { Name = "BreadcrumbFrame", Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 9, Parent = topLeft })
	ListLayout(breadcrumbFrame, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, 4)
	Create("ImageLabel", { Size = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit, ImageColor3 = THEME.TEXT_MUTED, ZIndex = 10, LayoutOrder = 1, Parent = breadcrumbFrame })
	Create("TextLabel", { Size = UDim2.new(0, 8, 0, 14), BackgroundTransparency = 1, Text = "/", Font = FONT_REG, TextSize = 10, TextColor3 = THEME.TEXT_MUTED, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 10, LayoutOrder = 2, Parent = breadcrumbFrame })
	local breadcrumbTabLabel = Create("TextLabel", { Size = UDim2.new(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "Dashboard", Font = FONT_SEMI, TextSize = 10, TextColor3 = THEME.TEXT_MUTED, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 10, LayoutOrder = 3, Parent = breadcrumbFrame })
	Create("TextLabel", { Size = UDim2.new(0, 8, 0, 14), BackgroundTransparency = 1, Text = "/", Font = FONT_REG, TextSize = 10, TextColor3 = THEME.TEXT_MUTED, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 10, LayoutOrder = 4, Parent = breadcrumbFrame })
	local breadcrumbSectionLabel = Create("TextLabel", { Size = UDim2.new(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "Section", Font = FONT_REG, TextSize = 10, TextColor3 = THEME.TEXT_MUTED, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 10, LayoutOrder = 5, Parent = breadcrumbFrame })

	local topRight = Create("Frame", { Name = "TopRight", Size = UDim2.new(0.55, -12, 1, 0), Position = UDim2.new(0.45, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 8, Parent = topBar })
	Padding(topRight, 0, 5, 0, 0)
	ListLayout(topRight, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, 0)

	local displayNick = LocalPlayer.DisplayName or LocalPlayer.Name
	local notificationEnabled = true
	local notificationButton = Create("TextButton", {
		Name = "NotificationButton",
		Size = UDim2.new(0, 24, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 9,
		LayoutOrder = 1,
		Parent = topRight,
	})
	local notificationIcon = Create("ImageLabel", {
		Name = "BellIcon",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0.5, -9, 0.5, -9),
		BackgroundTransparency = 1,
		Image = ResolveIcon("solar:bell-outline"),
		ImageColor3 = THEME.TEXT_SECONDARY,
		ImageTransparency = 0,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 10,
		Parent = notificationButton,
	})

	Create("TextLabel", { Name = "NotificationSeparator", Size = UDim2.new(0, 14, 0, 30), BackgroundTransparency = 1, Text = "/", Font = FONT_REG, TextSize = 12, TextColor3 = THEME.TEXT_MUTED, TextTransparency = 0.22, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 10, LayoutOrder = 2, Parent = topRight })
	local userChip = Create("Frame", { Name = "UserChip", Size = UDim2.new(0, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 9, LayoutOrder = 3, Parent = topRight })
	ListLayout(userChip, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, 8)
	local userTextStack = Create("Frame", { Name = "UserTextStack", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 10, LayoutOrder = 1, Parent = userChip })
	ListLayout(userTextStack, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, -2)
	local topbarRealNick = Create("TextLabel", { Name = "RealNick", Size = UDim2.new(0, 0, 0, 13), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name, Font = FONT_REG, TextSize = 8, TextColor3 = THEME.TEXT_MUTED, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 11, LayoutOrder = 1, Parent = userTextStack })
	local topbarVisualNick = Create("TextLabel", { Name = "VisualNick", Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = displayNick, Font = FONT_SEMI, TextSize = 13, TextColor3 = THEME.TEXT_PRIMARY, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 11, LayoutOrder = 2, Parent = userTextStack })

	local avatarCircle = Create("Frame", { Name = "Avatar", Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = THEME.ACCENT_BLUE, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 10, LayoutOrder = 2, Parent = userChip })
	Corner(16, avatarCircle)
	local avatarHeadshot = Create("ImageLabel", {
		Name = "Headshot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = GetLocalPlayerHeadshot(),
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 11,
		Parent = avatarCircle,
	})
	Corner(16, avatarHeadshot)

	-- ============================================================
	-- USER SETTINGS popup
	-- ============================================================
	local userSettingsBasePosition = UDim2.new(1, -14, 0, NEW_TOPBAR_H + TOPBAR_H + 8)

	local userSettings = Create("Frame", {
		Name = "UserSettings",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0.42, 0, 0.55, 0),
		Position = userSettingsBasePosition,
		BackgroundColor3 = THEME.BG_CARD,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 140,
		Parent = root,
	})
	userSettings:SetAttribute("ApexForegroundLayer", true)
	Corner(8, userSettings)

	local userSettingsScale = Create("UIScale", {
		Scale = 0.86,
		Parent = userSettings,
	})

	local userSettingsStroke = Create("UIStroke", {
		Color = THEME.BORDER,
		Transparency = 0.18,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = userSettings,
	})

	-- Invisible input blocker behind the popup, but limited to the page content area.
	local userSettingsInputBlocker = Create("TextButton", {
		Name = "UserSettingsInputBlocker",
		Size = UDim2.new(1, 0, 1, -TOPBAR_H),
		Position = UDim2.new(0, 0, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = false,
		Visible = false,
		Selectable = false,
		ZIndex = 130,
		Parent = contentArea,
	})
	userSettingsInputBlocker:SetAttribute("ApexForegroundLayer", true)

	Create("UIGradient", {
		Rotation = 270,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 42, 46)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 25)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Parent = userSettings,
	})

	Create("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = userSettings,
	})

	local userSettingsAvatarHolder = Create("Frame", {
		Name = "AvatarHolder",
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 142,
		Parent = userSettings,
	})
	Corner(999, userSettingsAvatarHolder)
	Create("UIStroke", {
		Color = THEME.ACCENT_BLUE,
		Transparency = 0.05,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = userSettingsAvatarHolder,
	})

	local userSettingsAvatar = Create("ImageLabel", {
		Name = "Avatar",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		BackgroundTransparency = 1,
		Image = avatarHeadshot.Image,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 143,
		Parent = userSettingsAvatarHolder,
	})
	Corner(999, userSettingsAvatar)

	local userSettingsWelcomeText = "Welcome to User Settings, " .. tostring(displayNick)
	local userSettingsWelcome = Create("TextLabel", {
		Name = "WelcomeText",
		Size = UDim2.new(1, -66, 0, 34),
		Position = UDim2.new(0, 64, 0, 1),
		BackgroundTransparency = 1,
		Text = userSettingsWelcomeText,
		TextColor3 = THEME.TEXT_PRIMARY,
		Font = FONT_BOLD,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 142,
		Parent = userSettings,
	})

	local userSettingsUsername = Create("TextLabel", {
		Name = "Username",
		Size = UDim2.new(1, -66, 0, 17),
		Position = UDim2.new(0, 64, 0, 36),
		BackgroundTransparency = 1,
		Text = "@" .. tostring(LocalPlayer.Name),
		TextColor3 = THEME.TEXT_MUTED,
		Font = FONT_REG,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 142,
		Parent = userSettings,
	})

	Create("Frame", {
		Name = "TopDivider",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 68),
		BackgroundColor3 = THEME.BORDER,
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		ZIndex = 142,
		Parent = userSettings,
	})

	local userSettingsBody = Create("ScrollingFrame", {
		Name = "UserSettingsBody",
		Size = UDim2.new(1, 0, 1, -92),
		Position = UDim2.new(0, 0, 0, 86),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ClipsDescendants = true,
		ZIndex = 142,
		Parent = userSettings,
	})
	local userSettingsBodyLayout = ListLayout(userSettingsBody, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 8)
	Padding(userSettingsBody, 6, 3, 18, 3)

	-- Hitbox only over the avatar/icon side, not the whole user text area.
	local userSettingsHitbox = Create("TextButton", {
		Name = "UserSettingsHitbox",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 30,
		Parent = avatarCircle,
	})

	-- ============================================================
	-- ASSEMBLE WINDOW INSTANCE
	-- ============================================================
	local self = setmetatable({
		Title = title,
		ScreenGui = screenGui,
		Window = root,
		NewTopBar = newTopBar,
		Sidebar = sidebar,
		SidebarTop = sidebarTop,
		SidebarToggle = sidebarToggle,
		SidebarToggleIcon = sidebarToggleIcon,
		CloseButton = closeDot,
		MinimizeButton = minimizeDot,
		IdleButton = idleDot,
		NotificationButton = notificationButton,
		NotificationIcon = notificationIcon,
		NotificationsEnabled = notificationEnabled,
		UserSettings = userSettings,
		UserSettingsScale = userSettingsScale,
		UserSettingsStroke = userSettingsStroke,
		UserSettingsInputBlocker = userSettingsInputBlocker,
		UserSettingsBackgroundTransparency = 0.4,
		UserSettingsStrokeTransparency = 0.18,
		UserSettingsHitbox = userSettingsHitbox,
		UserSettingsOpened = false,
		UserSettingsBasePosition = userSettingsBasePosition,
		UserSettingsWelcomeLabel = userSettingsWelcome,
		UserSettingsWelcomeText = userSettingsWelcomeText,
		UserSettingsUsernameLabel = userSettingsUsername,
		UserSettingsAvatarImage = userSettingsAvatar,
		UserSettingsBody = userSettingsBody,
		UserSettingsBodyLayout = userSettingsBodyLayout,
		UserSettingsSections = {},
		DefaultUserSettingsSection = nil,
		TopbarRealNick = topbarRealNick,
		TopbarVisualNick = topbarVisualNick,
		TopbarAvatarImage = avatarHeadshot,
		RealDisplayName = tostring(LocalPlayer.DisplayName or LocalPlayer.Name),
		RealUserName = tostring(LocalPlayer.Name),
		RealAvatar = avatarHeadshot.Image,
		HiddenMode = hiddenMode,
		HiddenName = hiddenName,
		HiddenAvatar = hiddenAvatar,
		DestroyCallbacks = {},
		MinimizeCallbacks = {},
		SidebarDivider = sidebarDivider,
		LineBelowPageTopBar = lineBelowPageTopBar,
		ContentArea = contentArea,
		TopBar = topBar,
		AppNameLabel = appNameLabel,
		LogoBox = logoBox,
		SidebarLogoExpandedSize = sidebarLogoSize,
		SidebarLogoClosedSize = sidebarLogoClosedSize,
		SidebarSearch = sidebarSearch,
		SidebarSearchStroke = sidebarSearchStroke,
		SearchIcon = searchIcon,
		SearchText = searchText,
		BreadcrumbTabLabel = breadcrumbTabLabel,
		BreadcrumbSectionLabel = breadcrumbSectionLabel,
		PageTitle = pageTitle,
		Pages = {},
		SidebarItems = {},
		Connections = {},
		CurrentPage = nil,
		CurrentTabName = "Dashboard",
		CurrentSectionName = "Section",
		SidebarState = "Expanded",
		SidebarClosed = false,
		Visible = true,
		Keybind = keybind,
		IconsType = iconsType,
	}, WindowClass)

	self.DefaultUserSettingsSection = self:UserSettingsSection({
		Name = "Account",
		Description = "Profile panel ready",
	})
	self:_ApplyIdentity(false)

	table.insert(self.Connections, sidebarToggle.MouseButton1Click:Connect(function()
		self:SetSidebarExpanded(self.SidebarState == "Closed")
	end))
	table.insert(self.Connections, closeDot.MouseButton1Click:Connect(function()
		self:Destroy()
	end))
	table.insert(self.Connections, minimizeDot.MouseButton1Click:Connect(function()
		self:Minimize()
	end))
	table.insert(self.Connections, notificationButton.MouseButton1Click:Connect(function()
		self:ToggleNotifications()
	end))
	table.insert(self.Connections, userSettingsHitbox.MouseButton1Click:Connect(function()
		self:ToggleUserSettings()
	end))
	if self._BindSidebarSearch then
		self:_BindSidebarSearch()
	end

	-- ============================================================
	-- WINDOW DRAG
	-- ============================================================
	local dragging = false
	local dragStartInput, dragStartMouse, dragStartPosition
	local function beginDrag(input)
		dragging = true
		dragStartInput = input
		dragStartMouse = input.Position
		dragStartPosition = root.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragStartInput = nil
			end
		end)
	end
	local function bindDrag(handle)
		handle.Active = true
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				beginDrag(input)
			end
		end)
	end
	bindDrag(newTopBar)
	bindDrag(sidebarTop)

	-- ============================================================
	-- DRAG BAR (separate component below the window — see Components/DragBar.lua)
	-- It's parented to the screenGui, follows the window in real time and
	-- mirrors window visibility. It does not share state with the topbar /
	-- sidebar drag pipeline.
	-- ============================================================
	local DragBar = require(script.Parent.DragBar)
	self.DragBar = DragBar.new(screenGui, root)
	for _, conn in ipairs(self.DragBar.Connections) do
		table.insert(self.Connections, conn)
	end

	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragStartMouse or not dragStartPosition then return end
		local isMouseDrag = dragStartInput and dragStartInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouchDrag = dragStartInput and dragStartInput.UserInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch
		if not isMouseDrag and not isTouchDrag then return end
		local delta = input.Position - dragStartMouse
		root.Position = UDim2.new(dragStartPosition.X.Scale, dragStartPosition.X.Offset + delta.X, dragStartPosition.Y.Scale, dragStartPosition.Y.Offset + delta.Y)
	end))
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == self.Keybind then self:Toggle() end
	end))

	-- ============================================================
	-- ============================================================
	-- CAMERA EFFECTS (FOV zoom on open, restore on minimize)
	-- ============================================================
	local CameraEffects = require(script.Parent.CameraEffects)
	self.CameraEffects = CameraEffects.new()
	self.CameraEffects:Apply()

	task.spawn(function()
		while root.Parent do
			TweenService:Create(logoBox, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundColor3 = THEME.ACCENT_BLUE }):Play()
			task.wait(2)
			TweenService:Create(logoBox, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundColor3 = Color3.fromRGB(62, 24, 116) }):Play()
			task.wait(2)
		end
	end)

	return self
end

return Build
