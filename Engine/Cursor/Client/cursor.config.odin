package CursorClient

import "../../../../OdinBasePack"
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
	cursorConfig: [Cursor.State]Cursor.CursorConfig(TShapeName),
) -> (
	error: TError,
) {
	module.created = true
	for config, state in cursorConfig {
		for shift in Cursor.Shift {
			module.cursor[state][shift] = {
				loadCursor(module, config.shapeName, shift, false) or_return,
				loadCursor(module, config.shapeName, shift, true) or_return,
				config,
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
getCursorOffset :: proc(shift: Cursor.Shift) -> (change: Math.Vector) {
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

@(private)
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
	change: Math.Vector,
) {
	if module.showCursorSurfaceBorder == visible {
		return
	}
	module.showCursorSurfaceBorder = visible
	setBareCursor(module) or_return
	return
}


@(private = "file")
@(require_results)
loadCursor :: proc(
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
	name: TShapeName,
	shift: Cursor.Shift,
	boxed: bool,
) -> (
	cursor: ^sdl3.Cursor,
	error: TError,
) {
	err: OdinBasePack.Error
	shape, _ := PainterClient.getShape(module.painterModule, name, true) or_return
	surface: ^sdl3.Surface
	surface, err = PainterClient.loadSurfaceFromShape(module.painterModule, shape)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	defer sdl3.DestroySurface(surface)
	if boxed {
		err = RendererClient.paintSurfaceBorder(module.rendererModule, surface, .BLUE)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	offset := getCursorOffset(shift)
	marker := offset + shape.markerVectorMap[.CURSOR_MOUSE_HOLDER]
	cursor = sdl3.CreateColorCursor(surface, i32(marker.x), i32(marker.y))
	if cursor == nil {
		error = .CURSOR_SDL_CURSOR_CREATION_FAILED
		return
	}
	return
}
