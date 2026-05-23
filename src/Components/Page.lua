--[[
    Apex UI Library - Page class
    A page lives inside the window. It owns its sidebar nav button, its viewport
    (scrolling content), and the sections inside it.

    Sections support two layout modes:
        Mode 1 (default): full width, stacked vertically (one per row)
        Mode 2 (card):    half width, max 2 per row. Falls back to full width
                          when the viewport is narrower than RESPONSIVE_THRESHOLD.

    The order of declaration is preserved. Mode 1 always takes a full row; Mode 2
    sections pair up with the next adjacent Mode 2 section (if any) on the same row.
]]

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)
local Section = require(script.Parent.Section)

local Create     = Util.Create
local Corner     = Util.Corner
local ListLayout = Util.ListLayout

local THEME      = Theme.THEME
local FONT_BOLD  = Theme.FONT_BOLD
local FONT_REG   = Theme.FONT_REG
local CORNER_MD  = Theme.CORNER_MD

local CARD_GAP = 8                   -- horizontal gap between two Mode-2 sections in a row
local RESPONSIVE_THRESHOLD = 480     -- below this absolute width, Mode 2 collapses to full width

local Page = {}
Page.__index = Page

function Page:UpdateCanvas()
	-- Only update this page's scroll canvas. Do NOT call Window:UpdateContentCanvas()
	-- from here, otherwise we recurse Page <-> Window forever.
	if self._UpdatingCanvas then return end
	self._UpdatingCanvas = true

	if self.Scroll and self.Padding then
		local contentHeight = (self._ContentHeight or 0)
			+ self.Padding.PaddingTop.Offset + self.Padding.PaddingBottom.Offset
		self.Scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	end

	self._UpdatingCanvas = false
end

