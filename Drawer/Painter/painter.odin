package Painter

import "../../../OdinBasePack"
import "../../EventLoop"
import "../../Math"
import "../Animation"
import "../Renderer"
import "vendor:sdl3"

AnimationId :: distinct int
PieMaskId :: Renderer.PieMaskId
TextureId :: Renderer.TextureId
StringId :: Renderer.StringId
RectangleId :: Renderer.RectangleId
CircleId :: Renderer.CircleId
LineId :: Renderer.LineId
TriangleId :: Renderer.TriangleId
Color :: Renderer.Color
getColor :: Renderer.getColor
ColorName :: Renderer.ColorName
ColorDefinition :: Renderer.ColorDefinition
GeometryId :: union {
	RectangleId,
	CircleId,
	TriangleId,
}

AnimationConfig :: struct($TAnimationName: typeid) {
	animationName: union {
		TAnimationName,
		string,
	},
	rotation:      f32,
	zoom:          f32,
	bounds:        Math.Rectangle,
	metaConfig:    Renderer.MetaConfig,
}

Animation :: struct($TShapeName: typeid, $TAnimationName: typeid) {
	animationId:      AnimationId,
	config:           AnimationConfig(TAnimationName),
	currentTextureId: TextureId,
	timeoutId:        Maybe(EventLoop.ReferenceId),
	offset:           Math.Vector,
	animation:        Animation.Animation(TShapeName, TAnimationName),
}


colorToInt :: proc(c: sdl3.Color) -> u32 {
	return (u32(c.r) << 24) | (u32(c.g) << 16) | (u32(c.b) << 8) | u32(c.a)
}
