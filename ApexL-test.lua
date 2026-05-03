--[[
	Apex UI Library
	Converted from ApexDashboard_v9_3_6_main_label_spacing_fix.lua into a reusable library.
	Visual style was preserved: dark Apex window, compact top bar, macOS dots,
	collapsible sidebar, breadcrumbs, gradient strokes, rounded section cards and
	Luna-style controls.

	Example:
	local ui = loadstring(game:HttpGet("URL/Library.lua"))()
	local window = ui.new({ Title = "My Dashboard" })
	local page = window:AddPage("Home", "rbxassetid://123456")
	local section = page:AddSection("General")
	section:AddLabel("Welcome to your dashboard!")
	section:AddToggle("Enable feature", false, function(v) print(v) end)
--]]

local Library = {}
Library.__index = Library
Library.Version = "ApexLibrary_v1.0.0"
Library.IconsType = "lucide"

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local THEME = {
	BG_OUTER    = Color3.fromRGB(24, 24, 25),
	BG_WINDOW   = Color3.fromRGB(40, 40, 43),
	BG_SIDEBAR  = Color3.fromRGB(24, 24, 25),
	BG_CARD     = Color3.fromRGB(40, 40, 43),
	BG_HOVER    = Color3.fromRGB(48, 48, 52),
	BG_ACTIVE   = Color3.fromRGB(46, 42, 54),
	BG_SEARCH   = Color3.fromRGB(31, 31, 34),
	BG_TABSEL   = Color3.fromRGB(46, 42, 54),
	BG_BUTTON   = Color3.fromRGB(35, 35, 38),
	BG_TOPBAR   = Color3.fromRGB(20, 20, 21),

	TEXT_PRIMARY   = Color3.fromRGB(245, 245, 247),
	TEXT_SECONDARY = Color3.fromRGB(180, 180, 186),
	TEXT_MUTED     = Color3.fromRGB(126, 126, 127),
	TEXT_ACCENT    = Color3.fromRGB(255, 255, 255),

	ACCENT_BLUE  = Color3.fromRGB(89, 29, 169),
	ACCENT_GREEN = Color3.fromRGB(52, 211, 153),
	BORDER       = Color3.fromRGB(64, 64, 68),
	BORDER_LIGHT = Color3.fromRGB(126, 126, 127),

	STROKE_PURPLE = Color3.fromRGB(89, 29, 169),
	STROKE_MID    = Color3.fromRGB(126, 126, 127),
	STROKE_LIGHT  = Color3.fromRGB(245, 245, 247),

	DOT_RED    = Color3.fromRGB(255, 95, 86),
	DOT_YELLOW = Color3.fromRGB(255, 189, 46),
	DOT_GREEN  = Color3.fromRGB(39, 201, 63),
	DOT_GRAY   = Color3.fromRGB(80, 80, 84),
}

local FONT_BOLD = Enum.Font.GothamBold
local FONT_SEMI = Enum.Font.GothamSemibold
local FONT_REG  = Enum.Font.Gotham
local FONT_MONO = Enum.Font.Code

local CORNER_SM = 6
local CORNER_MD = 10
local CORNER_XL = 10

local SIDEBAR_EXPANDED  = 188
local SIDEBAR_COLLAPSED = 62
local NEW_TOPBAR_H      = 32
local TOPBAR_H          = 52
local LOGO_ASSET        = "rbxassetid://76038193154224"

local WINDOW_POS  = UDim2.new(0.06, 0, 0.07, 0)
local WINDOW_SIZE = UDim2.new(0.66, 0, 0.86, 0)

local TW_FAST     = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_MED      = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_SIDEBAR  = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_DROPDOWN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function Create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function Corner(radius, parent)
	local c = Create("UICorner", { CornerRadius = UDim.new(0, radius) })
	if parent then c.Parent = parent end
	return c
end

local function Stroke(parent, color, thickness)
	local s = Create("UIStroke", {
		Color = color or THEME.BORDER,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
	if parent then s.Parent = parent end
	return s
end

local function Padding(parent, t, r, b, l)
	local p = Create("UIPadding", {
		PaddingTop    = UDim.new(0, t or 0),
		PaddingRight  = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft   = UDim.new(0, l or 0),
	})
	if parent then p.Parent = parent end
	return p
end

local function ListLayout(parent, fillDir, hAlign, vAlign, spacing)
	local l = Create("UIListLayout", {
		FillDirection       = fillDir or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Padding             = UDim.new(0, spacing or 0),
	})
	if parent then l.Parent = parent end
	return l
end

local function HoverColor(frame, normalColor, hoverColor, tweenInfo)
	if not frame or not frame:IsA("GuiObject") then
		return
	end

	tweenInfo = tweenInfo or TW_FAST
	normalColor = normalColor or frame.BackgroundColor3
	hoverColor = hoverColor or THEME.BG_HOVER

	frame.MouseEnter:Connect(function()
		if frame.Parent then
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

local function GradientStrokeFrame(parent, name, radius, thickness, zIndex)
	local frame = Create("Frame", {
		Name = name or "GradientStrokeFrame",
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Active = false,
		Selectable = false,
		ZIndex = zIndex or 100,
		Parent = parent,
	})
	Corner(radius, frame)

	local stroke = Create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 0.02,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = frame,
	})

	local gradient = Create("UIGradient", {
		Name = "AnimatedStrokeGradient",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, THEME.STROKE_PURPLE),
			ColorSequenceKeypoint.new(0.22, Color3.fromRGB(126, 76, 214)),
			ColorSequenceKeypoint.new(0.48, THEME.STROKE_LIGHT),
			ColorSequenceKeypoint.new(0.72, THEME.STROKE_MID),
			ColorSequenceKeypoint.new(1.00, THEME.STROKE_PURPLE),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.00),
			NumberSequenceKeypoint.new(0.14, 0.28),
			NumberSequenceKeypoint.new(0.50, 0.02),
			NumberSequenceKeypoint.new(0.86, 0.28),
			NumberSequenceKeypoint.new(1.00, 1.00),
		}),
		Parent = stroke,
	})
	TweenService:Create(gradient, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), { Rotation = 450 }):Play()
	return frame, stroke, gradient
