package Renderer

import "../../EventLoop"
import "../../Math"
import "../Animation"

AnimationId :: distinct PaintId

AnimationConfig :: struct($TShapeName: typeid, $TAnimationName: typeid) #all_or_none {
	animationName: union {
		TAnimationName,
		string,
	},
	rotation:      f32,
	zoom:          f32,
	bounds:        Math.Rectangle,
}

Animation :: struct($TShapeName: typeid, $TAnimationName: typeid) #all_or_none {
	animationId: AnimationId,
	config:      AnimationConfig(TShapeName, TAnimationName),
	timeoutId:   Maybe(EventLoop.ReferenceId),
	animation:   Animation.Animation(TShapeName, TAnimationName),
}