--- Build the visible frame for a section. Internal helper, used by :Section().
local function buildSectionFrame(parent, name, subtitle, layoutOrder)
	local sectionFrame = Create("Frame", {
		Name = "Section_" .. tostring(name or "Section"),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.BG_SIDEBAR,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 8,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	sectionFrame:SetAttribute("ApexSearchTitle", tostring(name or "Section"))
	sectionFrame:SetAttribute("ApexSearchDescription", tostring(subtitle or ""))
	Corner(CORNER_MD, sectionFrame)
	local sectionStroke = Create("UIStroke", {
		Color = Color3.fromRGB(142, 142, 150),
		Transparency = 0,
		Thickness = 1.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = sectionFrame,
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

	local header = Create("Frame", {
		Name = "SectionHeader",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 9,
		Parent = sectionFrame,
	})
	Util.Padding(header, 0, 16, 0, 16)
	Create("TextLabel", {
		Name = "TabSection",
		Size = UDim2.new(1, -88, 0, 18),
		Position = UDim2.new(0, 0, 0, 12),
		BackgroundTransparency = 1,
		Text = tostring(name or "TabSection"),
		Font = FONT_BOLD,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(236, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 10,
		Parent = header,
	})
	Create("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.new(1, -88, 0, 14),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = subtitle or "Basic controls rebuilt inside a clipped, layout-safe section",
		Font = FONT_REG,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(145, 139, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 10,
		Parent = header,
	})

	local elementsClip = Create("Frame", {
		Name = "ElementsClip",
		Size = UDim2.new(1, -36, 0, 0),
		Position = UDim2.new(0, 18, 0, 52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 9,
		Parent = sectionFrame,
	})
	local elementsList = Create("Frame", {
		Name = "ElementsList",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 9,
		Parent = elementsClip,
	})
	local elementsLayout = ListLayout(elementsList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 8)

	return sectionFrame, header, elementsClip, elementsList, elementsLayout
end

--- Reflow sections into rows of two (Mode 2 pairs) or full rows (Mode 1).
-- Positions and sizes are written explicitly so the order of declaration is
-- always preserved regardless of mode mix.
function Page:_ReflowSections()
	if not self.Scroll or not self.Sections then return end

	local pageWidth = self.Scroll.AbsoluteSize.X
	if pageWidth <= 0 then
		-- Scroll not measured yet, defer once
		task.defer(function() self:_ReflowSections() end)
		return
	end

	local padLeft = self.Padding and self.Padding.PaddingLeft.Offset or 12
	local padRight = self.Padding and self.Padding.PaddingRight.Offset or 12
	local innerWidth = pageWidth - padLeft - padRight
	local rowGap = 8 -- vertical gap between rows
	local collapse = innerWidth < RESPONSIVE_THRESHOLD

	-- Half width for Mode 2 (50% minus half the horizontal gap)
	local halfWidth = math.floor((innerWidth - CARD_GAP) / 2)

	local y = 0
	local i = 1
	while i <= #self.Sections do
		local s = self.Sections[i]
		if not s.Container then i = i + 1; continue end

		local h = s._BaseHeight or 0

		if s.Mode == 2 and not collapse then
			local nextS = self.Sections[i + 1]
			if nextS and nextS.Mode == 2 and not collapse then
				-- Pair on the same row, max of both heights
				local rowH = math.max(h, nextS._BaseHeight or 0)
				s.Container.Position = UDim2.fromOffset(0, y)
				s.Container.Size     = UDim2.fromOffset(halfWidth, h)
				nextS.Container.Position = UDim2.fromOffset(halfWidth + CARD_GAP, y)
				nextS.Container.Size     = UDim2.fromOffset(innerWidth - halfWidth - CARD_GAP, nextS._BaseHeight or 0)
				y = y + rowH + rowGap
				i = i + 2
			else
				-- Lone Mode-2: still half width
				s.Container.Position = UDim2.fromOffset(0, y)
				s.Container.Size     = UDim2.fromOffset(halfWidth, h)
				y = y + h + rowGap
				i = i + 1
			end
		else
			-- Mode 1 (or collapsed Mode 2): full row
			s.Container.Position = UDim2.fromOffset(0, y)
			s.Container.Size     = UDim2.fromOffset(innerWidth, h)
			y = y + h + rowGap
			i = i + 1
		end
	end

	-- Total content height for the scroll canvas (subtract trailing gap)
	self._ContentHeight = math.max(0, y - rowGap)
	self:UpdateCanvas()
end

--- Create a Section inside this page.
-- @param name      string title shown in the header
-- @param subtitle  string subtitle (optional)
-- @param mode      number 1 (full width, default) or 2 (half width / card)
-- Alternatively pass a single config table as the first argument:
--     page:Section({ Name = "...", Subtitle = "...", Mode = 2 })
function Page:Section(name, subtitle, mode)
	local cfg
	if type(name) == "table" then
		cfg = name
	else
		cfg = { Name = name, Subtitle = subtitle, Mode = mode }
	end

	local sectionName = cfg.Name or cfg.Title or "Section"
	local sectionSubtitle = cfg.Subtitle or cfg.Description
	local sectionMode = (tonumber(cfg.Mode) == 2) and 2 or 1

	local layoutOrder = #self.Sections + 1
	local sectionFrame, header, elementsClip, elementsList, elementsLayout =
		buildSectionFrame(self.Scroll, sectionName, sectionSubtitle, layoutOrder)

	local section = setmetatable({
		Page = self,
		Name = tostring(sectionName),
		Subtitle = sectionSubtitle and tostring(sectionSubtitle) or "",
		Container = sectionFrame,
		Header = header,
		ElementsClip = elementsClip,
		ElementsList = elementsList,
		ElementsLayout = elementsLayout,
		Elements = {},
		Mode = sectionMode,
		_BaseHeight = 0,
	}, Section)

	table.insert(self.Sections, section)

	local sizeConn = elementsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		section:_UpdateSize()
	end)
	if self.Window and self.Window.Connections then
		table.insert(self.Window.Connections, sizeConn)
	end

	-- When the scroll container resizes (window resize / sidebar collapse),
	-- re-evaluate the responsive layout.
	if not self._ReflowConn then
		self._ReflowConn = self.Scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:_ReflowSections()
		end)
		if self.Window and self.Window.Connections then
			table.insert(self.Window.Connections, self._ReflowConn)
		end
	end

	task.defer(function()
		section:_UpdateSize()
		self:_ReflowSections()
	end)

	return section
end

return Page
