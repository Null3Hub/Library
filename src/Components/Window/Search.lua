--[[
    Apex UI Library - Window methods: sidebar search
    Filters/highlights elements from the current page without changing layout.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Parent.Theme)

local THEME = Theme.THEME
local TW_SEARCH = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_SCROLL = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local Search = {}

local MATCH_BACKGROUND_TRANSPARENCY = 0.04
local DIM_BACKGROUND_TRANSPARENCY = 0.62
local MATCH_STROKE_TRANSPARENCY = 0.02
local DIM_STROKE_TRANSPARENCY = 0.74
local SCROLL_MARGIN = 18

local function normalize(value)
	return tostring(value or ""):lower():gsub("%s+", " ")
end

local function tokenize(query)
	local output = {}
	for token in normalize(query):gmatch("%S+") do
		table.insert(output, token)
	end
	return output
end

local function matchesTokens(text, tokens)
	for _, token in ipairs(tokens) do
		if not string.find(text, token, 1, true) then
			return false
		end
	end
	return true
end

local function readColorAttribute(instance, name, fallback)
	local value = instance and instance:GetAttribute(name)
	return typeof(value) == "Color3" and value or fallback
end

local function readNumberAttribute(instance, name, fallback)
	local value = instance and instance:GetAttribute(name)
	return type(value) == "number" and value or fallback
end

local function getElementStroke(element)
	if not element then return nil end
	for _, child in ipairs(element:GetChildren()) do
		if child:IsA("UIStroke") then
			return child
		end
	end
	return nil
end

local function getSectionText(section)
	local container = section and section.Container
	local title = (container and container:GetAttribute("ApexSearchTitle")) or section.Name or ""
	local description = (container and container:GetAttribute("ApexSearchDescription")) or section.Subtitle or ""
	return normalize(title .. " " .. description)
end

local function getElementText(element)
	local title = element and element:GetAttribute("ApexSearchTitle") or ""
	local description = element and element:GetAttribute("ApexSearchDescription") or ""
	return normalize(tostring(title or "") .. " " .. tostring(description or ""))
end

local function getSectionElements(section)
	if type(section.Elements) == "table" and #section.Elements > 0 then
		return section.Elements
	end

	local output = {}
	local elementsList = section and section.ElementsList
	if elementsList then
		for _, child in ipairs(elementsList:GetChildren()) do
			if child:GetAttribute("ApexSearchable") then
				table.insert(output, child)
			end
		end
	end
	return output
end

local function tween(instance, props)
	if instance and instance.Parent then
		TweenService:Create(instance, TW_SEARCH, props):Play()
	end
end

local function styleElement(element, state)
	if not element or not element.Parent then return end
	if element:GetAttribute("ApexSearchState") == state then return end
	element:SetAttribute("ApexSearchState", state)

	local stroke = getElementStroke(element)
	local baseBackgroundColor = readColorAttribute(element, "ApexBaseBackgroundColor", THEME.BG_BUTTON)
	local baseBackgroundTransparency = readNumberAttribute(element, "ApexBaseBackgroundTransparency", 0.12)
	local baseStrokeColor = readColorAttribute(element, "ApexBaseStrokeColor", THEME.BORDER)
	local baseStrokeTransparency = readNumberAttribute(element, "ApexBaseStrokeTransparency", 0)

	if state == "match" then
		tween(element, {
			BackgroundColor3 = THEME.BG_HOVER,
			BackgroundTransparency = MATCH_BACKGROUND_TRANSPARENCY,
		})
		tween(stroke, {
			Color = Color3.fromRGB(136, 131, 163),
			Transparency = MATCH_STROKE_TRANSPARENCY,
		})
	elseif state == "dim" then
		tween(element, {
			BackgroundColor3 = baseBackgroundColor,
			BackgroundTransparency = DIM_BACKGROUND_TRANSPARENCY,
		})
		tween(stroke, {
			Color = baseStrokeColor,
			Transparency = DIM_STROKE_TRANSPARENCY,
		})
	else
		tween(element, {
			BackgroundColor3 = baseBackgroundColor,
			BackgroundTransparency = baseBackgroundTransparency,
		})
		tween(stroke, {
			Color = baseStrokeColor,
			Transparency = baseStrokeTransparency,
		})
	end
end

function Search:_ScrollSearchResultIntoView(page, element)
	local scroll = page and page.Scroll
	if not scroll or not element then return end

	self._SearchScrollToken = (self._SearchScrollToken or 0) + 1
	local token = self._SearchScrollToken
	task.defer(function()
		if self._SearchScrollToken ~= token then return end
		if not scroll.Parent or not element.Parent then return end

		local viewportTop = scroll.AbsolutePosition.Y
		local viewportBottom = viewportTop + scroll.AbsoluteSize.Y
		local elementTop = element.AbsolutePosition.Y
		local elementBottom = elementTop + element.AbsoluteSize.Y

		if elementTop >= viewportTop + SCROLL_MARGIN and elementBottom <= viewportBottom - SCROLL_MARGIN then
			return
		end

		local targetY = scroll.CanvasPosition.Y + (elementTop - viewportTop) - SCROLL_MARGIN
		local maxY = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y)
		targetY = math.clamp(targetY, 0, maxY)
		TweenService:Create(scroll, TW_SCROLL, { CanvasPosition = Vector2.new(0, targetY) }):Play()
	end)
