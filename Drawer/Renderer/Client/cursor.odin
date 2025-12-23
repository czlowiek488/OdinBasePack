package RendererClient

import "../../../../OdinBasePack"
import "../../Shape"
import ShapeClient "../../Shape/Client"
import "vendor:sdl3"

@(require_results)
loadSurfaceFromShape :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	shape: ^Shape.Shape(TMarkerName),
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
getShape :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	name: union {
		TShapeName,
		string,
	},
	required: bool,
) -> (
	shape: ^Shape.Shape(TMarkerName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	shape, ok = ShapeClient.get(module.shapeModule, name, required) or_return
	return
}
