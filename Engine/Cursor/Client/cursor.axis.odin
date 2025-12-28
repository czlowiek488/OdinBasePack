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
	if module.config.showCursorAxis.x {
		module.axis.x = PainterClient.createLine(
			module.painterModule,
			{.PANEL_7, 0, nil, .MAP, {.RED, 1}},
			{{0, position.y}, {module.config.windowSize.x, position.y}},
		) or_return
	}
	if module.config.showCursorAxis.y {
		module.axis.y = PainterClient.createLine(
			module.painterModule,
			{.PANEL_7, 0, nil, .MAP, {.RED, 1}},
			{{position.x, 0}, {position.x, module.config.windowSize.y}},
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
	if module.config.showCursorAxis.x {
		PainterClient.removeLine(module.painterModule, module.axis.x) or_return
	}
	if module.config.showCursorAxis.y {
		PainterClient.removeLine(module.painterModule, module.axis.y) or_return
	}
	return
}
