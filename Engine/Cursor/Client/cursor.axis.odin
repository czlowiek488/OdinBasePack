package CursorClient

import "../../../../OdinBasePack"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
import "../../../Math"

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
	position: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if !module.config.showCursorAxis {
		return
	}
	module.axis = {
		PainterClient.createLine(
			module.painterModule,
			{.PANEL_7, 0, nil, .MAP, {.RED, 1, 1, nil}},
			{{0, position.y}, {module.config.windowSize.x, position.y}},
		) or_return,
		PainterClient.createLine(
			module.painterModule,
			{.PANEL_7, 0, nil, .MAP, {.RED, 1, 1, nil}},
			{{position.x, 0}, {position.x, module.config.windowSize.y}},
		) or_return,
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
	if x, ok := module.axis.x.?; ok {
		PainterClient.removeLine(module.painterModule, x) or_return
	}
	if y, ok := module.axis.y.?; ok {
		PainterClient.removeLine(module.painterModule, y) or_return
	}
	return
}
