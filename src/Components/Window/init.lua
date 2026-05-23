--[[
    Apex UI Library - Window class
    Holds runtime state (pages, sidebar items, identity, user settings, etc.)
    and exposes the public API. The instance is built by Build.lua.

    To keep this file readable the body is split into sub-modules under
    Components/Window/ and merged on require.
]]

local Window = {}
Window.__index = Window

-- Mix-in helper: copy every function from `source` into `Window`.
local function mix(source)
	for k, v in pairs(source) do
		if type(v) == "function" then
			Window[k] = v
		end
	end
end

mix(require(script.Sidebar))
mix(require(script.Pages))
mix(require(script.Identity))
mix(require(script.UserSettings))
mix(require(script.Lifecycle))
mix(require(script.Dashboard))
mix(require(script.Search))

-- Aliases preserved for compatibility with the original API.
Window.SidebarDivider = Window.SideBarDivider
Window.SidebarSectionDivider = Window.SideBarDivider

return Window
