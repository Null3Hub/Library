--[[
    Apex UI Library - Window methods: sidebar, breadcrumbs, page activation
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Parent.Util)

local Create     = Util.Create
local ResolveIcon = Util.ResolveIcon

local THEME       = Theme.THEME
local FONT_REG    = Theme.FONT_REG
local FONT_SEMI   = Theme.FONT_SEMI
local TW_FAST     = Theme.TW_FAST
local TW_SIDEBAR  = Theme.TW_SIDEBAR
local SIDEBAR_EXPANDED  = Theme.SIDEBAR_EXPANDED
local SIDEBAR_COLLAPSED = Theme.SIDEBAR_COLLAPSED
local NEW_TOPBAR_H      = Theme.NEW_TOPBAR_H
local TOPBAR_H          = Theme.TOPBAR_H

local Sidebar = {}

function Sidebar:_UpdateBreadcrumb()
	if self.BreadcrumbTabLabel then self.BreadcrumbTabLabel.Text = self.CurrentTabName or "Dashboard" end
	if self.BreadcrumbSectionLabel then self.BreadcrumbSectionLabel.Text = self.CurrentSectionName or "Section" end
	if self.PageTitle then self.PageTitle.Text = self.CurrentTabName or self.Title end
end

function Sidebar:_SetActivePage(page)
	if not page or self.CurrentPage == page then return end
	if self.CurrentPage and self._ClearSearch then
		self:_ClearSearch()
	end
	self.CurrentPage = page
	self.CurrentTabName = page.Name
	self.CurrentSectionName = page.SectionName or "Section"
	for _, p in ipairs(self.Pages) do
		local selected = p == page
		p.Viewport.Visible = selected
		if p.Viewport and p.Viewport.Parent then
			p.Viewport:SetAttribute("ApexForegroundInputBlocked", self.UserSettingsOpened and selected or false)
		end
		TweenService:Create(p.Nav.ActiveBar, TW_FAST, {
			Size = selected and UDim2.new(0, 3, 0.54, 0) or UDim2.new(0, 0, 0.54, 0),
		}):Play()
		p.Nav.ActiveBar.Visible = selected
		TweenService:Create(p.Nav.Button, TW_FAST, {
			-- Selected state no longer uses a filled glow/background.
			-- Only the small accent bar on the left marks the active page.
			BackgroundColor3 = THEME.BG_SIDEBAR,
			BackgroundTransparency = 1,
		}):Play()
		if p.Nav.IconIsImage then
			TweenService:Create(p.Nav.Icon, TW_FAST, {
				ImageColor3 = selected and THEME.TEXT_ACCENT or THEME.TEXT_SECONDARY,
			}):Play()
		else
			TweenService:Create(p.Nav.Icon, TW_FAST, {
				TextColor3 = selected and THEME.TEXT_ACCENT or THEME.TEXT_SECONDARY,
			}):Play()
		end
		p.Nav.Text.Font = selected and FONT_SEMI or FONT_REG
		TweenService:Create(p.Nav.Text, TW_FAST, {
			TextColor3 = selected and THEME.TEXT_PRIMARY or THEME.TEXT_SECONDARY,
		}):Play()
	end
	self:_UpdateBreadcrumb()
end

function Sidebar:_ReflowNav(animate)
	local isClosed = self.SidebarClosed and true or false
	local y = 112
	local tweenInfo = animate and TW_SIDEBAR or nil

	local function apply(inst, props)
		if not inst then return end
		if tweenInfo then
			TweenService:Create(inst, tweenInfo, props):Play()
		else
			for prop, value in pairs(props) do
				inst[prop] = value
			end
		end
	end

	for _, item in ipairs(self.SidebarItems or {}) do
		if item.Type == "Page" and item.Page and item.Page.Nav then
			local page = item.Page
			page.Nav.BaseY = y
			page.Nav.BaseYClosed = y

			apply(page.Nav.Button, {
				Position = isClosed and UDim2.new(0.5, -18, 0, y) or UDim2.new(0, 14, 0, y),
				Size = isClosed and UDim2.new(0, 36, 0, 36) or UDim2.new(1, -28, 0, 34),
			})

			-- Keep nav icons fixed-size when collapsed. Image icons no longer
			-- stretch to fill the whole selected tab square.
			apply(page.Nav.Icon, {
				Size = isClosed and UDim2.new(0, 24, 0, 24) or UDim2.new(0, 20, 0, 20),
				Position = isClosed and UDim2.new(0.5, -12, 0.5, -12) or UDim2.new(0, 17, 0.5, -10),
			})

			apply(page.Nav.Text, {
				TextTransparency = isClosed and 1 or 0,
			})

			y = y + 40
		elseif item.Type == "PageSection" and item.Label then
			-- PageSection is an expanded-sidebar label only.
			item.Label.Visible = not isClosed
			if not isClosed then
				apply(item.Label, {
					Position = UDim2.new(0, 14, 0, y),
					Size = UDim2.new(1, -28, 0, 22),
					TextTransparency = 0,
				})
				y = y + 29
			else
				item.Label.TextTransparency = 1
			end
		elseif item.Type == "Divider" and item.Frame then
			-- Dividers stay visible in both modes. When closed they become
			-- compact centered separators instead of disappearing.
			item.Frame.Visible = true
			apply(item.Frame, {
				Position = isClosed and UDim2.new(0.5, -17, 0, y + 5) or UDim2.new(0, 14, 0, y + 5),
				Size = isClosed and UDim2.new(0, 34, 0, 1) or UDim2.new(1, -28, 0, 1),
				BackgroundTransparency = 0.42,
			})
			y = y + 17
		end
	end
end

function Sidebar:SetSidebarExpanded(expanded)
	local isExpanded = expanded and true or false
	self.SidebarState = isExpanded and "Expanded" or "Closed"
	self.SidebarClosed = not isExpanded
	local targetW = isExpanded and SIDEBAR_EXPANDED or SIDEBAR_COLLAPSED

	-- Animate the sidebar toggle icon swap.
	-- Expanded  -> points left  (collapse action)
	-- Closed    -> points right (expand action)
	local toggleIcon = self.SidebarToggleIcon
	if toggleIcon then
		local nextImage = ResolveIcon(isExpanded and "solar:double-alt-arrow-left-line-duotone" or "solar:double-alt-arrow-right-line-duotone")
		self._SidebarToggleIconSwapToken = (self._SidebarToggleIconSwapToken or 0) + 1
		local swapToken = self._SidebarToggleIconSwapToken

		TweenService:Create(toggleIcon, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
			Rotation = isExpanded and -8 or 8,
		}):Play()

		task.delay(0.09, function()
			if not toggleIcon.Parent or self._SidebarToggleIconSwapToken ~= swapToken then return end
			toggleIcon.Image = nextImage
			toggleIcon.Rotation = isExpanded and 8 or -8
			TweenService:Create(toggleIcon, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0,
				Rotation = 0,
			}):Play()
		end)
	end
	TweenService:Create(self.Sidebar, TW_SIDEBAR, { Size = UDim2.new(0, targetW, 1, -NEW_TOPBAR_H) }):Play()
	TweenService:Create(self.ContentArea, TW_SIDEBAR, {
		Size = UDim2.new(1, -targetW, 1, -NEW_TOPBAR_H),
		Position = UDim2.new(0, targetW, 0, NEW_TOPBAR_H),
	}):Play()
	TweenService:Create(self.SidebarDivider, TW_SIDEBAR, {
		Position = isExpanded and UDim2.new(0, targetW, 0, NEW_TOPBAR_H) or UDim2.new(0, targetW, 0, NEW_TOPBAR_H + TOPBAR_H),
		Size = isExpanded and UDim2.new(0, 1, 1, -NEW_TOPBAR_H) or UDim2.new(0, 1, 1, -(NEW_TOPBAR_H + TOPBAR_H)),
		BackgroundTransparency = 0.35,
	}):Play()
	TweenService:Create(self.LineBelowPageTopBar, TW_SIDEBAR, {
		Size = isExpanded and UDim2.new(1, -targetW, 0, 1) or UDim2.new(1, 0, 0, 1),
		Position = isExpanded and UDim2.new(0, targetW, 0, NEW_TOPBAR_H + TOPBAR_H) or UDim2.new(0, 0, 0, NEW_TOPBAR_H + TOPBAR_H),
		BackgroundTransparency = 0.35,
	}):Play()

	TweenService:Create(self.AppNameLabel, TW_SIDEBAR, { TextTransparency = isExpanded and 0 or 1 }):Play()
	local expandedLogoSize = self.SidebarLogoExpandedSize or 36
	local closedLogoSize = self.SidebarLogoClosedSize or math.max(expandedLogoSize, 38)
	TweenService:Create(self.LogoBox, TW_SIDEBAR, {
		Size = isExpanded and UDim2.new(0, expandedLogoSize, 0, expandedLogoSize) or UDim2.new(0, closedLogoSize, 0, closedLogoSize),
		Position = isExpanded and UDim2.new(0, 14, 0.5, -expandedLogoSize / 2) or UDim2.new(0.5, -closedLogoSize / 2, 0.5, -closedLogoSize / 2),
	}):Play()
	TweenService:Create(self.SidebarSearch, TW_SIDEBAR, {
		Size = isExpanded and UDim2.new(1, -28, 0, 32) or UDim2.new(0, 34, 0, 34),
		Position = isExpanded and UDim2.new(0, 14, 0, 62) or UDim2.new(0.5, -17, 0, 62),
		BackgroundTransparency = isExpanded and 0 or 0.08,
	}):Play()
	TweenService:Create(self.SidebarSearchStroke, TW_SIDEBAR, { Transparency = isExpanded and 0 or 0.18 }):Play()
	TweenService:Create(self.SearchIcon, TW_SIDEBAR, {
		Size = isExpanded and UDim2.new(0, 16, 0, 16) or UDim2.new(0, 18, 0, 18),
		Position = isExpanded and UDim2.new(0, 10, 0.5, -8) or UDim2.new(0.5, -9, 0.5, -9),
		ImageTransparency = 0,
	}):Play()
	TweenService:Create(self.SearchText, TW_SIDEBAR, { TextTransparency = isExpanded and 0 or 1 }):Play()

	self:_ReflowNav(true)
