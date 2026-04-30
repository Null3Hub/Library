--[[
    Apex-inspired UI library built on the structural ideas of the JX UI framework.

    This module exposes a simple API for constructing a themed dashboard-like
    interface with pages, sections and a handful of common controls.  It keeps
    the clean separation of concerns found in the JX library while adopting
    the visual language of the Apex Dashboard: a dark card‑based layout with
    soft rounded corners, subtle gradients and animated borders.  Sidebar
    navigation and a compact top bar are included, along with animated
    expansion/collapse of the sidebar.

    Usage example:

    ````lua
    local ui = require(path.to.library)
    local window = ui.new({ Title = "My Dashboard" })
    local page = window:AddPage("Home", "rbxassetid://123456")
    local section = page:AddSection("General")
    section:AddLabel("Welcome to your dashboard!")
    section:AddToggle("Enable feature", false, function(v)
        print("Feature is now", v)
    end)
    ````

    The library automatically creates a ScreenGui and inserts it into the
    player's PlayerGui.  Controls return objects where appropriate so you
    can call `Set`/`Get` on them later.  Refer to the documentation in each
    function for details.
--]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Theme configuration matching the Apex dashboard palette.  You can
-- customise these values up front or at runtime if desired.
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

    ACCENT_BLUE    = Color3.fromRGB(89, 29, 169),
    ACCENT_GREEN   = Color3.fromRGB(52, 211, 153),
    BORDER         = Color3.fromRGB(64, 64, 68),
    BORDER_LIGHT   = Color3.fromRGB(126, 126, 127),

    STROKE_PURPLE  = Color3.fromRGB(89, 29, 169),
    STROKE_MID     = Color3.fromRGB(126, 126, 127),
    STROKE_LIGHT   = Color3.fromRGB(245, 245, 247),

    DOT_RED    = Color3.fromRGB(255, 95, 86),
    DOT_YELLOW = Color3.fromRGB(255, 189, 46),
    DOT_GREEN  = Color3.fromRGB(39, 201, 63),
    DOT_GRAY   = Color3.fromRGB(80, 80, 84),
}

-- Fonts used throughout the UI.  Roblox only permits a handful of font
-- families; these match the Apex look.  You can modify them for a
-- different feel if desired.
local FONT_BOLD = Enum.Font.GothamBold
local FONT_SEMI = Enum.Font.GothamSemibold
local FONT_REG  = Enum.Font.Gotham
local FONT_MONO = Enum.Font.Code

-- Corner radii constants.  Keeping these values consistent ensures
-- uniform rounded corners across the entire UI.  Feel free to tweak.
local CORNER_SM = 6
local CORNER_MD = 10
local CORNER_XL = 10

-- Sidebar sizing constants.  The expanded width matches the Apex
-- dashboard; collapsed width hides labels and shows icons only.
local SIDEBAR_EXPANDED  = 188
local SIDEBAR_COLLAPSED = 62

-- Top bar heights.  A compact top bar sits above the page header.
local NEW_TOPBAR_H = 32
local TOPBAR_H     = 52

-- Default window positioning and sizing as a fraction of the screen.
local WINDOW_POS  = UDim2.new(0.06, 0, 0.07, 0)
local WINDOW_SIZE = UDim2.new(0.66, 0, 0.86, 0)

-- Tween speeds used throughout the library.  Smaller durations
-- produce snappier animations; longer ones feel smoother.
local TW_FAST     = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_MED      = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_SIDEBAR  = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Utility function for instance creation.  Accepts a class name and a
-- table of property assignments.  Returns the created instance.
local function Create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

-- Apply a rounded corner to a GuiObject.  If a parent is provided,
-- the UICorner instance is parented immediately.
local function Corner(radius, parent)
    local c = Create("UICorner", { CornerRadius = UDim.new(0, radius) })
    if parent then c.Parent = parent end
    return c
end

