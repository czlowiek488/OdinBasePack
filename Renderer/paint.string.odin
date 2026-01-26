package Renderer

import "../Math"
import "vendor:sdl3"

StringConfig :: struct #all_or_none {
	bounds: Math.Rectangle,
	text:   string,
}

String :: struct #all_or_none {
	config:   StringConfig,
	stringId: StringId,
	text:     string,
	surface:  ^sdl3.Surface,
	texture:  ^sdl3.Texture,
}

StringId :: distinct PaintId
