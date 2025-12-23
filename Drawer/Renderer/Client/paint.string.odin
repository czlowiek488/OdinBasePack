package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Text"
import "../../Renderer"
import "core:fmt"
import "core:strings"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

@(require_results)
createString :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.StringConfig,
) -> (
	stringId: Renderer.StringId,
	paint: ^Renderer.Paint(Renderer.String, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	cText := fmt.caprint(config.text, allocator = context.temp_allocator)
	copiedText, _ := strings.clone(config.text, manager.allocator)
	surface := ttf.RenderText_Blended_Wrapped(
		manager.font,
		cText,
		len(cText),
		metaConfig.color,
		i32(config.bounds.size.x * 8),
	)
	if surface == nil {
		error = .SDL3_TTF_UTF8_RENDER_ERROR
		return
	}
	texture := sdl3.CreateTextureFromSurface(manager.renderer, surface)
	if texture == nil {
		error = .SDL3_TTF_CANNOT_CREATE_TEXTURE_FROM_SURFACE
		return
	}
	paintId: Renderer.PaintId
	paintId, paint = createPaint(
		manager,
		metaConfig,
		Renderer.String{config, 0, copiedText, surface, texture},
	) or_return
	stringId = Renderer.StringId(paintId)
	return
}

@(require_results)
getString :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	stringId: Renderer.StringId,
	required: bool,
) -> (
	meta: ^Renderer.Paint(Renderer.String, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	meta, ok = getPaint(manager, stringId, Renderer.String, required) or_return
	return
}

@(require_results)
setStringOffset :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	stringId: Renderer.StringId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getString(manager, stringId, true) or_return
	meta.offset = offset
	return
}

@(require_results)
removeString :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	stringId: Renderer.StringId,
) -> (
	paint: Renderer.Paint(Renderer.String, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	str, _ := getString(manager, stringId, true) or_return
	Text.destroy(str.element.text, manager.allocator) or_return
	sdl3.DestroySurface(str.element.surface)
	sdl3.DestroyTexture(str.element.texture)
	paint = removePaint(manager, stringId, Renderer.String) or_return
	return
}

@(require_results)
drawString :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	str: ^Renderer.Paint(Renderer.String, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	textSurfaceBounds: Math.Rectangle = {
		{0, 0},
		{f32(str.element.surface.w), f32(str.element.surface.h)},
	}
	destination: Math.Vector
	switch str.config.positionType {
	case .CAMERA:
		destination = str.element.config.bounds.position + str.offset
	case .MAP:
		destination =
			str.element.config.bounds.position + str.offset - manager.camera.bounds.position
	}
	bounds: Math.Rectangle = {destination, str.element.config.bounds.size}
	setTextureColor(str.element.texture, str.config.color) or_return
	if !sdl3.RenderTexture(
		manager.renderer,
		str.element.texture,
		cast(^sdl3.FRect)&textSurfaceBounds,
		cast(^sdl3.FRect)&bounds,
	) {
		error = .PAINTER_TEXTURE_ROTATED_RENDER_FAILED
		return
	}
	return
}
