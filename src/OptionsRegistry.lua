--[[
    Apex UI Library - Options Registry (shared state)
    A simple table that holds all flagged element controls.
    This module has ZERO dependencies so it can be required from anywhere
    without causing circular require chains.
]]

local OptionsRegistry = {}

-- The actual registry table. Key = flag string, Value = control object.
OptionsRegistry.Options = {}

function OptionsRegistry.Register(flag, control)
	if type(flag) ~= "string" or flag == "" or not control then return end
	OptionsRegistry.Options[flag] = control
end

function OptionsRegistry.Unregister(flag, control)
	if type(flag) ~= "string" or flag == "" then return end
	if control == nil or OptionsRegistry.Options[flag] == control then
		OptionsRegistry.Options[flag] = nil
	end
end

function OptionsRegistry.UnregisterUnder(root)
	if not root then return end
	for flag, control in pairs(OptionsRegistry.Options) do
		local instance = control and control.Instance
		if typeof(instance) == "Instance" and instance:IsDescendantOf(root) then
			OptionsRegistry.Unregister(flag, control)
		end
	end
end

return OptionsRegistry
