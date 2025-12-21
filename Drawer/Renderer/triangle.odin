package Renderer

import "../../Math"

TriangleId :: distinct PaintId

TriangleConfig :: struct #all_or_none {
	triangle: Math.Triangle,
}

Triangle :: struct #all_or_none {
	triangleId: TriangleId,
	config:     TriangleConfig,
}