end

local function SafeCallback(callback, ...)
	if type(callback) ~= "function" then return end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[ApexLibrary] Callback error:", err)
	end
end

-- Native icon resolver powered by Footagesus/Icons Main-v2.
-- Supports raw image ids and named icon keys:
--   Icone = "rbxassetid://123"
--   Icone = "house"
--   Icone = "lucide:house"
--   Icone = "geist:accessibility-unread"
--   Icone = "sfsymbols:HouseFill"
local ICONS_V2_URL = "https://raw.githubusercontent.com/Footagesus/Icons/58f2a4994f75d035472bdeb0ca276bd5bafc3282/Main-v2.lua"
local IconsV2
local IconsV2Loaded = false
local DefaultIconsType = "lucide"

local function IsImageSource(value)
	if type(value) ~= "string" then return false end
	return string.find(value, "rbxassetid://", 1, true) ~= nil
		or string.find(value, "rbxthumb://", 1, true) ~= nil
		or string.find(value, "http://", 1, true) ~= nil
		or string.find(value, "https://", 1, true) ~= nil
end

local function LoadIconsV2()
	if IconsV2Loaded then return IconsV2 end
	IconsV2Loaded = true

	local ok, result = pcall(function()
		local source
		if game.HttpGetAsync then
			source = game:HttpGetAsync(ICONS_V2_URL)
		else
			source = game:HttpGet(ICONS_V2_URL)
		end
		local loader = loadstring(source)
		return loader and loader()
	end)

	if ok and type(result) == "table" then
		IconsV2 = result
		if type(IconsV2.SetIconsType) == "function" then
			pcall(IconsV2.SetIconsType, DefaultIconsType)
		end
	else
		warn("[ApexLibrary] Failed to load IconsV2:", result)
	end

	return IconsV2
end

local function ResolveIcon(icon, iconType)
	if icon == nil then
		return "⊞", false
	end

	local raw = tostring(icon)
	if raw == "" then
		return "⊞", false
	end

	if IsImageSource(raw) then
		return raw, true
	end

	local icons = LoadIconsV2()
	if icons and type(icons.GetIcon) == "function" then
		local query = raw
		if iconType and iconType ~= "" and not string.find(raw, ":", 1, true) then
			query = tostring(iconType) .. ":" .. raw
		end

		local ok, image = pcall(icons.GetIcon, query)
		if ok and type(image) == "string" and image ~= "" then
			return image, true
		end
	end

	return raw, false
end


local function GetLocalPlayerHeadshot()
	local placeholder = "rbxassetid://0"
	if not LocalPlayer then
		return placeholder
	end

	local ok, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if ok and type(thumbnail) == "string" and thumbnail ~= "" then
		return thumbnail
	end

	return placeholder
end

local function GetKeyCode(value, fallback)
	fallback = fallback or Enum.KeyCode.LeftAlt
	if typeof(value) == "EnumItem" then return value end
	if type(value) == "string" and Enum.KeyCode[value] then return Enum.KeyCode[value] end
	return fallback
end

local Section = {}
Section.__index = Section

local Page = {}
Page.__index = Page

local Window = {}
Window.__index = Window

function Library.SetIconsType(iconType)
	DefaultIconsType = tostring(iconType or "lucide")
	Library.IconsType = DefaultIconsType
	local icons = LoadIconsV2()
	if icons and type(icons.SetIconsType) == "function" then
		pcall(icons.SetIconsType, DefaultIconsType)
	end
end

function Library.GetIcon(icon, iconType)
	local image = ResolveIcon(icon, iconType or Library.IconsType)
	return image
end

function Library.GetIconsModule()
	return LoadIconsV2()
end

function Section:_UpdateSize()
	local h = self.ElementsLayout.AbsoluteContentSize.Y
	self.ElementsList.Size = UDim2.new(1, 0, 0, h)
	self.ElementsClip.Size = UDim2.new(1, -36, 0, h)
	self.Container.Size = UDim2.new(1, 0, 0, 52 + h + 18)
	if self.Page and self.Page.UpdateCanvas then
		self.Page:UpdateCanvas()
	end
end

function Section:_BaseElement(name, height)
	local element = Create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, height or 38),
		BackgroundColor3 = THEME.BG_BUTTON,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 10,
		Parent = self.ElementsList,
	})
	Corner(9, element)
	local elStroke = Stroke(element, THEME.BORDER, 1)
	element.MouseEnter:Connect(function()
		TweenService:Create(elStroke, TW_FAST, { Color = Color3.fromRGB(87, 84, 104) }):Play()
		TweenService:Create(element, TW_FAST, { BackgroundTransparency = 0.04 }):Play()
	end)
	element.MouseLeave:Connect(function()
		TweenService:Create(elStroke, TW_FAST, { Color = THEME.BORDER }):Play()
		TweenService:Create(element, TW_FAST, { BackgroundTransparency = 0.12 }):Play()
	end)
	return element, elStroke
