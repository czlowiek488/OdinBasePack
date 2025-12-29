package CursorClient

import "../../Cursor"
import "../../Steer"
import "vendor:sdl3"

@(private)
@(require_results)
changeCursor :: proc(
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
	maybeState: Maybe(Cursor.State),
	showText: bool,
	customText: Maybe(string),
) -> (
	error: TError,
) {
	if state, present := maybeState.?; present {
		module.state = state
	}
	module.showText = showText
	module.customText = customText
	cursorData := &module.cursor[module.state][module.shift]
	if !sdl3.SetCursor(cursorData.cursor) {
		error = .CURSOR_SDL_CURSOR_SET_FAILED
		return
	}
	if textId, present := module.textId.?; present {
		hideString(module) or_return
	}
	if !showText {
		return
	}
	if text, present := customText.?; present {
		showString(module, text) or_return
	} else if text, present := cursorData.config.maybeText.?; present {
		showString(module, text) or_return
	}
	return
}
