package CursorClient

import "../../Cursor"

@(require_results)
performChangedEvent :: proc(
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
	input: Cursor.ChangedEvent,
) -> (
	error: TError,
) {
	changeCursor(module, input.nextState, input.withText, input.customText) or_return
	return
}
