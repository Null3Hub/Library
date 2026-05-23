--[[
    Apex UI Library - Create utilities
    Thin wrappers around Instance.new used everywhere in the library.
    Behavior is identical to the helpers from the original single-file build.
]]

local Theme = require(script.Parent.Parent.Theme)

local Create = {}

function Create.Instance(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

function Create.Corner(radius, parent)
	local c = Create.Instance("UICorner", { CornerRadius = UDim.new(0, radius) })
	if parent then c.Parent = parent end
	return c
end

function Create.Stroke(parent, color, thickness)
	local s = Create.Instance("UIStroke", {
		Color = color or Theme.THEME.BORDER,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
	if parent then s.Parent = parent end
	return s
end

function Create.Padding(parent, t, r, b, l)
	local p = Create.Instance("UIPadding", {
		PaddingTop    = UDim.new(0, t or 0),
		PaddingRight  = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft   = UDim.new(0, l or 0),
	})
	if parent then p.Parent = parent end
	return p
end

function Create.ListLayout(parent, fillDir, hAlign, vAlign, spacing)
	local l = Create.Instance("UIListLayout", {
		FillDirection       = fillDir or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Padding             = UDim.new(0, spacing or 0),
	})
	if parent then l.Parent = parent end
	return l
end

-- Animated gradient stroke wrapper used as the windowed border highlight.
function Create.GradientStrokeFrame(parent, name, radius, thickness, zIndex)
	local TweenService = game:GetService("TweenService")
	local THEME = Theme.THEME

	local frame = Create.Instance("Frame", {
		Name = name or "GradientStrokeFrame",
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Active = false,
		Selectable = false,
		ZIndex = zIndex or 100,
		Parent = parent,
	})
	Create.Corner(radius, frame)

	local stroke = Create.Instance("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 0.02,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = frame,
	})

	local gradient = Create.Instance("UIGradient", {
		Name = "AnimatedStrokeGradient",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, THEME.STROKE_PURPLE),
			ColorSequenceKeypoint.new(0.22, Color3.fromRGB(126, 76, 214)),
			ColorSequenceKeypoint.new(0.48, THEME.STROKE_LIGHT),
			ColorSequenceKeypoint.new(0.72, THEME.STROKE_MID),
			ColorSequenceKeypoint.new(1.00, THEME.STROKE_PURPLE),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.00),
			NumberSequenceKeypoint.new(0.14, 0.28),
			NumberSequenceKeypoint.new(0.50, 0.02),
			NumberSequenceKeypoint.new(0.86, 0.28),
			NumberSequenceKeypoint.new(1.00, 1.00),
		}),
		Parent = stroke,
	})
	TweenService:Create(gradient, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), { Rotation = 450 }):Play()
	return frame, stroke, gradient
end

return Create