-- Create a gradient stroke frame similar to the Apex card border.  The
-- gradient animates continuously.  Returns the frame, stroke and
-- gradient for further customisation if necessary.
local function GradientStrokeFrame(parent, name, radius, thickness, zIndex)
    local baseThickness = thickness or 2
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
        Thickness = baseThickness,
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

-- Rounds a number to the nearest whole number.  Lua 5.1 does not
-- provide math.round, so we provide a simple implementation here.
local function round(x)
    return (x >= 0) and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

-- Simple hover colour tween for a frame.  When the mouse enters the
-- frame, it smoothly transitions from its normal colour to a hover
-- colour; when the mouse leaves, it returns.  Note that this
-- technique assumes the frame has a BackgroundColor3 property.
local function HoverColor(frame, normalColor, hoverColor)
    frame.MouseEnter:Connect(function()
        TweenService:Create(frame, TW_FAST, { BackgroundColor3 = hoverColor }):Play()
    end)
    frame.MouseLeave:Connect(function()
        TweenService:Create(frame, TW_FAST, { BackgroundColor3 = normalColor }):Play()
    end)
end

-- Helper to create a UIListLayout with sensible defaults.  Sections
-- inside pages use this to lay out their controls vertically.
local function ListLayout(parent, fillDir, hAlign, vAlign, spacing)
    local l = Create("UIListLayout", {
        FillDirection       = fillDir  or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign   or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = vAlign   or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, spacing or 0),
    })
    if parent then l.Parent = parent end
    return l
end

-- Primary library table.  All public API functions are attached to
-- this table.  Use `require` to import and then call `new`.
local Library = {}

