package Painter

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