end

function Section:_Title(parent, title, desc)
	Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -118, 0, desc and 15 or 20),
		Position = UDim2.new(0, 12, 0, desc and 6 or 9),
		BackgroundTransparency = 1,
		Text = tostring(title or "Element"),
		Font = FONT_SEMI,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(235, 231, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = parent.ZIndex + 1,
		Parent = parent,
	})
	if desc then
		Create("TextLabel", {
			Name = "Desc",
			Size = UDim2.new(1, -118, 0, 13),
			Position = UDim2.new(0, 12, 0, 22),
			BackgroundTransparency = 1,
			Text = tostring(desc),
			Font = FONT_REG,
			TextSize = 10,
			TextColor3 = Color3.fromRGB(145, 139, 170),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = parent.ZIndex + 1,
			Parent = parent,
		})
	end
end

function Section:AddLabel(text, desc)
	local element = self:_BaseElement("ApexLabel", desc and 44 or 38)
	self:_Title(element, text or "Label", desc)

	local badge = Create("Frame", {
		Name = "InfoBadge",
		Size = UDim2.new(0, 64, 0, 22),
		Position = UDim2.new(1, -76, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(44, 38, 68),
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = element,
	})
	Corner(7, badge)
	Stroke(badge, Color3.fromRGB(82, 74, 118), 1)
	Create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "Apex",
		Font = FONT_SEMI,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(198, 189, 255),
		ZIndex = 12,
		Parent = badge,
	})
	self:_UpdateSize()
	return { Instance = element, Set = function(_, value) local t = element:FindFirstChild("Title"); if t then t.Text = tostring(value) end end }
end

function Section:AddButton(text, callback, desc)
	local element, buttonStroke = self:_BaseElement("ApexButton", desc and 44 or 38)
	self:_Title(element, text or "Button", desc)

	local interact = Create("TextButton", {
		Name = "Interact",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
		Parent = element,
	})
	local icon = Create("TextLabel", {
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -36, 0.5, -12),
		BackgroundTransparency = 1,
		Text = "↳",
		Font = FONT_BOLD,
		TextSize = 17,
		TextColor3 = Color3.fromRGB(178, 170, 210),
		ZIndex = 12,
		Parent = element,
	})
	interact.MouseButton1Click:Connect(function()
		TweenService:Create(buttonStroke, TW_FAST, { Color = Color3.fromRGB(136, 131, 163) }):Play()
		TweenService:Create(icon, TW_FAST, { TextColor3 = Color3.fromRGB(236, 232, 255) }):Play()
		task.delay(0.18, function()
			if buttonStroke.Parent then
				TweenService:Create(buttonStroke, TW_FAST, { Color = THEME.BORDER }):Play()
				TweenService:Create(icon, TW_FAST, { TextColor3 = Color3.fromRGB(178, 170, 210) }):Play()
			end
		end)
		SafeCallback(callback)
	end)
	self:_UpdateSize()
	return { Instance = element, SetText = function(_, value) local t = element:FindFirstChild("Title"); if t then t.Text = tostring(value) end end }
end

function Section:AddToggle(text, default, callback, desc)
	local element = self:_BaseElement("ApexToggle", desc and 44 or 38)
	self:_Title(element, text or "Toggle", desc)
	local value = default and true or false

	local track = Create("Frame", {
		Name = "ToggleTrack",
		Size = UDim2.new(0, 42, 0, 22),
		Position = UDim2.new(1, -54, 0.5, -11),
		BackgroundColor3 = value and Color3.fromRGB(82, 74, 118) or Color3.fromRGB(42, 39, 50),
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = element,
	})
	Corner(11, track)
	Stroke(track, THEME.BORDER, 1)
	local knob = Create("Frame", {
		Name = "ToggleKnob",
		Size = UDim2.new(0, 16, 0, 16),
		Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3 = value and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(145, 139, 170),
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = track,
	})
	Corner(8, knob)
	local button = Create("TextButton", {
		Name = "Interact",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
		Parent = element,
	})

	local object = {}
	function object:Set(newValue, silent)
		value = newValue and true or false
		TweenService:Create(track, TW_MED, {
			BackgroundColor3 = value and Color3.fromRGB(82, 74, 118) or Color3.fromRGB(42, 39, 50),
		}):Play()
		TweenService:Create(knob, TW_MED, {
			Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
			BackgroundColor3 = value and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(145, 139, 170),
		}):Play()
		if not silent then SafeCallback(callback, value) end
	end
	function object:Get()
		return value
	end
	object.Instance = element

	button.MouseButton1Click:Connect(function()
		object:Set(not value)
	end)
	self:_UpdateSize()
	return object
end

