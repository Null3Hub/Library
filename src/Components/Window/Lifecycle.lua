--[[
    Apex UI Library - Window methods: lifecycle (destroy, minimize, visibility, callbacks)
    Integrates CameraEffects (FOV zoom) on show/hide.
]]

local OptionsRegistry = require(script.Parent.Parent.Parent.OptionsRegistry)

local Lifecycle = {}

function Lifecycle:OnDestroy(callback)
	if type(callback) == "function" then
		table.insert(self.DestroyCallbacks, callback)
	end
	return self
end

function Lifecycle:OnMinimize(callback)
	if type(callback) == "function" then
		table.insert(self.MinimizeCallbacks, callback)
	end
	return self
end

function Lifecycle:_FireDestroyCallbacks()
	if self._DestroyCallbacksFired then return end
	self._DestroyCallbacksFired = true
	for _, callback in ipairs(self.DestroyCallbacks or {}) do
		task.spawn(function()
			pcall(callback, self)
		end)
	end
end

function Lifecycle:_FireMinimizeCallbacks(state)
	for _, callback in ipairs(self.MinimizeCallbacks or {}) do
		task.spawn(function()
			pcall(callback, state, self)
		end)
	end
end

function Lifecycle:Minimize()
	self:SetVisible(false)
end

function Lifecycle:Destroy()
	if self.Destroyed then return end
	self:SetUserSettingsVisible(false, true)
	self.Destroyed = true
	-- Restore camera instantly
	if self.CameraEffects then
		self.CameraEffects:Destroy()
	end
	self:_FireDestroyCallbacks()
	OptionsRegistry.UnregisterUnder(self.ScreenGui)
	for _, conn in ipairs(self.Connections or {}) do
		pcall(function() conn:Disconnect() end)
	end
	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

function Lifecycle:SetVisible(state)
	if self.Destroyed or not self.Window then return end
	local nextVisible = state and true or false
	local minimized = self.Visible == true and nextVisible == false
	local restored = self.Visible == false and nextVisible == true
	self.Visible = nextVisible
	self.Window.Visible = self.Visible

	-- Camera effects: FOV zoom
	if self.CameraEffects then
		if minimized then
			self.CameraEffects:Remove()
		elseif restored then
			self.CameraEffects:Apply()
		end
	end

	if minimized then
		self:SetUserSettingsVisible(false, true)
		self:_FireMinimizeCallbacks(true)
	end
end

function Lifecycle:Toggle()
	self:SetVisible(not self.Visible)
end

return Lifecycle
