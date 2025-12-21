package Painter

import "../Renderer"

AnimationId :: Renderer.AnimationId
PieMaskId :: Renderer.PieMaskId
StringId :: Renderer.StringId
RectangleId :: Renderer.RectangleId
CircleId :: Renderer.CircleId
LineId :: Renderer.LineId
TriangleId :: Renderer.TriangleId
GeometryId :: union {
	RectangleId,
	CircleId,
	TriangleId,
}
