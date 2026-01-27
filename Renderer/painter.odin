package Renderer

import "../EventLoop"
import "../Math"
import "../Renderer"
import "vendor:sdl3"

AnimationId :: distinct int
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
	staticShift:   Math.Vector,
	metaConfig:    Renderer.MetaConfig,
}

Animation :: struct($TShapeName: typeid, $TAnimationName: typeid) {
	animationId:      AnimationId,
	config:           AnimationConfig(TAnimationName),
	currentTextureId: TextureId,
	timeoutId:        Maybe(EventLoop.ReferenceId),
	offset:           Math.Vector,
	animation:        PainterAnimation(TShapeName, TAnimationName),
}
