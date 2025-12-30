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
	if data, ok := input.data.?; ok {
		showAnimation(module, data) or_return
	} else {
		hideAnimation(module) or_return
	}
	return
}
