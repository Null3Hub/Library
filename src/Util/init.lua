--[[
    Apex UI Library - Util aggregator
    Bundles every helper module so consumers can just `require(Util)` and
    pick what they need.
]]

local Util = {}

local Create     = require(script.Create)
local Foreground = require(script.Foreground)
local Icons      = require(script.Icons)
local Player     = require(script.Player)
local Callback   = require(script.Callback)

-- Create helpers (named just like the original locals to keep call sites short)
Util.Create              = Create.Instance
Util.Corner              = Create.Corner
Util.Stroke              = Create.Stroke
Util.Padding             = Create.Padding
Util.ListLayout          = Create.ListLayout
Util.GradientStrokeFrame = Create.GradientStrokeFrame

-- Foreground / hover helpers
Util.IsInsideForegroundLayer  = Foreground.IsInsideForegroundLayer
Util.IsForegroundInputBlocked = Foreground.IsForegroundInputBlocked
Util.HoverColor               = Foreground.HoverColor

-- Icons
Util.ResolveIcon = Icons.Resolve
Util.Icons       = Icons

-- Player / input
Util.GetLocalPlayerHeadshot = Player.GetLocalPlayerHeadshot
Util.GetKeyCode             = Player.GetKeyCode

-- Callbacks
Util.SafeCallback = Callback

return Util
