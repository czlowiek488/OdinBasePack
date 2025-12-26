package Renderer

import "../../Math"
import "vendor:sdl3"

Renderer :: sdl3.Renderer

CircleId :: distinct PaintId

CircleConfig :: struct #all_or_none {
	circle:   Math.Circle,
	limit:    f32,
	rotation: f32,
}

Circle :: struct #all_or_none {
	circleId: CircleId,
	config:   CircleConfig,
}
