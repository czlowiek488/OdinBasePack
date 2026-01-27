package Renderer

import "../Math"

TextureId :: distinct PaintId

TextureConfig :: struct($TShapeName: typeid) #all_or_none {
	shapeName:   union {
		TShapeName,
		string,
	},
	rotation:    f32,
	zoom:        f32,
	bounds:      Math.Rectangle,
	staticShift: Math.Vector,
}

Texture :: struct($TShapeName: typeid) #all_or_none {
	textureId: TextureId,
	config:    TextureConfig(TShapeName),
}
