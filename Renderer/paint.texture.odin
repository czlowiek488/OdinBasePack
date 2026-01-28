package Renderer

import "../Math"

TextureId :: distinct PaintId

TextureConfig :: struct #all_or_none {
	shapeName:   union {
		int,
		string,
	},
	rotation:    f32,
	zoom:        f32,
	bounds:      Math.Rectangle,
	staticShift: Math.Vector,
}

Texture :: struct #all_or_none {
	textureId: TextureId,
	config:    TextureConfig,
}