end

function Sidebar:UpdateContentCanvas()
	-- Safe public refresh helper. Performs the same canvas calculation directly
	-- instead of calling Page:UpdateCanvas(), preventing recursive stack overflow.
	local page = self.CurrentPage
	if not page or not page.Scroll or not page.Padding then return end
	if page._UpdatingCanvas then return end

	page._UpdatingCanvas = true
	local contentHeight = (page._ContentHeight or 0)
		+ page.Padding.PaddingTop.Offset + page.Padding.PaddingBottom.Offset
	page.Scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	page._UpdatingCanvas = false
end

function Sidebar:PageSection(args)
	-- Optional sidebar label shown only when the sidebar is expanded.
	-- Usage: Window:PageSection({ Name = "MAIN" }) or Window:PageSection("MAIN")
	local sectionArgs = type(args) == "table" and args or nil
	local sectionName = sectionArgs and (sectionArgs.Name or sectionArgs.Title or sectionArgs.Text or sectionArgs.name or sectionArgs.title or sectionArgs.text) or args
	sectionName = tostring(sectionName or "Section")

	local label = Create("TextLabel", {
		Name = "PageSection_" .. sectionName,
		Size = UDim2.new(1, -28, 0, 22),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = sectionName,
		Font = FONT_SEMI,
		TextSize = 12,
		TextColor3 = THEME.TEXT_MUTED,
		TextTransparency = self.SidebarClosed and 1 or 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = not self.SidebarClosed,
		ZIndex = 8,
		Parent = self.Sidebar,
	})

	local item = {
		Type = "PageSection",
		Name = sectionName,
		Label = label,
	}
	table.insert(self.SidebarItems, item)
	self:_ReflowNav()

	return {
		Label = label,
		SetName = function(_, newName)
			sectionName = tostring(newName or "Section")
			item.Name = sectionName
			label.Name = "PageSection_" .. sectionName
			label.Text = sectionName
		end,
		Destroy = function()
			for index, sidebarItem in ipairs(self.SidebarItems) do
				if sidebarItem == item then
					table.remove(self.SidebarItems, index)
					break
				end
			end
			label:Destroy()
			self:_ReflowNav()
		end,
	}
end

function Sidebar:SideBarDivider()
	-- Optional sidebar divider. Full-width in expanded mode and a compact
	-- centered separator in collapsed mode.
	local divider = Create("Frame", {
		Name = "SidebarCustomDivider",
		Size = self.SidebarClosed and UDim2.new(0, 34, 0, 1) or UDim2.new(1, -28, 0, 1),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundColor3 = THEME.BORDER,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Visible = true,
		ZIndex = 8,
		Parent = self.Sidebar,
	})
	Create("UIGradient", {
		Name = "SideFade",
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.12, 0.45),
			NumberSequenceKeypoint.new(0.50, 0.12),
			NumberSequenceKeypoint.new(0.88, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = divider,
	})

	local item = {
		Type = "Divider",
		Frame = divider,
	}
	table.insert(self.SidebarItems, item)
	self:_ReflowNav()

	return {
		Divider = divider,
		Destroy = function()
			for index, sidebarItem in ipairs(self.SidebarItems) do
				if sidebarItem == item then
					table.remove(self.SidebarItems, index)
					break
				end
			end
			divider:Destroy()
			self:_ReflowNav()
		end,
	}
end

return Sidebar
