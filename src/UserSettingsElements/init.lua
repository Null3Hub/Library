--[[
    Apex UI Library - UserSettings element registry
    Compact variants for the UserSettings popup.
]]

local UserSettingsElements = {}

UserSettingsElements.Label    = require(script.Label)
UserSettingsElements.Button   = require(script.Button)
UserSettingsElements.Toggle   = require(script.Toggle)
UserSettingsElements.Keybind  = require(script.Keybind)
UserSettingsElements.Dropdown = require(script.Dropdown)
UserSettingsElements.Special  = require(script.Special)

return UserSettingsElements
