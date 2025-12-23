package RendererClient

import "../../../../OdinBasePack"
import "../../../AutoSet"
import "../../../Math"
import "../../../SparseSet"
import "../../Renderer"
import "../../Shape"
import ShapeClient "../../Shape/Client"
import "vendor:sdl3"

@(require_results)
getRenderOrder :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	renderOrder: ^[Renderer.LayerId]^SparseSet.SparseSet(Renderer.PaintId, RenderOrder),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for bucket in module.renderOrder {
		SparseSet.sortBy(
			module,
			bucket,
			proc(
				module: ^Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
				aId, bId: RenderOrder,
			) -> int {
				a, aOk, _ := AutoSet.get(module.paintAS, aId.paintId, false)
				if !aOk {
					return 0
				}
				b, bOk, _ := AutoSet.get(module.paintAS, bId.paintId, false)
				if !bOk {
					return 0
				}
				return int(a.config.layer) - int(b.config.layer)
			},
		) or_return
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
		Renderer.ColorName,
		sdl3.Color,
	}) -> (error: OdinBasePack.Error) {
	switch value in color {
	case Renderer.ColorName:
		tint := Renderer.getColorFromName(value) or_return
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
		Renderer.ColorName,
		sdl3.Color,
	}) -> (error: OdinBasePack.Error) {
	switch value in color {
	case Renderer.ColorName:
		tint := Renderer.getColorFromName(value) or_return
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
