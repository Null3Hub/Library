--[[
    Apex UI Library - Window methods: Page creation
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Parent.Util)
local Page  = require(script.Parent.Parent.Page)

local Create     = Util.Create
local Corner     = Util.Corner
local Padding    = Util.Padding
local ListLayout = Util.ListLayout
local ResolveIcon = Util.ResolveIcon
local IsForegroundInputBlocked = Util.IsForegroundInputBlocked

local THEME       = Theme.THEME
local FONT_REG    = Theme.FONT_REG
local TW_FAST     = Theme.TW_FAST
local TOPBAR_H    = Theme.TOPBAR_H
local CORNER_MD   = Theme.CORNER_MD

local Pages = {}

function Pages:Page(name, icon)
	-- Page API:
	--   Window:Page("Home", "rbxassetid://...")
	--   Window:Page({ Name = "Home", Icone = "house" })
	-- Native IconsV2 support:
	--   Icone = "house" / "lucide:house" / "geist:accessibility-unread"
	--   Icone = "solar:Home2Bold" / "sfsymbols:HouseFill"
	-- Also accepts Icon and Icone aliases.
	local pageArgs = type(name) == "table" and name or nil
	local pageName = pageArgs and (pageArgs.Name or pageArgs.Title or pageArgs.name or pageArgs.title) or name
	local pageIcon = pageArgs and (pageArgs.Icon or pageArgs.Icone or pageArgs.IconId or pageArgs.Image or pageArgs.icon or pageArgs.icone or pageArgs.image) or icon
	local pageIconType = pageArgs and (pageArgs.IconType or pageArgs.IconsType or pageArgs.Type or pageArgs.iconType or pageArgs.iconsType or pageArgs.type) or nil
	local pageIconColor = pageArgs and (pageArgs.IconColor or pageArgs.Color or pageArgs.iconColor or pageArgs.color) or nil

	pageName = tostring(pageName or "Page")
	local resolvedIcon, iconIsImage = ResolveIcon(pageIcon, pageIconType or self.IconsType or "lucide")
	pageIcon = resolvedIcon
	local pageViewport = Create("Frame", {
		Name = pageName .. "Page",
		Size = UDim2.new(1, 0, 1, -TOPBAR_H),
		Position = UDim2.new(0, 0, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 7,
		Parent = self.ContentArea,
	})
	Corner(CORNER_MD, pageViewport)
	local scroll = Create("ScrollingFrame", {
		Name = "ContentShell",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = THEME.BORDER_LIGHT,
		ScrollBarImageTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		CanvasPosition = Vector2.new(0, 0),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollingEnabled = true,
		Active = true,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = pageViewport,
	})
	local padding = Padding(scroll, 12, 12, 18, 12)
	-- No automatic layout: Page:_ReflowSections() positions each section explicitly
	-- (Position + Size) so we can support Mode 1 (full row) and Mode 2 (paired
	-- half-width) in any order. The page's UpdateCanvas() reads the resulting
	-- bounding box from _ReflowSections to size the scroll canvas.
	local layout = nil

	local navY = 122 + (#self.Pages * 41)
	local navButton = Create("TextButton", {
		Name = "NavItem_" .. pageName,
		Size = UDim2.new(1, -28, 0, 34),
		Position = UDim2.new(0, 14, 0, navY),
		BackgroundColor3 = THEME.BG_SIDEBAR,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		ZIndex = 8,
		Parent = self.Sidebar,
	})
	Corner(8, navButton)
	local activeBar = Create("Frame", {
		Name = "ActiveBar",
		Size = UDim2.new(0, 0, 0.54, 0),
		Position = UDim2.new(0, 0, 0.23, 0),
		BackgroundColor3 = THEME.ACCENT_BLUE,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 9,
		Parent = navButton,
	})
	Corner(2, activeBar)
	local iconText
	if iconIsImage then
		iconText = Create("ImageLabel", {
			Name = "Icon",
			Size = self.SidebarClosed and UDim2.new(0, 24, 0, 24) or UDim2.new(0, 20, 0, 20),
			Position = self.SidebarClosed and UDim2.new(0.5, -12, 0.5, -12) or UDim2.new(0, 17, 0.5, -10),
			BackgroundTransparency = 1,
			Image = pageIcon,
			ImageColor3 = pageIconColor or THEME.TEXT_SECONDARY,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 9,
			Parent = navButton,
		})
	else
		iconText = Create("TextLabel", {
			Name = "Icon",
			Size = self.SidebarClosed and UDim2.new(0, 24, 0, 24) or UDim2.new(0, 20, 0, 20),
			Position = self.SidebarClosed and UDim2.new(0.5, -12, 0.5, -12) or UDim2.new(0, 17, 0.5, -10),
			BackgroundTransparency = 1,
			Text = pageIcon,
			Font = FONT_REG,
			TextSize = 13,
			TextColor3 = pageIconColor or THEME.TEXT_SECONDARY,
			TextTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 9,
			Parent = navButton,
		})
	end
	local textObj = Create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -54, 1, 0),
		Position = UDim2.new(0, 50, 0, 0),
		BackgroundTransparency = 1,
		Text = pageName,
		Font = FONT_REG,
		TextSize = 12,
		TextColor3 = THEME.TEXT_SECONDARY,
		TextTransparency = self.SidebarClosed and 1 or 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 9,
		Parent = navButton,
	})

	local page = setmetatable({
		Window = self,
		Name = pageName,
		SectionName = "Section",
		Viewport = pageViewport,
		Scroll = scroll,
		Padding = padding,
		Layout = layout,
		Sections = {},
		Nav = {
			Button = navButton,
			ActiveBar = activeBar,
			Icon = iconText,
			IconIsImage = iconIsImage,
			Text = textObj,
			BaseY = navY,
			BaseYClosed = navY - 19,
		},
	}, Page)

	table.insert(self.Connections, navButton.MouseButton1Click:Connect(function()
		self:_SetActivePage(page)
	end))
	table.insert(self.Connections, navButton.MouseEnter:Connect(function()
		if IsForegroundInputBlocked(navButton) then return end
		if self.CurrentPage ~= page then
			TweenService:Create(navButton, TW_FAST, { BackgroundColor3 = THEME.BG_HOVER, BackgroundTransparency = 0 }):Play()
		end
	end))
	table.insert(self.Connections, navButton.MouseLeave:Connect(function()
		if self.CurrentPage ~= page then
			TweenService:Create(navButton, TW_FAST, { BackgroundTransparency = 1 }):Play()
		end
	end))
	table.insert(self.Connections, scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() page:UpdateCanvas() end))
	table.insert(self.Pages, page)
	table.insert(self.SidebarItems, { Type = "Page", Page = page })
	self:_ReflowNav()
	if not self.CurrentPage then self:_SetActivePage(page) end
	task.defer(function() page:UpdateCanvas() end)
	return page
end

return Pages
