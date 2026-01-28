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

AnimationConfig :: struct {
	animationName: union {
		int,
		string,
	},
	rotation:      f32,
	zoom:          f32,
	bounds:        Math.Rectangle,
	staticShift:   Math.Vector,
	metaConfig:    Renderer.MetaConfig,
}

Animation :: struct($TShapeName: typeid) {
	animationId:      AnimationId,
	config:           AnimationConfig,
	currentTextureId: TextureId,
	timeoutId:        Maybe(EventLoop.ReferenceId),
	offset:           Math.Vector,
	animation:        PainterAnimation(TShapeName),
}