function Section:AddSlider(text, min, max, default, callback, desc)
	min = tonumber(min) or 0
	max = tonumber(max) or 100
	if min > max then min, max = max, min end
	local value = math.clamp(tonumber(default) or min, min, max)
	local range = math.max(max - min, 1)

	local element = self:_BaseElement("ApexSlider", desc and 54 or 52)
	self:_Title(element, text or "Slider", desc)
	local valueLabel = Create("TextLabel", {
		Name = "Value",
		Size = UDim2.new(0, 40, 0, 18),
		Position = UDim2.new(1, -52, 0, 7),
		BackgroundTransparency = 1,
		Text = tostring(value),
		Font = FONT_SEMI,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(236, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 11,
		Parent = element,
	})
	local bar = Create("Frame", {
		Name = "Bar",
		Size = UDim2.new(1, -24, 0, 5),
		Position = UDim2.new(0, 12, 1, -13),
		BackgroundColor3 = THEME.BG_ACTIVE,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = element,
	})
	Corner(3, bar)
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.new((value - min) / range, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(136, 131, 163),
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = bar,
	})
	Corner(3, fill)
	Create("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new(Color3.fromRGB(92, 84, 130), Color3.fromRGB(198, 189, 255)),
		Parent = fill,
	})

	local sliding = false
	local object = {}
	function object:Set(newValue, silent)
		value = math.clamp(tonumber(newValue) or min, min, max)
		local alpha = (value - min) / range
		valueLabel.Text = tostring(value)
		TweenService:Create(fill, TW_FAST, { Size = UDim2.new(alpha, 0, 1, 0) }):Play()
		if not silent then SafeCallback(callback, value) end
	end
	function object:Get()
		return value
	end
	object.Instance = element

	local function updateFromX(x)
		local width = math.max(bar.AbsoluteSize.X, 1)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
		local newValue = math.floor((min + range * alpha) + 0.5)
		object:Set(newValue)
	end

	element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	self:_UpdateSize()
	return object
end

function Section:AddDropdown(configOrTitle, values, default, callback)
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

	local element = self:_BaseElement(config.Name or "ApexDropdown", baseH)
	element.ClipsDescendants = true
	local elStroke = element:FindFirstChildOfClass("UIStroke")
	self:_Title(element, config.Title or "Dropdown", config.Description)

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
	local arrow = Create("TextLabel", {
		Size = UDim2.new(0, 20, 0, 22),
		Position = UDim2.new(1, -34, 0, 10),
		BackgroundTransparency = 1,
		Text = "⌄",
		Font = FONT_BOLD,
		TextSize = 17,
		TextColor3 = Color3.fromRGB(178, 170, 210),
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
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 50, 56)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 120, 132)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(155, 155, 168)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(120, 120, 132)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(50, 50, 56)),
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
		Create("TextLabel", {
			Size = UDim2.new(0, 14, 0, 14),
			BackgroundTransparency = 1,
			Text = "⌕",
			Font = FONT_REG,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(95, 90, 112),
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
				Position = UDim2.new(0, 0, 0.5, -13),
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
			SafeCallback(config.Callback, getValue())
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
			Rotation = open and 180 or 0,
			TextColor3 = open and Color3.fromRGB(236, 232, 255) or Color3.fromRGB(178, 170, 210),
		}):Play()
		if not open and searchBox then
			searchBox.Text = ""
			for _, itm in pairs(itemButtons) do itm.Visible = true end
			noResults.Visible = false
		end
		task.delay(0.03, function() self:_UpdateSize() end)
		task.delay(0.25, function() self:_UpdateSize() end)
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
				task.delay(0.03, function() self:_UpdateSize() end)
				task.delay(0.25, function() self:_UpdateSize() end)
			end
		end)
	end

	refreshVisuals()
	self:_UpdateSize()
	return {
		Instance = element,
		Set = function(_, newValue, silent)
			if multi then
				for k in pairs(selected) do selected[k] = nil end
				if type(newValue) == "table" then
					for _, v in ipairs(newValue) do selected[v] = true end
				else
					selected[newValue] = true
				end
			else
				selectedValue = newValue
			end
			refreshVisuals()
			if not silent then SafeCallback(config.Callback, getValue()) end
		end,
		Get = getValue,
		Open = function() setOpen(true) end,
		Close = function() setOpen(false) end,
	}
end

function Section:AddInput(text, default, callback, desc)
	local element = self:_BaseElement("ApexInput", desc and 46 or 42)
	self:_Title(element, text or "Input", desc)
	local holder = Create("Frame", {
		Name = "InputHolder",
		Size = UDim2.new(0, 142, 0, 26),
		Position = UDim2.new(1, -154, 0.5, -13),
		BackgroundColor3 = THEME.BG_SEARCH,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 11,
		Parent = element,
	})
	Corner(7, holder)
	Stroke(holder, THEME.BORDER, 1)
	local box = Create("TextBox", {
		Name = "InputBox",
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(default or ""),
		PlaceholderText = "Type here...",
		PlaceholderColor3 = Color3.fromRGB(95, 90, 112),
		Font = FONT_REG,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(236, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 12,
		Parent = holder,
	})
	local object = {}
	function object:Set(value, silent)
		box.Text = tostring(value or "")
		if not silent then SafeCallback(callback, box.Text) end
	end
	function object:Get() return box.Text end
	object.Instance = element
	box.FocusLost:Connect(function() SafeCallback(callback, box.Text) end)
	self:_UpdateSize()
	return object
end

function Section:AddKeybind(text, default, callback, desc)
	local element = self:_BaseElement("ApexKeybind", desc and 44 or 38)
	self:_Title(element, text or "Keybind", desc)
	local current = GetKeyCode(default, Enum.KeyCode.LeftAlt)
	local listening = false
	local button = Create("TextButton", {
		Name = "BindButton",
		Size = UDim2.new(0, 74, 0, 24),
		Position = UDim2.new(1, -86, 0.5, -12),
		BackgroundColor3 = THEME.BG_SEARCH,
		BorderSizePixel = 0,
		Text = current.Name,
		Font = FONT_SEMI,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(178, 170, 210),
		AutoButtonColor = false,
		ZIndex = 12,
		Parent = element,
	})
	Corner(7, button)
	Stroke(button, THEME.BORDER, 1)
	button.MouseButton1Click:Connect(function()
		listening = true
		button.Text = "..."
	end)
	local conn
	conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			current = input.KeyCode
			button.Text = current.Name
			listening = false
			SafeCallback(callback, current)
		end
	end)
	self:_UpdateSize()
	return {
		Instance = element,
		Get = function() return current end,
		Set = function(_, keyCode, silent)
			current = GetKeyCode(keyCode, current)
			button.Text = current.Name
			if not silent then SafeCallback(callback, current) end
		end,
		Listening = function() return listening end,
		Disconnect = function() if conn then conn:Disconnect() end end,
	}
