package CursorClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
import RendererClient "../../../Drawer/Renderer/Client"
import "../../../EventLoop"
import "../../../Math"
import "../../Cursor"
import "vendor:sdl3"

@(require_results)
loadConfigAndInitialize :: proc(
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
	cursorConfig: [Painter.State]Painter.CursorConfig(TShapeName),
) -> (
	error: TError,
) {
	module.cursorState.created = true
	for config, state in cursorConfig {
		module.cursorState.cursor[state].config = config
		for shift in Painter.Shift {
			module.cursorState.cursor[state].shifts[shift] = {
				PainterClient.loadCursor(
					module.painterModule,
					config.shapeName,
					shift,
					false,
				) or_return,
				PainterClient.loadCursor(
					module.painterModule,
					config.shapeName,
					shift,
					true,
				) or_return,
			}
		}
	}
	EventLoop.pushTasks(
		module.eventLoop,
		Cursor.CursorEvent(TAnimationName)(Cursor.CreatedEvent{}),
	) or_return
	return
}


@(private)
@(require_results)
getCursorOffset :: proc(shift: Painter.Shift) -> (change: Math.Vector) {
	switch shift {
	case .REGULAR:
	case .BOTH_BUTTON_CLICKED:
		change = {0, 2}
	case .LEFT_BUTTON_CLICKED:
		change = {-2, 1}
	case .RIGHT_BUTTON_CLICKED:
		change = {2, 1}
	}
	return
}

@(require_results)
setCursorBoxVisibility :: proc(
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
	if module.cursorState.showCursorSurfaceBorder == visible {
		return
	}
	module.cursorState.showCursorSurfaceBorder = visible
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
	return
}
