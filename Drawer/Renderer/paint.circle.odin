package Renderer

import "../../Math"

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
