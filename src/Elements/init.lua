--[[
    Apex UI Library - Section element registry
    Returns a table of element builders. Each builder is a function with the
    signature `Build(section, ...)` that creates the visual instance and
    returns the public element object.
]]

local Elements = {}

Elements.Label    = require(script.Label)
Elements.Button   = require(script.Button)
Elements.Toggle   = require(script.Toggle)
Elements.Slider   = require(script.Slider)
Elements.Dropdown = require(script.Dropdown)
Elements.Input    = require(script.Input)
Elements.Keybind  = require(script.Keybind)

return Elements
