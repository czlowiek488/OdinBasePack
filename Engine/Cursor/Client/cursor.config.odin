package CursorClient

import "../../../../OdinBasePack"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
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
				loadCursor(module, config.shapeName, shift) or_return,
				config,
			}
		}
	}
	showAxises(module, {}) or_return
	EventLoop.pushTasks(module.eventLoop, Cursor.CursorEvent(Cursor.CreatedEvent{})) or_return
	return
}


@(private = "file")
@(require_results)
paintSurfaceBorder :: proc(
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
	surface: ^sdl3.Surface,
	colorName: Renderer.ColorName,
) -> (
	error: OdinBasePack.Error,
) {
	if !module.config.showCursorSurfaceBorder {
		return
	}
	if surface.format != .ABGR8888 {
		error = .CURSOR_SDL_INVALID_SURFACE_FORMAT
		return
	}
	if !sdl3.LockSurface(surface) {
		error = .CURSOR_SDL_SURFACE_LOCK_FAILED
		return
	}
	defer sdl3.UnlockSurface(surface)

	pixels := cast([^]u32)surface.pixels
	pitch := surface.pitch / size_of(u32)
	color := Renderer.getColor({.BLUE, 1})
	pixel_color := sdl3.MapRGBA(
		sdl3.GetPixelFormatDetails(surface.format),
		nil,
		color.r,
		color.g,
		color.b,
		color.a,
	)

	for x: i32; x < surface.w; x += 1 {
		pixels[x] = pixel_color
	}
	for x: i32; x < surface.w; x += 1 {
		pixels[(surface.h - 1) * pitch + x] = pixel_color
	}
	for y: i32; y < surface.h; y += 1 {
		pixels[y * pitch] = pixel_color
	}
	for y: i32; y < surface.h; y += 1 {
		pixels[y * pitch + (surface.w - 1)] = pixel_color
	}
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
	err = paintSurfaceBorder(module, surface, .BLUE)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
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
