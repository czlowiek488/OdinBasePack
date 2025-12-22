package Renderer

import "../../EventLoop"
import "../../Math"
import "../Animation"

TextureId :: distinct PaintId

TextureConfig :: struct($TShapeName: typeid) #all_or_none {
	shapeName: union {
		TShapeName,
		string,
	},
	rotation:  f32,
	zoom:      f32,
	bounds:    Math.Rectangle,
}

Texture :: struct($TShapeName: typeid) #all_or_none {
	textureId: TextureId,
	config:    TextureConfig(TShapeName),
}
