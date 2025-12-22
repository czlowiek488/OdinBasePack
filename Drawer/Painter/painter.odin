package Painter

import "../Renderer"

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
