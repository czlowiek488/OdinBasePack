package CursorClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
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
	maybeState: Maybe(Painter.State),
	showText: bool,
	customText: Maybe(string),
) -> (
	error: TError,
) {
	if state, present := maybeState.?; present {
		module.cursorState.state = state
	}
	module.cursorState.showText = showText
	module.cursorState.customText = customText
	err := PainterClient.setBareCursor(
		module.painterModule,
		&module.cursorState.cursor[module.cursorState.state],
		module.cursorState.shift,
		module.cursorState.showCursorSurfaceBorder,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if textId, present := module.cursorState.textId.?; present {
		hideString(module) or_return
	}
	if !showText {
		return
	}

	cursorData := &module.cursorState.cursor[module.cursorState.state]
	if text, present := customText.?; present {
		showString(module, text) or_return
	} else if text, present := cursorData.config.maybeText.?; present {
		showString(module, text) or_return
	}
	return
}
