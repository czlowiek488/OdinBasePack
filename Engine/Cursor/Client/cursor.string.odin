package CursorClient

import "../../../../OdinBasePack"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
import "../../../Math"
import "../../Cursor"
import SteerClient "../../Steer/Client"
import "core:log"
import "vendor:sdl3"

@(require_results)
getStrPosition :: proc(
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
	position: Math.Vector,
	error: TError,
) {
	position = SteerClient.getMousePositionOnMap(module.steerModule) or_return
	position += 3
	position -= getCursorOffset(module.cursorState.shift)
	return
}

@(private)
@(require_results)
showString :: proc(
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
	text: string,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	module.cursorState.textId = PainterClient.createString(
		module.painterModule,
		{.PANEL_3, 0, nil, .MAP, {.WHITE, 1, 1, nil}},
		{{getStrPosition(module) or_return, {f32(len(text) * 3), 12}}, text},
	) or_return
	return
}

@(private)
@(require_results)
hideString :: proc(
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
	error: TError,
) {
	if textId, present := module.cursorState.textId.?; present {
		PainterClient.removeString(module.painterModule, textId) or_return
		module.cursorState.textId = nil
	} else {
		error = module.eventLoop.mapper(.CURSOR_STRING_ALREADY_REMOVED)
	}
	return
}
