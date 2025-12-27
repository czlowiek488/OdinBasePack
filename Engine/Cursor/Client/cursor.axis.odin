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
		color: Renderer.Color
		color, err = Renderer.getColorFromName(.RED)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		module.axis.x = PainterClient.createLine(
			module.painterModule,
			{.PANEL_7, 0, nil, .MAP, color},
			{{0, position.y}, {module.config.windowSize.x, position.y}},
		) or_return
	}
	if module.config.showCursorAxis.y {
		color: Renderer.Color
		color, err = Renderer.getColorFromName(.RED)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		module.axis.y = PainterClient.createLine(
			module.painterModule,
			{.PANEL_7, 0, nil, .MAP, color},
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
