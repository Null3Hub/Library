--[[
    Apex UI Library - SafeCallback util
    Wraps any user callback in pcall so a buggy hook does not crash the UI.
]]

local function SafeCallback(callback, ...)
	if type(callback) ~= "function" then return end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[ApexLibrary] Callback error:", err)
	end
end

return SafeCallback
