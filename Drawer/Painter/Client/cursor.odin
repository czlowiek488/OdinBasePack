package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Painter"
import RendererClient "../../Renderer/Client"
import "../../Shape"
import "vendor:sdl3"

@(require_results)
loadSurfaceFromShape :: proc(
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
	shape: ^Shape.Shape(TMarkerName),
) -> (
	surface: ^sdl3.Surface,
	error: OdinBasePack.Error,
) {
	surface = RendererClient.loadSurfaceFromShape(module.rendererModule, shape) or_return
	return
}

@(require_results)
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
	cursorData: ^Painter.CursorData(TShapeName),
	shift: Painter.Shift,
	border: bool,
) -> (
	error: OdinBasePack.Error,
) {
	if !sdl3.SetCursor(
		cursorData.shifts[shift].cursorBoxed if border else cursorData.shifts[shift].cursor,
	) {
		error = .CURSOR_SDL_CURSOR_SET_FAILED
		return
	}
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
	shift: Painter.Shift,
	boxed: bool,
) -> (
	cursor: ^sdl3.Cursor,
	error: TError,
) {
	err: OdinBasePack.Error
	shape, _ := getShape(module, name, true) or_return
	surface: ^sdl3.Surface
	surface, err = loadSurfaceFromShape(module, shape)
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
