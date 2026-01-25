package RendererClient

import "../../../../OdinBasePack"
import "../../../Memory/SparseSet"
import "../../Renderer"
import "core:math"
import "vendor:sdl3"

@(require_results)
calculateRenderOrder :: proc(y: f32, zIndex: Renderer.ZIndex, paintId: Renderer.PaintId) -> u128 {
	return u128(10_000_000 * y) + u128(10_000 * zIndex) + u128(paintId)
}

@(require_results)
getRenderOrder :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	renderOrder: ^[Renderer.LayerId]^SparseSet.SparseSet(Renderer.PaintId, RenderOrder),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for bucket in module.renderOrder {
		SparseSet.sortBy(bucket, proc(a, b: RenderOrder) -> int {
			if a.position < b.position {return -1}
			if a.position > b.position {return 1}
			return 0
		}) or_return
	}
	renderOrder = &module.renderOrder
	return
}

@(require_results)
clearScreen :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	if !sdl3.RenderClear(module.renderer) {
		error = .PAINTER_RENDER_CLEAR_FAILED
		return
	}
	return
}

@(require_results)
drawScreen :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	if !sdl3.RenderPresent(module.renderer) {
		error = .PAINTER_DRAW_SCREEN_FAILED
		return
	}
	return
}

@(require_results)
setTextureColor :: proc(texture: ^sdl3.Texture, color: union {
		Renderer.ColorDefinition,
		sdl3.Color,
	}) -> (error: OdinBasePack.Error) {
	switch value in color {
	case Renderer.ColorDefinition:
		tint := Renderer.getColor(value)
		if !sdl3.SetTextureColorMod(texture, tint.r, tint.g, tint.b) {
			error = .PAINTER_TEXTURE_COLOR_MOD_SET_FAILED
			return
		}
		if !sdl3.SetTextureAlphaMod(texture, tint.a) {
			error = .PAINTER_TEXTURE_ALPHA_MOD_FAILED
			return
		}
	case sdl3.Color:
		if !sdl3.SetTextureColorMod(texture, value.r, value.g, value.b) {
			error = .PAINTER_TEXTURE_COLOR_MOD_SET_FAILED
			return
		}
		if !sdl3.SetTextureAlphaMod(texture, value.a) {
			error = .PAINTER_TEXTURE_ALPHA_MOD_FAILED
			return
		}
	}
	return
}


@(require_results)
setRendererColor :: proc(renderer: ^sdl3.Renderer, color: union {
		Renderer.ColorDefinition,
		sdl3.Color,
	}) -> (error: OdinBasePack.Error) {
	switch value in color {
	case Renderer.ColorDefinition:
		tint := Renderer.getColor(value)
		if !sdl3.SetRenderDrawColor(renderer, tint.r, tint.g, tint.b, tint.a) {
			error = .PAINTER_RENDER_DRAW_COLOR_SET_FAILED
			return
		}
	case sdl3.Color:
		if !sdl3.SetRenderDrawColor(renderer, value.r, value.g, value.b, value.a) {
			error = .PAINTER_RENDER_DRAW_COLOR_SET_FAILED
			return
		}
	}
	return
}
