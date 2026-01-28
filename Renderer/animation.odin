package Renderer

import "../Memory/Timer"
import "base:intrinsics"

AnimationFrame :: struct {
	shapeName: int,
	duration:  Timer.Time,
}

PainterAnimationConfig :: struct {
	animationName: int,
	frameList:     []AnimationFrame,
}

DynamicAnimationFrame :: struct {
	shapeName: string,
	duration:  Timer.Time,
}

DynamicAnimationConfig :: struct {
	frameList: []DynamicAnimationFrame,
}

PainterAnimation :: struct {
	config:            union {
		PainterAnimationConfig,
		DynamicAnimationConfig,
	},
	frameListLength:   int,
	created:           bool,
	infinite:          bool,
	currentFrameIndex: int,
	duration:          Timer.Time,
	totalDuration:     Timer.Time,
}
