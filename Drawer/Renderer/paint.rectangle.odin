package Renderer

import "../../Math"

RectangleId :: distinct PaintId


RectangleDrawType :: enum {
	FILL,
	BORDER,
}

PositionType :: enum {
	CAMERA,
	MAP,
}

RectangleConfig :: struct #all_or_none {
	type:   RectangleDrawType,
	bounds: Math.Rectangle,
}

Rectangle :: struct #all_or_none {
	rectangleId: RectangleId,
	bounds:      Math.Rectangle,
	config:      RectangleConfig,
}