end

function Page:UpdateCanvas()
	-- Only update this page scroll canvas.
	-- Do NOT call Window:UpdateContentCanvas() from here, because Window:UpdateContentCanvas()
	-- also updates the current page and that creates Page -> Window -> Page recursion.
	if self._UpdatingCanvas then return end
	self._UpdatingCanvas = true

	if self.Scroll and self.Layout and self.Padding then
		local contentHeight = self.Layout.AbsoluteContentSize.Y + self.Padding.PaddingTop.Offset + self.Padding.PaddingBottom.Offset
		self.Scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	end

	self._UpdatingCanvas = false
end

function Page:AddSection(name, subtitle)
	local sectionFrame = Create("Frame", {
		Name = "Section_" .. tostring(name or "Section"),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.BG_SIDEBAR,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 8,
		LayoutOrder = #self.Sections + 1,
		Parent = self.Scroll,
	})
	Corner(CORNER_MD, sectionFrame)
	local sectionStroke = Create("UIStroke", {
		Color = Color3.fromRGB(142, 142, 150),
		Transparency = 0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = sectionFrame,
	})
	Create("UIGradient", {
		Name = "SectionStrokeFade",
		Rotation = 90,
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
	Padding(header, 0, 16, 0, 16)
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

	local section = setmetatable({
		Page = self,
		Container = sectionFrame,
		Header = header,
		ElementsClip = elementsClip,
		ElementsList = elementsList,
		ElementsLayout = elementsLayout,
	}, Section)
	table.insert(self.Sections, section)
	elementsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		section:_UpdateSize()
	end)
	task.defer(function() section:_UpdateSize() end)
	return section
end

function Window:_UpdateBreadcrumb()
	if self.BreadcrumbTabLabel then self.BreadcrumbTabLabel.Text = self.CurrentTabName or "Dashboard" end
	if self.BreadcrumbSectionLabel then self.BreadcrumbSectionLabel.Text = self.CurrentSectionName or "Section" end
	if self.PageTitle then self.PageTitle.Text = self.CurrentTabName or self.Title end
end

function Window:_SetActivePage(page)
	if not page or self.CurrentPage == page then return end
	self.CurrentPage = page
	self.CurrentTabName = page.Name
	self.CurrentSectionName = page.SectionName or "Section"
	for _, p in ipairs(self.Pages) do
		local selected = p == page
		p.Viewport.Visible = selected
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

function Window:_ReflowNav(animate)
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

function Window:SetSidebarExpanded(expanded)
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

function Window:UpdateContentCanvas()
	-- Safe public refresh helper.
	-- This performs the same canvas calculation directly instead of calling
	-- Page:UpdateCanvas(), preventing recursive stack overflow.
	local page = self.CurrentPage
	if not page or not page.Scroll or not page.Layout or not page.Padding then return end
	if page._UpdatingCanvas then return end

	page._UpdatingCanvas = true
	local contentHeight = page.Layout.AbsoluteContentSize.Y + page.Padding.PaddingTop.Offset + page.Padding.PaddingBottom.Offset
	page.Scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	page._UpdatingCanvas = false
end

function Window:AddPageSection(args)
	-- Optional sidebar label shown only when the sidebar is expanded.
	-- Usage:
	--   Window:AddPageSection({ Name = "MAIN" })
	--   Window:AddPageSection("MAIN")
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

function Window:AddSideBarDivider()
	-- Optional sidebar divider. It is full-width in expanded mode and
	-- becomes a compact centered divider in closed mode.
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


Window.AddSidebarDivider = Window.AddSideBarDivider
Window.AddSidebarSectionDivider = Window.AddSideBarDivider

function Window:AddPage(name, icon)
	-- Old API is still supported:
	--   Window:AddPage("Home", "rbxassetid://...")
	-- New table API:
	--   Window:AddPage({ Name = "Home", Icone = "house" })
	-- Native IconsV2 support:
	--   Icone = "house"
	--   Icone = "lucide:house"
	--   Icone = "geist:accessibility-unread"
	--   Icone = "solar:Home2Bold"
	--   Icone = "sfsymbols:HouseFill"
	-- Also accepts Icon and Icone aliases.
	local pageArgs = type(name) == "table" and name or nil
	local pageName = pageArgs and (pageArgs.Name or pageArgs.Title or pageArgs.name or pageArgs.title) or name
	local pageIcon = pageArgs and (pageArgs.Icon or pageArgs.Icone or pageArgs.IconId or pageArgs.Image or pageArgs.icon or pageArgs.icone or pageArgs.image) or icon
	local pageIconType = pageArgs and (pageArgs.IconType or pageArgs.IconsType or pageArgs.Type or pageArgs.iconType or pageArgs.iconsType or pageArgs.type) or nil
	local pageIconColor = pageArgs and (pageArgs.IconColor or pageArgs.Color or pageArgs.iconColor or pageArgs.color) or nil

	pageName = tostring(pageName or "Page")
	local resolvedIcon, iconIsImage = ResolveIcon(pageIcon, pageIconType or self.IconsType or Library.IconsType)
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
	local layout = ListLayout(scroll, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 8)

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

	navButton.MouseButton1Click:Connect(function()
		self:_SetActivePage(page)
	end)
	navButton.MouseEnter:Connect(function()
		if self.CurrentPage ~= page then
			TweenService:Create(navButton, TW_FAST, { BackgroundColor3 = THEME.BG_HOVER, BackgroundTransparency = 0 }):Play()
		end
	end)
	navButton.MouseLeave:Connect(function()
		if self.CurrentPage ~= page then
			TweenService:Create(navButton, TW_FAST, { BackgroundTransparency = 1 }):Play()
		end
	end)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page:UpdateCanvas() end)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() page:UpdateCanvas() end)
	table.insert(self.Pages, page)
	table.insert(self.SidebarItems, { Type = "Page", Page = page })
	self:_ReflowNav()
	if not self.CurrentPage then self:_SetActivePage(page) end
	task.defer(function() page:UpdateCanvas() end)
	return page
