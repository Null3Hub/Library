--[[
    Apex UI Library - Section Element: Dropdown
    Single or multi select dropdown with optional search.
    Uses gradient stroke menu and animated chevron exactly like the original.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)

local Create        = Util.Create
local Corner        = Util.Corner
local Stroke        = Util.Stroke
local Padding       = Util.Padding
local ListLayout    = Util.ListLayout
local SafeCallback  = Util.SafeCallback
local ResolveIcon   = Util.ResolveIcon
local IsForegroundInputBlocked = Util.IsForegroundInputBlocked

local THEME       = Theme.THEME
local FONT_REG    = Theme.FONT_REG
local FONT_SEMI   = Theme.FONT_SEMI
local TW_FAST     = Theme.TW_FAST
local TW_DROPDOWN = Theme.TW_DROPDOWN
local CORNER_MD   = Theme.CORNER_MD
local LOGO_ASSET  = Theme.LOGO_ASSET

local Dropdown = {}

function Dropdown.Build(section, configOrTitle, values, default, callback)
	local config = {}
	if type(configOrTitle) == "table" then
		config = configOrTitle
	else
		config.Title = tostring(configOrTitle or "Dropdown")
		config.Values = values or {}
		config.Default = default
		config.Callback = callback
	end

	local listValues = config.Values or config.Options or {}
	local hasSearch = config.Search == true
	local multi = config.Multi == true
	local baseH = 42
	local itemH = 38
	local itemGap = 4
	local menuPad = 6
	local searchH = 34
	local selected = {}
	local selectedValue = config.Default or listValues[1]
	local open = false
	local setOpen

	if multi then
		if type(config.Default) == "table" then
			for _, v in ipairs(config.Default) do selected[v] = true end
		elseif selectedValue ~= nil then
			selected[selectedValue] = true
		end
	end

	local function getSelectedText()
		if not multi then return tostring(selectedValue or "None") end
		local output = {}
		for _, v in ipairs(listValues) do
			if selected[v] then table.insert(output, tostring(v)) end
		end
		return (#output > 0 and table.concat(output, ", ")) or "None"
	end

	local function getValue()
		if not multi then return selectedValue end
		local output = {}
		for _, v in ipairs(listValues) do
			if selected[v] then table.insert(output, v) end
		end
		return output
	end

	local element = section:_BaseElement(config.Name or "ApexDropdown", baseH)
	element.ClipsDescendants = true
	local elStroke = element:FindFirstChildOfClass("UIStroke")
	section:_Title(element, config.Title or "Dropdown", config.Description)

	local trigger = Create("TextButton", {
		Name = "Trigger",
		Size = UDim2.new(1, 0, 0, baseH),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = element,
	})
	local valueLabel = Create("TextLabel", {
		Size = UDim2.new(0, 132, 0, 22),
		Position = UDim2.new(1, -170, 0, 10),
		BackgroundTransparency = 1,
		Text = getSelectedText(),
		Font = FONT_REG,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(178, 170, 210),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		Parent = trigger,
	})
	local arrow = Create("ImageLabel", {
		Name = "Chevron",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(1, -30, 0.5, -8),
		BackgroundTransparency = 1,
		Image = ResolveIcon("solar:alt-arrow-up-linear"),
		ImageColor3 = Color3.fromRGB(178, 170, 210),
		ImageTransparency = 0.08,
		Rotation = 180,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 12,
		Parent = trigger,
	})

	local menu = Create("Frame", {
		Name = "Menu",
		Size = UDim2.new(1, -8, 0, 0),
		Position = UDim2.new(0, 4, 0, baseH + 10),
		BackgroundColor3 = THEME.BG_SEARCH,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 12,
		Parent = element,
	})
	Corner(CORNER_MD, menu)
	local menuStroke = Stroke(menu, THEME.BORDER, 1)
	menuStroke.Transparency = 1
	Create("UIGradient", {
		Rotation = -45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 120, 132)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(155, 155, 168)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(120, 120, 132)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
		}),
		Parent = menuStroke,
	})
	Padding(menu, menuPad, menuPad, menuPad, menuPad)

	local searchBox
	if hasSearch then
		local sHolder = Create("Frame", {
			Size = UDim2.new(1, 0, 0, searchH - 4),
			BackgroundColor3 = Color3.fromRGB(28, 28, 31),
			BorderSizePixel = 0,
			ZIndex = 14,
			Parent = menu,
		})
		Corner(8, sHolder)
		Stroke(sHolder, THEME.BORDER, 1)
		Padding(sHolder, 0, 10, 0, 10)
		ListLayout(sHolder, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, 6)
		Create("ImageLabel", {
			Size = UDim2.new(0, 14, 0, 14),
			BackgroundTransparency = 1,
			Image = LOGO_ASSET,
			ImageColor3 = Color3.fromRGB(95, 90, 112),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 15,
			LayoutOrder = 1,
			Parent = sHolder,
		})
		searchBox = Create("TextBox", {
			Size = UDim2.new(1, -24, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search...",
			PlaceholderColor3 = Color3.fromRGB(95, 90, 112),
			Font = FONT_REG,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(236, 232, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			ZIndex = 15,
			LayoutOrder = 2,
			Parent = sHolder,
		})
	end

	local itemsFrame = Create("Frame", {
		Size = UDim2.new(1, 0, 1, hasSearch and -(searchH + 2) or 0),
		Position = UDim2.new(0, 0, 0, hasSearch and (searchH + 2) or 0),
		BackgroundTransparency = 1,
		ZIndex = 13,
		Parent = menu,
	})
	ListLayout(itemsFrame, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, itemGap)
	local noResults = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, itemH),
		BackgroundTransparency = 1,
		Text = "No results found",
		Font = FONT_REG,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(95, 90, 112),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = false,
		ZIndex = 14,
		Parent = itemsFrame,
	})

	local itemButtons = {}
	local itemLabels = {}
	local itemChecks = {}
	local control -- forward decl, populated near the end so item clicks can fire OnChanged

	local function refreshVisuals()
		valueLabel.Text = getSelectedText()
		for valueItem, item in pairs(itemButtons) do
			local active = multi and selected[valueItem] or ((not multi) and valueItem == selectedValue)
			TweenService:Create(item, TW_FAST, { BackgroundTransparency = 1 }):Play()
			if itemLabels[valueItem] then
				local targetX = (multi and active) and 28 or 0
				TweenService:Create(itemLabels[valueItem], TW_FAST, {
					Position = UDim2.new(0, targetX, 0, 0),
					TextColor3 = active and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(178, 170, 210),
				}):Play()
				local sc = itemLabels[valueItem]:FindFirstChildOfClass("UIScale")
				if sc then TweenService:Create(sc, TW_FAST, { Scale = active and 1.08 or 1.0 }):Play() end
				itemLabels[valueItem].Font = active and FONT_SEMI or FONT_REG
			end
			if itemChecks[valueItem] then
				local img = itemChecks[valueItem]:FindFirstChildOfClass("ImageLabel")
				if img then TweenService:Create(img, TW_FAST, { ImageTransparency = active and 0 or 1 }):Play() end
			end
		end
	end

	for idx, valueItem in ipairs(listValues) do
		local item = Create("TextButton", {
			Name = "Item_" .. tostring(idx),
			Size = UDim2.new(1, 0, 0, itemH),
			BackgroundColor3 = THEME.BG_SEARCH,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 14,
			LayoutOrder = idx,
			Parent = itemsFrame,
		})
		Corner(8, item)
		Padding(item, 0, 12, 0, 12)

		if multi then
			local logoFrame = Create("Frame", {
				Size = UDim2.new(0, 26, 0, 26),
				Position = UDim2.new(0, -5, 0.5, -12),
				BackgroundTransparency = 1,
				Visible = true,
				ZIndex = 15,
				Parent = item,
			})
			Create("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				Image = LOGO_ASSET,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 16,
				Parent = logoFrame,
			})
			itemChecks[valueItem] = logoFrame
		end

		itemLabels[valueItem] = Create("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(valueItem),
			Font = FONT_REG,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(178, 170, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 15,
			Parent = item,
		})
		Create("UIScale", { Scale = 1, Parent = itemLabels[valueItem] })
		itemButtons[valueItem] = item

		item.MouseEnter:Connect(function()
			if IsForegroundInputBlocked(item) then return end
			local active = multi and selected[valueItem] or ((not multi) and valueItem == selectedValue)
			if not active then
				TweenService:Create(item, TW_FAST, {
					BackgroundTransparency = 0.85,
					BackgroundColor3 = Color3.fromRGB(60, 60, 68),
				}):Play()
				local sc = itemLabels[valueItem]:FindFirstChildOfClass("UIScale")
				if sc then TweenService:Create(sc, TW_FAST, { Scale = 1.04 }):Play() end
			end
		end)
		item.MouseLeave:Connect(function()
			local active = multi and selected[valueItem] or ((not multi) and valueItem == selectedValue)
			if not active and itemLabels[valueItem] then
				local sc = itemLabels[valueItem]:FindFirstChildOfClass("UIScale")
				if sc then TweenService:Create(sc, TW_FAST, { Scale = 1.0 }):Play() end
			end
			refreshVisuals()
		end)
		item.MouseButton1Click:Connect(function()
			if multi then
				selected[valueItem] = not selected[valueItem]
			else
				selectedValue = valueItem
				task.defer(function() setOpen(false) end)
			end
			refreshVisuals()
			local v = getValue()
			if control then control.Value = v end
			SafeCallback(config.Callback, v)
			if control then
				for _, fn in ipairs(control._changedListeners) do SafeCallback(fn, v) end
			end
		end)
	end

	local function calcMenuHeight()
		local visCount = 0
		for _, itm in pairs(itemButtons) do
			if itm.Visible then visCount = visCount + 1 end
		end
		local searchSpace = hasSearch and (searchH + 2) or 0
		local itemsH = visCount > 0 and (visCount * itemH + math.max(0, visCount - 1) * itemGap) or itemH
		return menuPad * 2 + searchSpace + itemsH
	end

	setOpen = function(state)
		if open == state then return end
		open = state
		local menuH = open and calcMenuHeight() or 0
		local totalH = baseH + (open and (menuH + 16) or 0)
		element.ZIndex = open and 25 or 10
		TweenService:Create(element, TW_DROPDOWN, { Size = UDim2.new(1, 0, 0, totalH) }):Play()
		TweenService:Create(menu, TW_DROPDOWN, {
			Size = UDim2.new(1, -8, 0, menuH),
			BackgroundTransparency = open and 0 or 1,
		}):Play()
		TweenService:Create(menuStroke, TW_FAST, { Transparency = open and 0 or 1 }):Play()
		if elStroke then TweenService:Create(elStroke, TW_FAST, { Color = open and Color3.fromRGB(87, 84, 104) or THEME.BORDER }):Play() end
		TweenService:Create(arrow, TW_DROPDOWN, {
			Rotation = open and 0 or 180,
			ImageColor3 = open and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(178, 170, 210),
			ImageTransparency = open and 0 or 0.08,
		}):Play()
		if not open and searchBox then
			searchBox.Text = ""
			for _, itm in pairs(itemButtons) do itm.Visible = true end
			noResults.Visible = false
		end
		task.delay(0.03, function() section:_UpdateSize() end)
		task.delay(0.25, function() section:_UpdateSize() end)
	end

	trigger.MouseButton1Click:Connect(function() setOpen(not open) end)

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = string.lower(searchBox.Text or "")
			local anyVisible = false
			for valueItem, itm in pairs(itemButtons) do
				local match = q == "" or string.find(string.lower(tostring(valueItem)), q, 1, true) ~= nil
				itm.Visible = match
				if match then anyVisible = true end
			end
			noResults.Visible = (not anyVisible) and q ~= ""
			if open then
				local newMenuH = calcMenuHeight()
				TweenService:Create(element, TW_DROPDOWN, { Size = UDim2.new(1, 0, 0, baseH + newMenuH + 16) }):Play()
				TweenService:Create(menu, TW_DROPDOWN, { Size = UDim2.new(1, -8, 0, newMenuH) }):Play()
				task.delay(0.03, function() section:_UpdateSize() end)
				task.delay(0.25, function() section:_UpdateSize() end)
			end
		end)
	end

	refreshVisuals()
	section:_UpdateSize()

	-- Flag registration
	local OptionsRegistry = require(script.Parent.Parent.OptionsRegistry)

	control = {
		Type = "Dropdown",
		Flag = config.Flag,
		Multi = multi,
		Instance = element,
		Value = getValue(),
		_changedListeners = {},
	}

	function control:Set(newValue, silent)
		if multi then
			for k in pairs(selected) do selected[k] = nil end
			if type(newValue) == "table" then
				for _, v in ipairs(newValue) do selected[v] = true end
			elseif newValue ~= nil then
				selected[newValue] = true
			end
		else
			selectedValue = newValue
		end
		refreshVisuals()
		self.Value = getValue()
		if not silent then
			SafeCallback(config.Callback, self.Value)
			for _, fn in ipairs(self._changedListeners) do SafeCallback(fn, self.Value) end
		end
	end
	control.SetValue = control.Set
	function control:Get() return getValue() end
	function control:Open() setOpen(true) end
	function control:Close() setOpen(false) end
	function control:OnChanged(fn)
		if type(fn) == "function" then table.insert(self._changedListeners, fn) end
	end

	--- Refresh the dropdown values list without destroying the element.
	function control:Refresh(newValues)
		-- Clear old items
		for _, itm in pairs(itemButtons) do itm:Destroy() end
		for k in pairs(itemButtons) do itemButtons[k] = nil end
		for k in pairs(itemLabels) do itemLabels[k] = nil end
		for k in pairs(itemChecks) do itemChecks[k] = nil end

		listValues = newValues or {}
		if not multi then
			selectedValue = nil
		else
			for k in pairs(selected) do selected[k] = nil end
		end

		-- Rebuild items
		for idx, valueItem in ipairs(listValues) do
			local item = Create("TextButton", {
				Name = "Item_" .. tostring(idx),
				Size = UDim2.new(1, 0, 0, itemH),
				BackgroundColor3 = THEME.BG_SEARCH,
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 14,
				LayoutOrder = idx,
				Parent = itemsFrame,
			})
			Corner(8, item)
			Padding(item, 0, 12, 0, 12)

			if multi then
				local logoFrame = Create("Frame", {
					Size = UDim2.new(0, 26, 0, 26),
					Position = UDim2.new(0, -5, 0.5, -12),
					BackgroundTransparency = 1,
					Visible = true,
					ZIndex = 15,
					Parent = item,
				})
				Create("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					Image = LOGO_ASSET,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 16,
					Parent = logoFrame,
				})
				itemChecks[valueItem] = logoFrame
			end

			itemLabels[valueItem] = Create("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(valueItem),
				Font = FONT_REG,
				TextSize = 12,
				TextColor3 = Color3.fromRGB(178, 170, 210),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 15,
				Parent = item,
			})
			Create("UIScale", { Scale = 1, Parent = itemLabels[valueItem] })
			itemButtons[valueItem] = item

			item.MouseEnter:Connect(function()
				if IsForegroundInputBlocked(item) then return end
				local active = multi and selected[valueItem] or ((not multi) and valueItem == selectedValue)
				if not active then
					TweenService:Create(item, TW_FAST, {
						BackgroundTransparency = 0.85,
						BackgroundColor3 = Color3.fromRGB(60, 60, 68),
					}):Play()
					local sc = itemLabels[valueItem]:FindFirstChildOfClass("UIScale")
					if sc then TweenService:Create(sc, TW_FAST, { Scale = 1.04 }):Play() end
				end
			end)
			item.MouseLeave:Connect(function()
				local active = multi and selected[valueItem] or ((not multi) and valueItem == selectedValue)
				if not active and itemLabels[valueItem] then
					local sc = itemLabels[valueItem]:FindFirstChildOfClass("UIScale")
					if sc then TweenService:Create(sc, TW_FAST, { Scale = 1.0 }):Play() end
				end
				refreshVisuals()
			end)
			item.MouseButton1Click:Connect(function()
				if multi then
					selected[valueItem] = not selected[valueItem]
				else
					selectedValue = valueItem
					task.defer(function() setOpen(false) end)
				end
				refreshVisuals()
				local v = getValue()
				if control then control.Value = v end
				SafeCallback(config.Callback, v)
				if control then
					for _, fn in ipairs(control._changedListeners) do SafeCallback(fn, v) end
				end
			end)
		end

		refreshVisuals()
		self.Value = getValue()
		section:_UpdateSize()
	end

	if config.Flag then OptionsRegistry.Register(config.Flag, control) end

	return control
end

return Dropdown
