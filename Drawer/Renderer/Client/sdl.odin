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
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
) -> (
	renderOrder: ^[Renderer.LayerId]^SparseSet.SparseSet(Renderer.PaintId, RenderOrder),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for bucket in manager.renderOrder {
		SparseSet.sortBy(
			manager,
			bucket,
			proc(
				manager: ^Manager(
					TFileImageName,
					TBitmapName,
					TMarkerName,
					TShapeName,
					TAnimationName,
				),
				aId, bId: RenderOrder,
			) -> int {
				a, aOk, _ := AutoSet.get(manager.paintAS, aId.paintId, false)
				if !aOk {
					return 0
				}
				b, bOk, _ := AutoSet.get(manager.paintAS, bId.paintId, false)
				if !bOk {
					return 0
				}
				return int(a.config.layer) - int(b.config.layer)
			},
		) or_return
	}
	renderOrder = &manager.renderOrder
	return
}

@(require_results)
clearScreen :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	if !sdl3.RenderClear(manager.renderer) {
		error = .PAINTER_RENDER_CLEAR_FAILED
		return
	}
	return
}

@(require_results)
drawScreen :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	if !sdl3.RenderPresent(manager.renderer) {
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

@(require_results)
drawTexture :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	texture: ^sdl3.Texture,
	source, destination: ^Math.Rectangle,
	relativeRotationCenter: Math.Vector,
	color: union {
		Renderer.ColorName,
		sdl3.Color,
	},
	direction: Shape.ShapeDirection,
	rotation: f32,
) -> (
	error: OdinBasePack.Error,
) {
	setTextureColor(texture, color) or_return
	if !sdl3.RenderTextureRotated(
		manager.renderer,
		texture,
		cast(^sdl3.FRect)source,
		cast(^sdl3.FRect)destination,
		f64(rotation),
		sdl3.FPoint(relativeRotationCenter),
		ShapeClient.getFlipMode(direction) or_return,
	) {
		error = .PAINTER_TEXTURE_ROTATED_RENDER_FAILED
		return
	}
	return
}
