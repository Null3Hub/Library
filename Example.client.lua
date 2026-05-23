--[[
    Apex UI Library - Example
    Mirrors the documented usage in src/init.lua header.
    Run this in a script that has access to the modular library at
    ReplicatedStorage.ApexLibrary (or any other path you choose).
]]

local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("ApexLibrary"))

-- Optional: change the global icon pack used when names are passed without prefix
Library.SetIconsType("lucide")

local window = Library.new({
	Title       = "Apex L",
	TopBarText  = "Powered by Apex L .",
	Keybind     = Enum.KeyCode.LeftAlt,
	-- HiddenMode = true,
	-- HiddenName = "Anonymous",
})

window:PageSection({ Name = "MAIN" })

-- Dashboard (player info, server stats, executor, discord)
window:CreateDashboard({
	SupportedExecutors = {"Delta", "Synapse Z", "Wave", "Xeno"},
	DiscordInvite = "noinvitelink",
	Icon = 1,
})

local home = window:Page({ Name = "Home", Icone = "house" })
local settings = window:Page({ Name = "Settings", Icone = "lucide:settings" })

window:SideBarDivider()
window:PageSection({ Name = "EXTRAS" })

local about = window:Page({ Name = "About", Icone = "lucide:info" })

-- ============================================================
-- Home page (elements with Flags for SaveManager)
-- ============================================================
local general = home:Section("General", "Basic controls")  -- Mode 1 (default, full width)
general:Label("Welcome!")
general:Toggle({
	Title = "Enable feature",
	Default = false,
	Flag = "EnableFeature",
	Callback = function(v) print("toggle ->", v) end,
})
general:Slider({
	Title = "Volume",
	Min = 0, Max = 100, Default = 50,
	Flag = "Volume",
	Callback = function(v) print("slider ->", v) end,
})
general:Input({
	Title = "Username",
	Default = "",
	Flag = "Username",
	Callback = function(v) print("input ->", v) end,
})
general:Button("Click me", function() print("button click") end)
general:Keybind({
	Title = "Hotkey",
	Default = Enum.KeyCode.F,
	Flag = "Hotkey",
	Callback = function(k) print("keybind ->", k) end,
})

-- ===== Card sections (Mode 2): two side by side =====
local cardA = home:Section({ Name = "Stats", Subtitle = "Card A", Mode = 2 })
cardA:Label("Players: 12")
cardA:Label("Ping: 38ms")
cardA:Toggle("Online", true, function(v) print("online ->", v) end)

local cardB = home:Section({ Name = "Quick Actions", Subtitle = "Card B", Mode = 2 })
cardB:Button("Refresh", function() print("refresh") end)
cardB:Button("Reset", function() print("reset") end)

local advanced = home:Section("Advanced")
advanced:Dropdown({
	Title = "Theme",
	Values = { "Apex", "Mono", "Solar" },
	Default = "Apex",
	Search = true,
	Flag = "SelectedTheme",
	Callback = function(v) print("dropdown ->", v) end,
})
advanced:Dropdown({
	Title = "Tags",
	Values = { "alpha", "beta", "release", "internal" },
	Default = { "alpha" },
	Multi = true,
	Search = true,
	Flag = "Tags",
	Callback = function(t) print("multi ->", t) end,
})

-- ============================================================
-- User Settings popup (click the avatar in the top right)
-- ============================================================
local profile = window:GetUserSettingsSection()
profile:Configure({ Name = "Account", Description = "Profile panel ready" })
profile:Toggle("Hidden mode", false, function(v) window:SetHiddenMode(v) end)
profile:Keybind("Toggle UI", Enum.KeyCode.LeftAlt, function(k) window.Keybind = k end)
profile:Button("Reload", function()
	if type(window.Notify) == "function" then
		window:Notify("Hello")
	else
		print("[Apex] Reload clicked")
	end
end)

local extras = window:UserSettingsSection({ Name = "Theme", Description = "Visual tweaks" })
extras:Dropdown({
	Title = "Icon pack",
	Values = { "lucide", "solar", "geist", "sfsymbols" },
	Default = "lucide",
	Callback = function(pack) Library.SetIconsType(pack) end,
})

-- ============================================================
-- SaveManager (creates its own page with config controls)
-- ============================================================
Library.SaveManager:SetFolder("ApexExample")
Library.SaveManager:BuildConfigPage(window)
Library.SaveManager:LoadAutoload()