end

function Search:_ApplySearch(query)
	local page = self.CurrentPage
	if not page or not page.Sections then return end

	local tokens = tokenize(query)
	local active = #tokens > 0
	local firstMatch = nil
	local matchCount = 0

	for _, section in ipairs(page.Sections) do
		local sectionText = getSectionText(section)
		local sectionMatches = active and matchesTokens(sectionText, tokens)
		for _, element in ipairs(getSectionElements(section)) do
			local elementMatches = sectionMatches or (active and matchesTokens(sectionText .. " " .. getElementText(element), tokens))
			local state = "normal"
			if active then
				state = elementMatches and "match" or "dim"
			end

			styleElement(element, state)
			if active and elementMatches then
				matchCount += 1
				firstMatch = firstMatch or element
			end
		end
	end

	self._SearchQuery = tostring(query or "")
	self._SearchMatchCount = matchCount
	if firstMatch then
		self:_ScrollSearchResultIntoView(page, firstMatch)
	end
end

function Search:_UpdateSearchChrome()
	local box = self.SearchText
	if not box or not box:IsA("TextBox") then return end

	local active = self._SearchFocused or box.Text ~= ""
	tween(self.SidebarSearch, {
		BackgroundColor3 = active and THEME.BG_HOVER or THEME.BG_SEARCH,
	})
	tween(self.SidebarSearchStroke, {
		Color = active and Color3.fromRGB(136, 131, 163) or THEME.BORDER,
		Transparency = active and 0 or 0.08,
	})
	tween(self.SearchIcon, {
		ImageColor3 = active and Color3.fromRGB(236, 232, 255) or THEME.TEXT_MUTED,
	})
	tween(box, {
		TextColor3 = active and THEME.TEXT_PRIMARY or THEME.TEXT_SECONDARY,
		PlaceholderColor3 = active and THEME.TEXT_SECONDARY or THEME.TEXT_MUTED,
	})
end

function Search:_ClearSearch()
	local box = self.SearchText
	self._SearchScrollToken = (self._SearchScrollToken or 0) + 1

	if box and box:IsA("TextBox") and box.Text ~= "" then
		box.Text = ""
	else
		self:_ApplySearch("")
		self:_UpdateSearchChrome()
	end
end

function Search:_BindSidebarSearch()
	if self._SearchBound then return end
	local box = self.SearchText
	if not box or not box:IsA("TextBox") then return end

	self._SearchBound = true
	self._SearchFocused = false
	self.Connections = self.Connections or {}

	local function refresh()
		self:_ApplySearch(box.Text)
		self:_UpdateSearchChrome()
	end

	table.insert(self.Connections, box:GetPropertyChangedSignal("Text"):Connect(refresh))
	table.insert(self.Connections, box.Focused:Connect(function()
		self._SearchFocused = true
		self:_UpdateSearchChrome()
	end))
	table.insert(self.Connections, box.FocusLost:Connect(function()
		self._SearchFocused = false
		self:_UpdateSearchChrome()
	end))

	if self.SidebarSearch then
		table.insert(self.Connections, self.SidebarSearch.InputBegan:Connect(function(input)
			if self.SidebarClosed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				box:CaptureFocus()
			end
		end))
	end

	refresh()
end

return Search
