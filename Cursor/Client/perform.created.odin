package CursorClient

import "../../Cursor"

@(require_results)
performCreatedEvent :: proc(
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
	event: Cursor.CreatedEvent,
) -> (
	error: TError,
) {
	changeCursor(module, .REGULAR, false, nil) or_return
	return
}