-- Create a new window.  The options table may contain Title (string)
-- and other future values.  Returns a window object with methods to
-- add pages and control the sidebar state.
function Library.new(options)
    options = options or {}
    local title = options.Title or "Untitled"

    -- Root ScreenGui.  We create one ScreenGui per library instance.
    local screenGui = Create("ScreenGui", {
        Name = "ApexUI", -- simple name to avoid conflicts
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
    })

    -- Window container.  Clips descendants so the gradient border does not
    -- overflow.  Its size and position scale with the screen size.
    local window = Create("Frame", {
        Name = "Window",
        Size = WINDOW_SIZE,
        Position = WINDOW_POS,
        BackgroundColor3 = THEME.BG_WINDOW,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 5,
        Parent = screenGui,
    })
    Corner(CORNER_XL, window)

    -- Subtle background gradient on the window body.
    Create("UIGradient", {
        Rotation = 270,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.25),
        }),
        Color = ColorSequence.new(THEME.BG_WINDOW, THEME.BG_OUTER),
        Parent = window,
    })

    -- Animated gradient border around the window.
    GradientStrokeFrame(window, "WindowGradientBorder", CORNER_XL, 2, 120)

    -- Sidebar divider line.  This stays at the window level so that
    -- it does not move when the sidebar collapses.  We update its
    -- position whenever the sidebar width changes.
    local sidebarDivider = Create("Frame", {
        Name = "SidebarDivider",
        Size = UDim2.new(0, 1, 1, -NEW_TOPBAR_H),
        Position = UDim2.new(0, SIDEBAR_EXPANDED, 0, NEW_TOPBAR_H),
        BackgroundColor3 = THEME.BORDER,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = window,
    })

    -- Top bar frame.  Contains the sidebar toggle and macOS style dots.
    local topbar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, NEW_TOPBAR_H),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = THEME.BG_TOPBAR,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = window,
    })
    Corner(CORNER_XL, topbar)
    -- Square fixes to hide rounded corners at the bottom edges of the topbar
    local function addTopbarFix(name, posX)
        Create("Frame", {
            Name = name,
            Size = UDim2.new(0, CORNER_XL + 6, 0, CORNER_XL + 6),
            Position = UDim2.new(posX, posX == 0 and 0 or -(CORNER_XL + 6), 1, -(CORNER_XL + 6)),
            BackgroundColor3 = THEME.BG_TOPBAR,
            BorderSizePixel = 0,
            ZIndex = 10,
            Parent = topbar,
        })
    end
    addTopbarFix("TopBarBottomLeftFix", 0)
    addTopbarFix("TopBarBottomRightFix", 1)

    -- Sidebar toggle button (three bars).  Clicking this toggles the
    -- sidebar between collapsed and expanded states.  We animate the
    -- sidebar and divider accordingly.
    local sidebarToggle = Create("TextButton", {
        Name = "SidebarToggle",
        Size = UDim2.new(0, 28, 0, 22),
        Position = UDim2.new(0, 14, 0.5, -11),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = topbar,
    })
    -- Bars for the hamburger icon
    local function newToggleBar(name, offset)
        local bar = Create("Frame", {
            Name = name,
            Size = UDim2.new(0, 3, 0.7, 0),
            Position = UDim2.new(0, offset, 0.15, 0),
            BackgroundColor3 = THEME.TEXT_MUTED,
            BorderSizePixel = 0,
            ZIndex = 13,
            Parent = sidebarToggle,
        })
        Corner(1, bar)
        return bar
    end
    local bar1 = newToggleBar("Bar1", 4)
    local bar2 = newToggleBar("Bar2", 10)
    local block = Create("Frame", {
        Name = "Block",
        Size = UDim2.new(0, 7, 0.7, 0),
        Position = UDim2.new(0, 17, 0.15, 0),
        BackgroundColor3 = THEME.TEXT_MUTED,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = sidebarToggle,
    })
    Corner(1, block)
    -- Hover effect on the bars
    sidebarToggle.MouseEnter:Connect(function()
        TweenService:Create(bar1, TW_FAST, { BackgroundColor3 = THEME.TEXT_PRIMARY }):Play()
        TweenService:Create(bar2, TW_FAST, { BackgroundColor3 = THEME.TEXT_PRIMARY }):Play()
        TweenService:Create(block, TW_FAST, { BackgroundColor3 = THEME.TEXT_PRIMARY }):Play()
    end)
    sidebarToggle.MouseLeave:Connect(function()
        TweenService:Create(bar1, TW_FAST, { BackgroundColor3 = THEME.TEXT_MUTED }):Play()
        TweenService:Create(bar2, TW_FAST, { BackgroundColor3 = THEME.TEXT_MUTED }):Play()
        TweenService:Create(block, TW_FAST, { BackgroundColor3 = THEME.TEXT_MUTED }):Play()
    end)

    -- Container for the macOS style dots on the top right
    local dotHolder = Create("Frame", {
        Name = "DotHolder",
        Size = UDim2.new(0, 68, 1, 0),
        Position = UDim2.new(1, -66, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 12,
        Parent = topbar,
    })
    local layout = ListLayout(dotHolder, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, 8)

    -- Helper for macOS dots with simple hover colour change and symbol display
    local function MacDot(color, symbol)
        local dot = Create("Frame", {
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = THEME.DOT_GRAY,
            BorderSizePixel = 0,
            ZIndex = 13,
            Parent = dotHolder,
        })
        Corner(6, dot)
        local lbl = Create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Font = FONT_BOLD,
            TextSize = 8,
            TextColor3 = Color3.fromRGB(40, 0, 0),
            TextTransparency = 1,
            ZIndex = 14,
            Parent = dot,
        })
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
    MacDot(THEME.DOT_RED,    "×")
    MacDot(THEME.DOT_YELLOW, "−")
    MacDot(THEME.DOT_GREEN,  "+")

    -- Sidebar panel.  Contains navigation buttons for each page and a
    -- search box.  Starts expanded by default.
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SIDEBAR_EXPANDED, 1, -NEW_TOPBAR_H),
        Position = UDim2.new(0, 0, 0, NEW_TOPBAR_H),
        BackgroundColor3 = THEME.BG_SIDEBAR,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 8,
        Parent = window,
    })
    -- Layout for buttons
    local sidebarLayout = ListLayout(sidebar, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 2)
    sidebarLayout.Padding = UDim.new(0, 2)

    -- Search bar at top of sidebar
    local searchBar = Create("TextBox", {
        Name = "SearchBar",
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = THEME.BG_SEARCH,
        BorderSizePixel = 0,
        PlaceholderText = "Search...",
        PlaceholderColor3 = THEME.TEXT_MUTED,
        Text = "",
        TextColor3 = THEME.TEXT_PRIMARY,
        TextSize = 12,
        Font = FONT_REG,
        ZIndex = 9,
        ClearTextOnFocus = false,
        Parent = sidebar,
    })
    Corner(CORNER_SM, searchBar)
    Create("UIPadding", {
        PaddingLeft  = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = searchBar,
    })

    -- Layout container under search bar for page buttons
    local navContainer = Create("Frame", {
        Name = "NavContainer",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
        Parent = sidebar,
    })
    local navLayout = ListLayout(navContainer, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 0)

    -- Container for pages.  Each page occupies the remaining area to the
    -- right of the sidebar.  Pages are stacked and only the selected
    -- page is visible at a time.
    local pageContainer = Create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -SIDEBAR_EXPANDED, 1, -NEW_TOPBAR_H),
        Position = UDim2.new(0, SIDEBAR_EXPANDED, 0, NEW_TOPBAR_H),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 6,
        Parent = window,
    })

    -- State values for the window
    local state = {
        sidebarExpanded = true,
        currentPage = nil,
        pages = {},
    }

    -- Forward declarations
    local PagePrototype
    local SectionPrototype
    local ControlPrototypes = {}

    ---------------------------------------------------------------------
    -- Page management
    ---------------------------------------------------------------------

    -- Switch to the given page by name.  Hides all other pages and
    -- highlights the active navigation button.  Does nothing if the
    -- page does not exist.
    local function showPage(name)
        if state.currentPage == name then return end
        state.currentPage = name
        for n, page in pairs(state.pages) do
            page.container.Visible = (n == name)
            if page.navButton then
                if n == name then
                    TweenService:Create(page.navButton, TW_FAST, { BackgroundColor3 = THEME.BG_ACTIVE }):Play()
                    TweenService:Create(page.navButton.TitleLabel, TW_FAST, { TextColor3 = THEME.TEXT_PRIMARY }):Play()
                else
                    TweenService:Create(page.navButton, TW_FAST, { BackgroundColor3 = THEME.BG_BUTTON }):Play()
                    TweenService:Create(page.navButton.TitleLabel, TW_FAST, { TextColor3 = THEME.TEXT_MUTED }):Play()
                end
            end
        end
    end

    -- Toggle the sidebar collapsed/expanded.  We animate the width of
    -- the sidebar and reposition the page container and divider.
    local function toggleSidebar()
        state.sidebarExpanded = not state.sidebarExpanded
        local targetWidth = state.sidebarExpanded and SIDEBAR_EXPANDED or SIDEBAR_COLLAPSED
        -- Animate sidebar width and reposition page container and divider
        TweenService:Create(sidebar, TW_SIDEBAR, { Size = UDim2.new(0, targetWidth, 1, -NEW_TOPBAR_H) }):Play()
        TweenService:Create(pageContainer, TW_SIDEBAR, { Size = UDim2.new(1, -targetWidth, 1, -NEW_TOPBAR_H), Position = UDim2.new(0, targetWidth, 0, NEW_TOPBAR_H) }):Play()
        TweenService:Create(sidebarDivider, TW_SIDEBAR, { Position = UDim2.new(0, targetWidth, 0, NEW_TOPBAR_H) }):Play()
        -- Hide/show titles on nav buttons depending on state
        for _, page in pairs(state.pages) do
            if page.navButton then
                page.navButton.TitleLabel.Visible = state.sidebarExpanded
            end
        end
        -- Hide search bar when collapsed
        searchBar.Visible = state.sidebarExpanded
    end

    -- Bind the toggle function to the toggle button
    sidebarToggle.MouseButton1Click:Connect(toggleSidebar)

    ---------------------------------------------------------------------
    -- Page prototype
    ---------------------------------------------------------------------

    -- Each page holds a container frame and a navigation button.  It
    -- exposes methods to add sections.  Sections themselves can add
    -- controls.
    PagePrototype = {}
    PagePrototype.__index = PagePrototype

    function PagePrototype:AddSection(name)
        assert(type(name) == "string" and #name > 0, "section name must be a non-empty string")
        local sectionContainer = Create("Frame", {
            Name = name,
            Size = UDim2.new(1, -16, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.BG_CARD,
            BorderSizePixel = 0,
            ClipsDescendants = false,
            ZIndex = 6,
            Parent = self.body,
        })
        Corner(CORNER_MD, sectionContainer)
        GradientStrokeFrame(sectionContainer, "SectionBorder", CORNER_MD, 1, 90)
        -- Padding inside the section card
        Create("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 12),
            PaddingRight  = UDim.new(0, 12),
            Parent = sectionContainer,
        })
        -- Label for the section title
        local titleLabel = Create("TextLabel", {
            Name = "SectionTitle",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = THEME.TEXT_PRIMARY,
            Font = FONT_SEMI,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sectionContainer,
        })
        -- Container for controls underneath the title
        local controlsFrame = Create("Frame", {
            Name = "Controls",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 22),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = sectionContainer,
        })
        local controlsLayout = ListLayout(controlsFrame, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 6)
        controlsLayout.Padding = UDim.new(0, 6)

        -- Section object returned to the user.  Offers methods to add
        -- various control types.
        local section = setmetatable({}, SectionPrototype)
        section.container = sectionContainer
        section.controlsFrame = controlsFrame
        return section
    end

    ---------------------------------------------------------------------
    -- Section prototype
    ---------------------------------------------------------------------

    SectionPrototype = {}
    SectionPrototype.__index = SectionPrototype

    -- Add a simple text label to the section.  Returns no object.
    function SectionPrototype:AddLabel(text)
        assert(type(text) == "string", "label text must be a string")
        local label = Create("TextLabel", {
            Size = UDim2.new(1, -2, 0, 16),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = THEME.TEXT_SECONDARY,
            Font = FONT_REG,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.controlsFrame,
        })
        return label
    end

    -- Add a button.  The callback is invoked when the button is clicked.
    -- Returns a table with a SetText method.
    function SectionPrototype:AddButton(text, callback)
        assert(type(text) == "string", "button text must be a string")
        assert(callback == nil or type(callback) == "function", "callback must be nil or a function")
        local btn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = THEME.BG_BUTTON,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = THEME.TEXT_SECONDARY,
            Font = FONT_SEMI,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = self.controlsFrame,
        })
        Corner(CORNER_SM, btn)
        HoverColor(btn, THEME.BG_BUTTON, THEME.BG_HOVER)
        if callback then
            btn.MouseButton1Click:Connect(function()
                callback()
            end)
        end
        return {
            SetText = function(_, t)
                btn.Text = t
            end,
            Button = btn,
        }
    end

    -- Add a toggle (checkbox).  default is a boolean.  callback
    -- receives the new boolean value.  Returns a table with Set and
    -- Get methods to manipulate its state.
    function SectionPrototype:AddToggle(name, default, callback)
        assert(type(name) == "string", "toggle name must be a string")
        local value = default and true or false
        local container = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = self.controlsFrame,
        })
        local title = Create("TextLabel", {
            Size = UDim2.new(1, -32, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = THEME.TEXT_SECONDARY,
            Font = FONT_REG,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        local box = Create("Frame", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -24, 0.5, -10),
            BackgroundColor3 = THEME.BG_BUTTON,
            BorderSizePixel = 0,
            Parent = container,
        })
        Corner(CORNER_SM, box)
        local checkmark = Create("ImageLabel", {
            Size = UDim2.new(1, -4, 1, -4),
            Position = UDim2.new(0, 2, 0, 2),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031068420", -- checkmark icon
            ImageColor3 = THEME.ACCENT_GREEN,
            ImageTransparency = value and 0 or 1,
            Parent = box,
        })
        HoverColor(box, THEME.BG_BUTTON, THEME.BG_HOVER)
        local function update(val)
            value = val
            TweenService:Create(checkmark, TW_FAST, { ImageTransparency = val and 0 or 1 }):Play()
        end
        box.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                update(not value)
                if callback then
                    callback(value)
                end
            end
        end)
        return {
            Set = function(_, v)
                update(not not v)
            end,
            Get = function()
                return value
            end,
            Container = container,
        }
    end

    -- Add a slider.  min and max define the range.  default is the
    -- initial value.  callback receives new numeric values.  Returns an
    -- object with Set and Get methods and a Value property.
    function SectionPrototype:AddSlider(name, min, max, default, callback)
        assert(type(name) == "string", "slider name must be a string")
        min, max = tonumber(min) or 0, tonumber(max) or 1
        local value = tonumber(default) or min
        if min > max then min, max = max, min end
        if value < min then value = min end
        if value > max then value = max end
        local container = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Parent = self.controlsFrame,
        })
        local title = Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = name .. " (" .. tostring(value) .. ")",
            TextColor3 = THEME.TEXT_SECONDARY,
            Font = FONT_REG,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        -- bar and fill
        local bar = Create("Frame", {
            Size = UDim2.new(1, -32, 0, 6),
            Position = UDim2.new(0, 0, 1, -10),
            BackgroundColor3 = THEME.BORDER,
            BorderSizePixel = 0,
            Parent = container,
        })
        Corner(CORNER_SM, bar)
        local fill = Create("Frame", {
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = THEME.ACCENT_BLUE,
            BorderSizePixel = 0,
            Parent = bar,
        })
        Corner(CORNER_SM, fill)
        -- draggable knob
        local knob = Create("Frame", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new((value - min) / (max - min), -6, 0.5, -3),
            BackgroundColor3 = THEME.ACCENT_BLUE,
            BorderSizePixel = 0,
            Parent = bar,
        })
        Corner(6, knob)
        -- drag logic
        local dragging = false
        local function setValueFromX(x)
            local absPos = bar.AbsolutePosition.X
            local absSize = bar.AbsoluteSize.X
            local rel = math.clamp((x - absPos) / absSize, 0, 1)
            local newVal = min + (max - min) * rel
            newVal = round(newVal)
            value = newVal
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -3)
            title.Text = name .. " (" .. tostring(value) .. ")"
            if callback then callback(value) end
        end
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        knob.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                setValueFromX(input.Position.X)
                dragging = true
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                setValueFromX(input.Position.X)
            end
        end)
        return {
            Set = function(_, v)
                v = tonumber(v) or min
                v = math.clamp(v, min, max)
                setValueFromX(bar.AbsolutePosition.X + (v - min) / (max - min) * bar.AbsoluteSize.X)
            end,
            Get = function()
                return value
            end,
            Container = container,
        }
    end

    -- Add a dropdown selector.  options is a table of strings.  If
    -- multi is true the dropdown allows multiple selections.  default
    -- selects the first value.  callback receives the selected value(s).
    -- Returns an object with Get and Set methods.
    function SectionPrototype:AddDropdown(name, options, default, multi, callback)
        assert(type(name) == "string", "dropdown name must be a string")
        assert(type(options) == "table" and #options > 0, "options must be a non-empty table")
        multi = not not multi
        -- Copy the options to avoid mutating input
        local opts = {}
        for i, v in ipairs(options) do opts[i] = v end
        -- Selected values
        local selected = {}
        if default ~= nil then
            if multi then
                if type(default) == "table" then
                    for _, v in ipairs(default) do selected[v] = true end
                else
                    selected[default] = true
                end
            else
                selected[1] = default
            end
        else
            -- default to first option
            if multi then
                selected[opts[1]] = true
            else
                selected[1] = opts[1]
            end
        end
        -- Dropdown container
        local container = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Parent = self.controlsFrame,
        })
        local label = Create("TextLabel", {
            Size = UDim2.new(1, -22, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = name .. ": " .. (multi and "Multiple" or tostring(selected[1] or "")),
            TextColor3 = THEME.TEXT_SECONDARY,
            Font = FONT_REG,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        local arrow = Create("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -20, 0, 0),
            BackgroundTransparency = 1,
            Text = "▼",
            TextColor3 = THEME.TEXT_MUTED,
            Font = FONT_SEMI,
            TextSize = 14,
            Parent = container,
        })
        -- Dropdown list container, initially hidden
        local listContainer = Create("ScrollingFrame", {
            Size = UDim2.new(1, -2, 0, 0),
            Position = UDim2.new(0, 1, 1, 2),
            BackgroundColor3 = THEME.BG_CARD,
            BorderSizePixel = 0,
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ZIndex = 10,
            Parent = container,
        })
        Corner(CORNER_MD, listContainer)
        GradientStrokeFrame(listContainer, "DropdownBorder", CORNER_MD, 1, 90)
        local listLayout = ListLayout(listContainer, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 0)
        listLayout.Padding = UDim.new(0, 0)
        -- Populate list
        local function rebuildList()
            listContainer:ClearAllChildren()
            listLayout.Parent = listContainer
            for i, opt in ipairs(opts) do
                local item = Create("TextButton", {
                    Size = UDim2.new(1, -8, 0, 24),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundColor3 = THEME.BG_BUTTON,
                    BorderSizePixel = 0,
                    Text = opt,
                    TextColor3 = (multi and selected[opt]) or (selected[1] == opt) and THEME.TEXT_PRIMARY or THEME.TEXT_SECONDARY,
                    Font = FONT_REG,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    Parent = listContainer,
                })
                Corner(CORNER_SM, item)
                HoverColor(item, THEME.BG_BUTTON, THEME.BG_HOVER)
                item.MouseButton1Click:Connect(function()
                    if multi then
                        selected[opt] = not selected[opt]
                    else
                        selected[1] = opt
                        -- Collapse list after selection for single
                        listContainer.Visible = false
                    end
                    -- Update label text
                    if multi then
                        local parts = {}
                        for _, v in ipairs(opts) do
                            if selected[v] then table.insert(parts, v) end
                        end
                        label.Text = name .. ": " .. table.concat(parts, ", ")
                    else
                        label.Text = name .. ": " .. tostring(selected[1] or "")
                    end
                    rebuildList()
                    if callback then
                        if multi then
                            -- Build an array of selected keys
                            local sel = {}
                            for _, v in ipairs(opts) do
                                if selected[v] then table.insert(sel, v) end
                            end
                            callback(sel)
                        else
                            callback(selected[1])
                        end
                    end
                end)
            end
        end
        rebuildList()
        -- Show/hide list when clicking on container
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                listContainer.Visible = not listContainer.Visible
            end
        end)
        return {
            Get = function()
                if multi then
                    local sel = {}
                    for _, v in ipairs(opts) do
                        if selected[v] then table.insert(sel, v) end
                    end
                    return sel
                else
                    return selected[1]
                end
            end,
            Set = function(_, v)
                -- update selection
                if multi then
                    for k in pairs(selected) do selected[k] = false end
                    if type(v) == "table" then
                        for _, val in ipairs(v) do selected[val] = true end
                    else
                        selected[v] = true
                    end
                else
                    selected[1] = v
                end
                -- Update UI
                rebuildList()
                -- Fire callback with new selection
                if callback then
                    if multi then
                        local sel = {}
                        for _, val in ipairs(opts) do
                            if selected[val] then table.insert(sel, val) end
                        end
                        callback(sel)
                    else
                        callback(selected[1])
                    end
                end
            end,
            Container = container,
        }
    end

    -- Add a text input.  default is the initial string.  callback
    -- receives the new string whenever it changes (on focus lost).
    function SectionPrototype:AddInput(name, default, callback)
        assert(type(name) == "string", "input name must be a string")
        local text = default or ""
        local container = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Parent = self.controlsFrame,
        })
        local label = Create("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = THEME.TEXT_SECONDARY,
            Font = FONT_REG,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        local inputBox = Create("TextBox", {
            Size = UDim2.new(0.6, -8, 1, -4),
            Position = UDim2.new(0.4, 8, 0, 2),
            BackgroundColor3 = THEME.BG_BUTTON,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = THEME.TEXT_PRIMARY,
            Font = FONT_REG,
            TextSize = 13,
            ClearTextOnFocus = false,
            Parent = container,
        })
        Corner(CORNER_SM, inputBox)
        HoverColor(inputBox, THEME.BG_BUTTON, THEME.BG_HOVER)
        inputBox.FocusLost:Connect(function(enter)
            text = inputBox.Text
            if callback then callback(text) end
        end)
        return {
            Get = function()
                return text
            end,
            Set = function(_, v)
                text = tostring(v)
                inputBox.Text = text
            end,
            Container = container,
        }
    end

    ---------------------------------------------------------------------
    -- Window methods exposed to the user
    ---------------------------------------------------------------------

    local windowApi = {}

    -- Add a new page to the window.  Each page gets its own button in
    -- the sidebar.  The icon parameter should be an asset id (string).
    function windowApi:AddPage(name, icon)
        assert(type(name) == "string" and #name > 0, "page name must be a non-empty string")
        -- Page container
        local body = Create("Frame", {
            Name = name,
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.None,
            Visible = false,
            Parent = pageContainer,
        })
        -- Layout for sections inside the body
        local bodyLayout = ListLayout(body, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 8)
        bodyLayout.Padding = UDim.new(0, 8)
        -- Page object
        local page = setmetatable({
            name = name,
            container = body,
            body = body,
            navButton = nil,
        }, PagePrototype)
        -- Create navigation button
        local navButton = Create("Frame", {
            Name = name .. "_Nav",
            Size = UDim2.new(1, -16, 0, 28),
            BackgroundColor3 = THEME.BG_BUTTON,
            BorderSizePixel = 0,
            ZIndex = 8,
            Parent = navContainer,
        })
        Corner(CORNER_SM, navButton)
        local iconLabel
        if icon and #icon > 0 then
            iconLabel = Create("ImageLabel", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, state.sidebarExpanded and 8 or (28-20)/2, 0.5, -10),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = THEME.TEXT_SECONDARY,
                ZIndex = 9,
                Parent = navButton,
            })
        end
        local titleLabel = Create("TextLabel", {
            Name = "TitleLabel",
            Size = UDim2.new(1, -28 - (iconLabel and 24 or 0), 1, 0),
            Position = UDim2.new(0, (iconLabel and 24 or 8), 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = THEME.TEXT_MUTED,
            Font = FONT_REG,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = state.sidebarExpanded,
            ZIndex = 9,
            Parent = navButton,
        })
        -- Show page when nav button clicked
        navButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                showPage(name)
            end
        end)
        HoverColor(navButton, THEME.BG_BUTTON, THEME.BG_HOVER)
        page.navButton = navButton
        page.navButton.TitleLabel = titleLabel
        -- Store page in state
        state.pages[name] = page
        -- If this is the first page, show it
        if not state.currentPage then
            showPage(name)
        end
        return page
    end

    -- Expose a method to destroy the window and clean up
    function windowApi:Destroy()
        screenGui:Destroy()
        state.pages = {}
    end

    return windowApi
end

return Library
