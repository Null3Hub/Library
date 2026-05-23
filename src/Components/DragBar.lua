--[[
    Apex UI Library - DragBar
    Standalone drag handle that lives below the main window.

    Visual states:
        normal   -> BackgroundTransparency 0.5
        hover    -> 0.3
        pressed  -> 0.1 + soft glow (UIStroke same color as the bar)
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Util  = require(script.Parent.Parent.Util)

local Create = Util.Create
local Corner = Util.Corner
local TW_FAST = Theme.TW_FAST

local DRAG_BAR_W   = 80
local DRAG_BAR_H   = 4
local DRAG_BAR_GAP = 12

local BAR_COLOR        = Color3.fromRGB(200, 200, 210)
local NORMAL_ALPHA     = 0.4
local HOVER_ALPHA      = 0.3
local PRESSED_ALPHA    = 0.1
local GLOW_ALPHA       = 0.1 -- 1 = invisible, 0.3 = subtle glow

local DragBar = {}

--- Build and wire the drag bar.
-- @param screenGui Instance ScreenGui that owns the window
-- @param window    Instance Window root frame to follow and move
-- @return table { Frame = Frame, Connections = { RBXScriptConnection, ... } }
function DragBar.new(screenGui, window)
	local connections = {}

	local bar = Create("Frame", {
		Name = "DragBar",
		Size = UDim2.fromOffset(DRAG_BAR_W, DRAG_BAR_H),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = BAR_COLOR,
		BackgroundTransparency = NORMAL_ALPHA,
		BorderSizePixel = 0,
		Active = true,
		Visible = window.Visible,
		ZIndex = 120,
		Parent = screenGui,
	})
	Corner(2, bar)

	local glow = Create("UIStroke", {
		Color = BAR_COLOR,
		Transparency = 1,
		Thickness = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = bar,
	})

	-- ===== position tracking =====
	local guiInset = game:GetService("GuiService"):GetGuiInset()
	local function updatePosition()
		if not window.Parent then return end
		local absPos  = window.AbsolutePosition
		local absSize = window.AbsoluteSize
		-- AbsolutePosition is relative to the inset viewport, but our ScreenGui
		-- uses IgnoreGuiInset = true, so we must add the inset Y offset back.
		bar.Position = UDim2.fromOffset(
			math.floor(absPos.X + absSize.X / 2 - DRAG_BAR_W / 2),
			math.floor(absPos.Y + absSize.Y + guiInset.Y + DRAG_BAR_GAP)
		)
	end
	updatePosition()
	table.insert(connections, window:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition))
	table.insert(connections, window:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition))

	-- ===== visibility tracking =====
	table.insert(connections, window:GetPropertyChangedSignal("Visible"):Connect(function()
		bar.Visible = window.Visible
	end))

	-- ===== self-contained drag pipeline =====
	local dragging = false
	local dragInput, startMouse, startWindowPos

	local function setVisualState(state)
		-- "normal" | "hover" | "pressed"
		if state == "pressed" then
			TweenService:Create(bar,  TW_FAST, { BackgroundTransparency = PRESSED_ALPHA }):Play()
			TweenService:Create(glow, TW_FAST, { Transparency = GLOW_ALPHA }):Play()
		elseif state == "hover" then
			TweenService:Create(bar,  TW_FAST, { BackgroundTransparency = HOVER_ALPHA }):Play()
			TweenService:Create(glow, TW_FAST, { Transparency = 1 }):Play()
		else
			TweenService:Create(bar,  TW_FAST, { BackgroundTransparency = NORMAL_ALPHA }):Play()
			TweenService:Create(glow, TW_FAST, { Transparency = 1 }):Play()
		end
	end

	bar.MouseEnter:Connect(function()
		if not dragging then setVisualState("hover") end
	end)
	bar.MouseLeave:Connect(function()
		if not dragging then setVisualState("normal") end
	end)

	bar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragInput = input
		startMouse = input.Position
		startWindowPos = window.Position
		setVisualState("pressed")

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
				-- Restore hover or normal depending on cursor location.
				setVisualState("normal")
			end
		end)
	end)

	-- Global movement listener — only acts while dragging from this bar.
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging or not startMouse or not startWindowPos or not dragInput then
			return
		end
		local isMouse = dragInput.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = dragInput.UserInputType == Enum.UserInputType.Touch
			and input.UserInputType == Enum.UserInputType.Touch
		if not isMouse and not isTouch then return end

		local delta = input.Position - startMouse
		window.Position = UDim2.new(
			startWindowPos.X.Scale, startWindowPos.X.Offset + delta.X,
			startWindowPos.Y.Scale, startWindowPos.Y.Offset + delta.Y
		)
	end))

	return {
		Frame = bar,
		Connections = connections,
		Destroy = function()
			for _, conn in ipairs(connections) do
				pcall(function() conn:Disconnect() end)
			end
			if bar and bar.Parent then bar:Destroy() end
		end,
	}
end

return DragBar