end

function Window:OnDestroy(callback)
	if type(callback) == "function" then
		table.insert(self.DestroyCallbacks, callback)
	end
	return self
end

function Window:OnMinimize(callback)
	if type(callback) == "function" then
		table.insert(self.MinimizeCallbacks, callback)
	end
	return self
end

function Window:_FireDestroyCallbacks()
	if self._DestroyCallbacksFired then return end
	self._DestroyCallbacksFired = true
	for _, callback in ipairs(self.DestroyCallbacks or {}) do
		task.spawn(function()
			pcall(callback, self)
		end)
	end
end

function Window:_FireMinimizeCallbacks(state)
	for _, callback in ipairs(self.MinimizeCallbacks or {}) do
		task.spawn(function()
			pcall(callback, state, self)
		end)
	end
end

function Window:SetNotificationsEnabled(state)
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

function Window:ToggleNotifications()
	return self:SetNotificationsEnabled(not self.NotificationsEnabled)
end

function Window:SetUserSettingsVisible(opened, instant)
	if self.Destroyed then return end
	local settings = self.UserSettings
	local scale = self.UserSettingsScale
	local stroke = self.UserSettingsStroke
	if not settings or not settings.Parent or not scale then return end

	opened = opened == true
	if self.UserSettingsOpened == opened and not instant then
		return
	end

	self.UserSettingsOpened = opened
	self._UserSettingsTweenToken = (self._UserSettingsTweenToken or 0) + 1
	local token = self._UserSettingsTweenToken
	local targetTransparency = self.UserSettingsBackgroundTransparency or 0.5
	local targetStrokeTransparency = self.UserSettingsStrokeTransparency or 0.18
	local basePosition = self.UserSettingsBasePosition or settings.Position

	if opened then
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
			end
		end)
	end
end

function Window:ToggleUserSettings()
	self:SetUserSettingsVisible(not self.UserSettingsOpened)
end


function Window:Minimize()
	self:SetVisible(false)
end

function Window:Destroy()
	if self.Destroyed then return end
	self:SetUserSettingsVisible(false, true)
	self.Destroyed = true
	self:_FireDestroyCallbacks()
	for _, conn in ipairs(self.Connections or {}) do
		pcall(function() conn:Disconnect() end)
	end
	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

