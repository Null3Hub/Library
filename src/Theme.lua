--[[
    Apex UI Library - Theme module
    Holds the colors, fonts, sizes and tween presets used everywhere.
    Matches the original ApexL-test.lua values 1:1.
]]

local Theme = {}

Theme.THEME = {
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

Theme.FONT_BOLD = Enum.Font.GothamBold
Theme.FONT_SEMI = Enum.Font.GothamSemibold
Theme.FONT_REG  = Enum.Font.Gotham
Theme.FONT_MONO = Enum.Font.Code

Theme.CORNER_SM = 6
Theme.CORNER_MD = 10
Theme.CORNER_XL = 10

Theme.SIDEBAR_EXPANDED  = 188
Theme.SIDEBAR_COLLAPSED = 62
Theme.NEW_TOPBAR_H      = 32
Theme.TOPBAR_H          = 52
Theme.LOGO_ASSET        = "rbxassetid://94586681223401"

Theme.WINDOW_POS  = UDim2.new(0.06, 0, 0.07, 0)
Theme.WINDOW_SIZE = UDim2.new(0.66, 0, 0.86, 0)

Theme.TW_FAST     = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Theme.TW_MED      = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Theme.TW_SIDEBAR  = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Theme.TW_DROPDOWN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

return Theme
