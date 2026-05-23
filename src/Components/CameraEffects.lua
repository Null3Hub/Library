--[[
    Apex UI Library - Camera Effects
    Handles camera zoom (FOV) when the window is shown/hidden.

    API:
        CameraEffects.new() -> self
        self:Apply()   -- zoom in (window visible)
        self:Remove()  -- restore original FOV (window minimized)
        self:Destroy() -- cleanup
]]

local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")

local TW_IN  = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local ZOOM_FOV = 40   -- zoomed-in FOV when UI is open

local CameraEffects = {}

function CameraEffects.new()
	local self = {}
	self._applied = false
	self._originalFOV = nil

	function self:Apply()
		if self._applied then return end
		self._applied = true

		local camera = Workspace.CurrentCamera
		if camera then
			self._originalFOV = camera.FieldOfView
			TweenService:Create(camera, TW_IN, { FieldOfView = ZOOM_FOV }):Play()
		end
	end

	function self:Remove()
		if not self._applied then return end
		self._applied = false

		local camera = Workspace.CurrentCamera
		if camera and self._originalFOV then
			TweenService:Create(camera, TW_OUT, { FieldOfView = self._originalFOV }):Play()
		end
	end

	function self:Destroy()
		self._applied = false
		local camera = Workspace.CurrentCamera
		if camera and self._originalFOV then
			camera.FieldOfView = self._originalFOV
		end
	end

	return self
end

return CameraEffects
