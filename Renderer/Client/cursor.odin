package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
loadSurfaceFromShape :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	shape: ^Renderer.Shape(TMarkerName),
) -> (
	surface: ^sdl3.Surface,
	error: OdinBasePack.Error,
) {
	if !module.created {
		error = .INVALID_ENUM_VALUE
		return
	}
	rect: sdl3.Rect = {
		i32(shape.bounds.position.x),
		i32(shape.bounds.position.y),
		i32(shape.bounds.size.x),
		i32(shape.bounds.size.y),
	}
	target := sdl3.CreateTexture(
		module.renderer,
		shape.texture.format,
		.TARGET,
		shape.texture.w,
		shape.texture.h,
	)
	defer sdl3.DestroyTexture(target)
	if target == nil {
		error = .CURSOR_SDL_TEXTURE_TARGET_FAILED
		return
	}
	if !sdl3.SetRenderTarget(module.renderer, target) {
		error = .CURSOR_SDL_RENDER_TARGET_CHANGE_FAILED
		return
	}
	if !sdl3.RenderClear(module.renderer) {
		error = .CURSOR_SDL_RENDER_CLEAR_FAILED
		return
	}
	if !sdl3.RenderTexture(module.renderer, shape.texture, nil, nil) {
		error = .CURSOR_SDL_RENDER_TEXTURE_FAILED
		return
	}
	surface = sdl3.RenderReadPixels(module.renderer, &rect)
	if surface == nil {
		error = .CURSOR_SDL_RENDER_TEXTURE_FAILED
		return
	}
	if !sdl3.SetRenderTarget(module.renderer, nil) {
		error = .CURSOR_SDL_RENDER_TARGET_REVERT_FAILED
		return
	}
	if !sdl3.RenderClear(module.renderer) {
		error = .CURSOR_SDL_RENDER_CLEAR_FAILED
		return
	}
	return
}

@(require_results)
paintSurfaceBorder :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	surface: ^sdl3.Surface,
	colorName: Renderer.ColorName,
) -> (
	error: OdinBasePack.Error,
) {
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
	color := Renderer.getColor({.BLUE, 1, 1, nil})
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

@(require_results)
setBareCursor :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	cursorData: ^Renderer.CursorData,
	shift: Renderer.Shift,
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
getCursorOffset :: proc(shift: Renderer.Shift) -> (change: Math.Vector) {
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
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	name: int,
	shift: Renderer.Shift,
	boxed: bool,
) -> (
	cursor: ^sdl3.Cursor,
	error: OdinBasePack.Error,
) {
	shape, _ := getShape(module, name, true) or_return
	surface := loadSurfaceFromShape(module, shape) or_return
	defer sdl3.DestroySurface(surface)
	if boxed {
		paintSurfaceBorder(module, surface, .BLUE) or_return
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
