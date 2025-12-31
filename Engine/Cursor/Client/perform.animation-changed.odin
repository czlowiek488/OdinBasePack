package CursorClient

import "../../Cursor"

@(require_results)
performAnimationChangedEvent :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	input: Cursor.AnimationChangedEvent(TAnimationName),
) -> (
	error: TError,
) {
	data, ok := input.data.?
	if !ok {
		hideAnimation(module) or_return
		return
	}
	if _, ok = module.animationId.?; ok {
		hideAnimation(module) or_return
	}
	showAnimation(module, data) or_return
	return
}
