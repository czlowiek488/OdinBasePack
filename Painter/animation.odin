package Painter

import "../Memory/Timer"
import "base:intrinsics"

AnimationFrame :: struct(
	$TShapeName: typeid
) where intrinsics.type_is_enum(TShapeName) ||
	TShapeName == int
{
	shapeName: TShapeName,
	duration:  Timer.Time,
}

PainterAnimationConfig :: struct($TShapeName: typeid, $TAnimationName: typeid) {
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

PainterAnimation :: struct($TShapeName: typeid, $TAnimationName: typeid) {
	config:            union {
		PainterAnimationConfig(TShapeName, TAnimationName),
		DynamicAnimationConfig,
	},
	frameListLength:   int,
	created:           bool,
	infinite:          bool,
	currentFrameIndex: int,
	duration:          Timer.Time,
	totalDuration:     Timer.Time,
}
