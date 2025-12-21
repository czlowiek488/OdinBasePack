package PainterClient

import AnimationClient "../../Animation/Client"
import "../../Painter"

@(require_results)
animationFrameFinishedPerform :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	input: Painter.AnimationFrameFinishedEvent,
) -> (
	error: TError,
) {
	animation, _ := getAnimation(manager, input.animationId, true) or_return
	duration, err := AnimationClient.setNextFrame(&animation.element.animation)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	animation.element.timeoutId = manager.eventLoop->task(
		.TIMEOUT,
		duration,
		Painter.PainterEvent(
			Painter.AnimationFrameFinishedEvent{input.animationId, input.layerId},
		),
	) or_return
	return
}