function Window:SetVisible(state)
	if self.Destroyed or not self.Window then return end
	local nextVisible = state and true or false
	local minimized = self.Visible == true and nextVisible == false
	self.Visible = nextVisible
	self.Window.Visible = self.Visible
	if minimized then
		self:SetUserSettingsVisible(false, true)
		self:_FireMinimizeCallbacks(true)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Library.new(config)
	config = config or {}
	local title = tostring(config.Title or config.Name or "Apex")
	local topBarRightText = tostring(config.TopBarText or "Future text blbablablta test @2026 - Apex L .")
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
	DefaultIconsType = iconsType
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
	GradientStrokeFrame(root, "WindowGradientBorder", CORNER_XL, 2, 120)

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

	local newTopBar = Create("Frame", {
		Name = "NewTopBar",
		Size = UDim2.new(1, 0, 0, NEW_TOPBAR_H),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = THEME.BG_TOPBAR,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 10,
		Parent = root,
	})
	Corner(CORNER_XL, newTopBar)
	Create("Frame", { Name = "NTBBottomLeftFix", Size = UDim2.new(0, CORNER_XL + 6, 0, CORNER_XL + 6), Position = UDim2.new(0, 0, 1, -(CORNER_XL + 6)), BackgroundColor3 = THEME.BG_TOPBAR, BorderSizePixel = 0, ZIndex = 10, Parent = newTopBar })
	Create("Frame", { Name = "NTBBottomRightFix", Size = UDim2.new(0, CORNER_XL + 6, 0, CORNER_XL + 6), Position = UDim2.new(1, -(CORNER_XL + 6), 1, -(CORNER_XL + 6)), BackgroundColor3 = THEME.BG_TOPBAR, BorderSizePixel = 0, ZIndex = 10, Parent = newTopBar })

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
		Size = UDim2.new(0, 360, 1, 0),
		Position = UDim2.new(1, -374, 0, 0),
		BackgroundTransparency = 1,
		Text = topBarRightText,
		Font = FONT_REG,
		TextSize = 11,
		TextColor3 = THEME.TEXT_MUTED,
		TextTransparency = 0.22,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		Parent = newTopBar,
	})

	local sidebar = Create("Frame", { Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_EXPANDED, 1, -NEW_TOPBAR_H), Position = UDim2.new(0, 0, 0, NEW_TOPBAR_H), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 6, Parent = root })
	Corner(CORNER_XL, sidebar)
	Create("Frame", { Name = "SidebarTopLeftFix", Size = UDim2.new(0, CORNER_XL + 6, 0, CORNER_XL + 6), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = sidebar })
	Create("Frame", { Name = "SidebarTopRightFix", Size = UDim2.new(0, CORNER_XL + 6, 0, CORNER_XL + 6), Position = UDim2.new(1, -(CORNER_XL + 6), 0, 0), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = sidebar })
	Create("Frame", { Name = "SidebarBottomRightFix", Size = UDim2.new(0, CORNER_XL + 6, 0, CORNER_XL + 6), Position = UDim2.new(1, -(CORNER_XL + 6), 1, -(CORNER_XL + 6)), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = sidebar })
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

	local sidebarSearch = Create("Frame", { Name = "SidebarSearch", Size = UDim2.new(1, -28, 0, 32), Position = UDim2.new(0, 14, 0, 62), BackgroundColor3 = THEME.BG_SEARCH, BorderSizePixel = 0, ZIndex = 7, Parent = sidebar })
	Corner(8, sidebarSearch)
	local sidebarSearchStroke = Stroke(sidebarSearch, THEME.BORDER, 1)
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
	local searchText = Create("TextLabel", { Name = "SearchText", Size = UDim2.new(1, -46, 1, 0), Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1, Text = "Search anything...", Font = FONT_REG, TextSize = 12, TextColor3 = THEME.TEXT_MUTED, TextTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = sidebarSearch })

	-- Search divider is no longer created from window config.
	-- Use Window:AddSideBarDivider() in runtime to add a divider below search or between pages.


	local contentArea = Create("Frame", { Name = "ContentArea", Size = UDim2.new(1, -SIDEBAR_EXPANDED, 1, -NEW_TOPBAR_H), Position = UDim2.new(0, SIDEBAR_EXPANDED, 0, NEW_TOPBAR_H), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6, Parent = root })
	local topBar = Create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, TOPBAR_H), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 7, Parent = contentArea })
	Corner(CORNER_MD, topBar)
	Create("Frame", { Name = "TopBarTopLeftFix", Size = UDim2.new(0, CORNER_MD + 4, 0, CORNER_MD + 4), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = topBar })
	Create("Frame", { Name = "TopBarBottomLeftFix", Size = UDim2.new(0, CORNER_MD + 4, 0, CORNER_MD + 4), Position = UDim2.new(0, 0, 1, -(CORNER_MD + 4)), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = topBar })
	Create("Frame", { Name = "TopBarTopRightFix", Size = UDim2.new(0, CORNER_MD + 4, 0, CORNER_MD + 4), Position = UDim2.new(1, -(CORNER_MD + 4), 0, 0), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = topBar })
	Create("Frame", { Name = "TopBarBottomRightFix", Size = UDim2.new(0, CORNER_MD + 4, 0, CORNER_MD + 4), Position = UDim2.new(1, -(CORNER_MD + 4), 1, -(CORNER_MD + 4)), BackgroundColor3 = THEME.BG_SIDEBAR, BorderSizePixel = 0, ZIndex = 7, Parent = topBar })

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
	Create("TextLabel", { Name = "RealNick", Size = UDim2.new(0, 0, 0, 13), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name, Font = FONT_REG, TextSize = 8, TextColor3 = THEME.TEXT_MUTED, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 11, LayoutOrder = 1, Parent = userTextStack })
	Create("TextLabel", { Name = "VisualNick", Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = displayNick, Font = FONT_SEMI, TextSize = 13, TextColor3 = THEME.TEXT_PRIMARY, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 11, LayoutOrder = 2, Parent = userTextStack })

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
	-- USER SETTINGS
	-- Syde-inspired profile/settings popup. Parent is the main window so
	-- it follows the current Apex palette and ZIndex stack.
	-- ============================================================
	local userSettingsBasePosition = UDim2.new(1, -18, 0, NEW_TOPBAR_H + TOPBAR_H + 8)
	local userSettings = Create("Frame", {
		Name = "UserSettings",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0, 286, 0, 226),
		Position = userSettingsBasePosition,
		BackgroundColor3 = THEME.BG_CARD,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 140,
		Parent = root,
	})
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
		PaddingTop = UDim.new(0, 13),
		PaddingBottom = UDim.new(0, 13),
		PaddingLeft = UDim.new(0, 13),
		PaddingRight = UDim.new(0, 13),
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

	Create("TextLabel", {
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
		Position = UDim2.new(0, 0, 0, 63),
		BackgroundColor3 = THEME.BORDER,
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		ZIndex = 142,
		Parent = userSettings,
	})

	local userSettingsSection = Create("Frame", {
		Name = "UserSettingsSectionBlock",
		Size = UDim2.new(1, 0, 0, 132),
		Position = UDim2.new(0, 0, 0, 76),
		BackgroundColor3 = THEME.BG_BUTTON,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 142,
		Parent = userSettings,
	})
	Corner(9, userSettingsSection)
	Create("UIStroke", {
		Color = THEME.BORDER,
		Transparency = 0.34,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = userSettingsSection,
	})

	local userSettingsAccent = Create("Frame", {
		Name = "SectionAccent",
		Size = UDim2.new(0, 3, 0, 32),
		Position = UDim2.new(0, 9, 0, 11),
		BackgroundColor3 = THEME.ACCENT_BLUE,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 143,
		Parent = userSettingsSection,
	})
	Corner(3, userSettingsAccent)

	Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -30, 0, 18),
		Position = UDim2.new(0, 21, 0, 10),
		BackgroundTransparency = 1,
		Text = "Account",
		TextColor3 = THEME.TEXT_PRIMARY,
		Font = FONT_SEMI,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 143,
		Parent = userSettingsSection,
	})

	Create("TextLabel", {
		Name = "Sub",
		Size = UDim2.new(1, -30, 0, 18),
		Position = UDim2.new(0, 21, 0, 30),
		BackgroundTransparency = 1,
		Text = "Profile panel ready",
		TextColor3 = THEME.TEXT_MUTED,
		Font = FONT_REG,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 143,
		Parent = userSettingsSection,
	})

	local userSettingsButton = Create("TextButton", {
		Name = "TestButton",
		Size = UDim2.new(0, 78, 0, 26),
		Position = UDim2.new(1, -89, 0, 14),
		BackgroundColor3 = THEME.BG_ACTIVE,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Text = "Apex",
		TextColor3 = THEME.TEXT_SECONDARY,
		Font = FONT_SEMI,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 144,
		Parent = userSettingsSection,
	})
	Corner(8, userSettingsButton)
	Create("UIStroke", {
		Color = THEME.ACCENT_BLUE,
		Transparency = 0.45,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = userSettingsButton,
	})
	HoverColor(userSettingsButton, THEME.BG_ACTIVE, THEME.BG_HOVER)

	local userSettingsDropdown = Create("Frame", {
		Name = "TestDropdown",
		Size = UDim2.new(1, -18, 0, 28),
		Position = UDim2.new(0, 9, 0, 58),
		BackgroundColor3 = THEME.BG_SEARCH,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 143,
		Parent = userSettingsSection,
	})
	Corner(8, userSettingsDropdown)
	Create("UIStroke", {
		Color = THEME.BORDER,
		Transparency = 0.45,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = userSettingsDropdown,
	})
	Create("TextLabel", {
		Name = "DropdownText",
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "Dropdown test",
		TextColor3 = THEME.TEXT_SECONDARY,
		Font = FONT_REG,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 144,
		Parent = userSettingsDropdown,
	})
	Create("ImageLabel", {
		Name = "DropdownIcon",
		Size = UDim2.new(0, 15, 0, 15),
		Position = UDim2.new(1, -24, 0.5, -7),
		BackgroundTransparency = 1,
		Image = ResolveIcon("solar:alt-arrow-down-line-duotone"),
		ImageColor3 = THEME.TEXT_MUTED,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 144,
		Parent = userSettingsDropdown,
	})

	local userSettingsKeybind = Create("Frame", {
		Name = "TestKeybind",
		Size = UDim2.new(1, -18, 0, 28),
		Position = UDim2.new(0, 9, 0, 94),
		BackgroundColor3 = THEME.BG_SEARCH,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 143,
		Parent = userSettingsSection,
	})
	Corner(8, userSettingsKeybind)
	Create("UIStroke", {
		Color = THEME.BORDER,
		Transparency = 0.45,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = userSettingsKeybind,
	})
	Create("TextLabel", {
		Name = "KeybindText",
		Size = UDim2.new(1, -64, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "Keybind test",
		TextColor3 = THEME.TEXT_SECONDARY,
		Font = FONT_REG,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 144,
		Parent = userSettingsKeybind,
	})
	local userSettingsKeyBox = Create("Frame", {
		Name = "KeyBox",
		Size = UDim2.new(0, 46, 0, 18),
		Position = UDim2.new(1, -55, 0.5, -9),
		BackgroundColor3 = THEME.BG_ACTIVE,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 144,
		Parent = userSettingsKeybind,
	})
	Corner(6, userSettingsKeyBox)
	Create("TextLabel", {
		Name = "KeyText",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "LeftAlt",
		TextColor3 = THEME.TEXT_SECONDARY,
		Font = FONT_SEMI,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 145,
		Parent = userSettingsKeyBox,
	})

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
		UserSettingsBackgroundTransparency = 0.5,
		UserSettingsStrokeTransparency = 0.18,
		UserSettingsHitbox = userSettingsHitbox,
		UserSettingsOpened = false,
		UserSettingsBasePosition = userSettingsBasePosition,
		UserSettingsWelcomeLabel = userSettingsWelcome,
		UserSettingsWelcomeText = userSettingsWelcomeText,
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
		ToggleIconBar1 = toggleIconBar1,
		ToggleIconBar2 = toggleIconBar2,
		ToggleIconBlock = toggleIconBlock,
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
	}, Window)

	-- Bind references used by methods
	self.ToggleIconBar1 = toggleIconBar1
	self.ToggleIconBar2 = toggleIconBar2
	self.ToggleIconBlock = toggleIconBlock

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

	-- Window drag
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

	-- Entrance animation preserved from the current file.
	local finalSize = root.Size
	local finalPos = root.Position
	root.Size = UDim2.new(0.1, 0, 0.1, 0)
	root.Position = UDim2.new(0.45, 0, 0.45, 0)
	root.BackgroundTransparency = 1
	task.defer(function()
		TweenService:Create(root, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = finalSize,
			Position = finalPos,
			BackgroundTransparency = 0,
		}):Play()
	end)

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

return Library
