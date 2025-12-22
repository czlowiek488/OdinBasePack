package Renderer

import "../../Math"
import "base:intrinsics"
import "vendor:sdl3"

Vertex :: struct #all_or_none {
	position:     Math.Vector,
	color:        sdl3.Color,
	textPosition: Math.Vector,
}

PieMaskConfig :: struct #all_or_none {
	shapeName:              union {
		int,
		string,
	},
	bounds:                 Math.Rectangle,
	clockwise:              bool,
	startingFillPercentage: f32,
}

PieMask :: struct #all_or_none {
	pieMaskId:      PieMaskId,
	config:         PieMaskConfig,
	vertices:       [dynamic]Vertex,
	indices:        [dynamic]u32,
	fillPercentage: f32,
}

PieMaskId :: distinct PaintId
