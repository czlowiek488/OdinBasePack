package PainterAnimation

import "../../Memory/Timer"
import "base:intrinsics"

AnimationFrame :: struct(
	$TShapeName: typeid
) where intrinsics.type_is_enum(TShapeName) ||
	TShapeName == int
{
	shapeName: TShapeName,
	duration:  Timer.Time,
}

AnimationConfig :: struct($TShapeName: typeid, $TAnimationName: typeid) {
	animationName: TAnimationName,
	frameList:     []AnimationFrame(TShapeName),
}

DynamicAnimationFrame :: struct {
	shapeName: string,
	duration:  Timer.Time,
}

DynamicAnimationConfig :: struct {
	frameList: []DynamicAnimationFrame,
}

Animation :: struct($TShapeName: typeid, $TAnimationName: typeid) {
	config:            union {
		AnimationConfig(TShapeName, TAnimationName),
		DynamicAnimationConfig,
	},
	frameListLength:   int,
	created:           bool,
	infinite:          bool,
	currentFrameIndex: int,
	duration:          Timer.Time,
	totalDuration:     Timer.Time,
}
