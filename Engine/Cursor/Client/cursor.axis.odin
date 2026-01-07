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
	module.showCursorAxis = visible
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
	if !module.showCursorAxis {
		return
	}
	position := module.mousePositionOnCamera / module.config.tileScale
	metaConfig: Renderer.MetaConfig = {.PANEL_7, 0, nil, .CAMERA, {.RED, 1, .4, nil}}
	if x, ok := module.axis.x.?; !ok {
		module.axis.x = PainterClient.createLine(
			module.painterModule,
			metaConfig,
			{{0, position.y}, {module.config.windowSize.x, position.y}},
		) or_return
	}
	if y, ok := module.axis.y.?; !ok {
		module.axis.y = PainterClient.createLine(
			module.painterModule,
			metaConfig,
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
	if x, ok := module.axis.x.?; ok {
		PainterClient.removeLine(module.painterModule, x) or_return
		module.axis.x = nil
	}
	if y, ok := module.axis.y.?; ok {
		PainterClient.removeLine(module.painterModule, y) or_return
		module.axis.y = nil
	}
	return
}
