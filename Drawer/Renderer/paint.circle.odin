package Renderer

import "../../Math"
import "vendor:sdl3"

Renderer :: sdl3.Renderer


CircleDrawType :: enum {
	FILL,
	BORDER,
}

CircleId :: distinct PaintId

CircleConfig :: struct #all_or_none {
	type:     CircleDrawType,
	circle:   Math.Circle,
	limit:    f32,
	rotation: f32,
}

Circle :: struct #all_or_none {
	circleId: CircleId,
	config:   CircleConfig,
}
