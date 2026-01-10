package CursorClient

import "../../../../OdinBasePack"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
import "../../../Math"

@(require_results)
setCursorAxisVisibility :: proc(
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
	visible: bool,
) -> (
	error: TError,
) {
	module.cursorState.showCursorAxis = visible
	hideAxises(module) or_return
	showAxises(module) or_return
	return
}

@(private)
@(require_results)
showAxises :: proc(
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
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if !module.cursorState.showCursorAxis {
		return
	}
	position := module.cursorState.mousePositionOnCamera / module.cursorState.tileScale
	metaConfig: Renderer.MetaConfig = {.PANEL_7, 0, nil, .CAMERA, {.RED, 1, .4, nil}}
	if x, ok := module.cursorState.axis.x.?; !ok {
		module.cursorState.axis.x = PainterClient.createLine(
			module.painterModule,
			metaConfig,
			{{0, position.y}, {module.cursorState.windowSize.x, position.y}},
		) or_return
	}
	if y, ok := module.cursorState.axis.y.?; !ok {
		module.cursorState.axis.y = PainterClient.createLine(
			module.painterModule,
			metaConfig,
			{{position.x, 0}, {position.x, module.cursorState.windowSize.y}},
		) or_return
	}
	return
}

@(private)
@(require_results)
hideAxises :: proc(
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
	if x, ok := module.cursorState.axis.x.?; ok {
		PainterClient.removeLine(module.painterModule, x) or_return
		module.cursorState.axis.x = nil
	}
	if y, ok := module.cursorState.axis.y.?; ok {
		PainterClient.removeLine(module.painterModule, y) or_return
		module.cursorState.axis.y = nil
	}
	return
}
