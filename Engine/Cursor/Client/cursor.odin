package CursorClient

import "../../../../OdinBasePack"
import "../../Cursor"
import "../../Steer"
import "vendor:sdl3"

@(private)
setBareCursor :: proc(
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
) -> (
	error: OdinBasePack.Error,
) {
	cursorData := &module.cursor[module.state][module.shift]
	if !sdl3.SetCursor(
		cursorData.cursorBoxed if module.showCursorSurfaceBorder else cursorData.cursor,
	) {
		error = .CURSOR_SDL_CURSOR_SET_FAILED
		return
	}
	return
}

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
	err := setBareCursor(module)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if textId, present := module.textId.?; present {
		hideString(module) or_return
	}
	if !showText {
		return
	}
	cursorData := &module.cursor[module.state][module.shift]
	if text, present := customText.?; present {
		showString(module, text) or_return
	} else if text, present := cursorData.config.maybeText.?; present {
		showString(module, text) or_return
	}
	return
}
