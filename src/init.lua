--[[
    Apex UI Library
    Modular re-implementation of the original ApexL-test.lua single-file build.

    Visual style is preserved exactly: dark Apex window, compact top bar,
    macOS-style traffic-light dots, collapsible sidebar, breadcrumbs,
    animated gradient strokes, rounded section cards and Luna-style controls.

    Quick example:
        local Library = require(path.to.ApexLibrary)
        local window  = Library.new({ Title = "My Dashboard" })
        local page    = window:Page("Home", "lucide:house")
        local section = page:Section("General")
        section:Label("Welcome to your dashboard!")
        section:Toggle("Enable feature", false, function(v) print(v) end)

    Distribution example (loadstring):
        local ui = loadstring(game:HttpGet("URL/Library.lua"))()
        local window = ui.new({ Title = "My Dashboard" })

    Source layout:
        Theme.lua                    palette, fonts, sizes, tween presets
        Constants.lua                hidden-mode defaults
        Util/                        Create, Stroke, Padding, Foreground, Icons,
                                     Player, Callback helpers
        Elements/                    Section element builders (Toggle, Slider, etc.)
        UserSettingsElements/        Compact variants for the UserSettings popup
        Components/Section.lua       Section class + element forwarders
        Components/UserSettingsSection.lua
        Components/Page.lua          Page class with Section spawner
        Components/Window/           Window class split by concern
        Components/Build.lua         Library.new builder (UI tree + wiring)
]]

local Util = require(script.Util)
local Icons = Util.Icons
local Build = require(script.Components.Build)
local OptionsRegistry = require(script.OptionsRegistry)
local SaveManager = require(script.SaveManager)

local Library = {}
Library.__index = Library
Library.Version  = "ApexLibrary_v1.0.0"
Library.IconsType = Icons.DefaultIconsType

-- Central registry for elements that opt in via the `Flag` config field.
Library.Options = OptionsRegistry.Options

-- SaveManager instance (singleton)
Library.SaveManager = SaveManager

--- Register an element control under its flag.
function Library.RegisterFlag(flag, control)
	OptionsRegistry.Register(flag, control)
end

-- =====================================================================
-- Public Library API
-- =====================================================================

function Library.SetIconsType(iconType)
	Icons.SetIconsType(iconType)
	Library.IconsType = Icons.DefaultIconsType
end

function Library.GetIcon(icon, iconType)
	return Icons.GetIcon(icon, iconType or Library.IconsType)
end

function Library.GetIconsModule()
	return Icons.GetModule()
end

function Library.new(config)
	return Build.New(Library, config)
end

return Library
