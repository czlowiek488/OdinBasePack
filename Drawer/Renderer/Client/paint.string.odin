package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/Text"
import "../../Renderer"
import "core:fmt"
import "core:strings"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

@(require_results)
createString :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.StringConfig,
) -> (
	stringId: Renderer.StringId,
	paint: ^Renderer.Paint(Renderer.String, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	cText := fmt.caprint(config.text, allocator = context.temp_allocator)
	copiedText, _ := strings.clone(config.text, module.allocator)
	color := Renderer.getColor(metaConfig.color)
	surface := ttf.RenderText_Blended_Wrapped(
		module.font,
		cText,
		len(cText),
		color,
		i32(config.bounds.size.x * 8),
	)
	if surface == nil {
		error = .SDL3_TTF_UTF8_RENDER_ERROR
		return
	}
	texture := sdl3.CreateTextureFromSurface(module.renderer, surface)
	if texture == nil {
		error = .SDL3_TTF_CANNOT_CREATE_TEXTURE_FROM_SURFACE
		return
	}
	paintId: Renderer.PaintId
	paintId, paint = createPaint(
		module,
		metaConfig,
		Renderer.String{config, 0, copiedText, surface, texture},
	) or_return
	stringId = Renderer.StringId(paintId)
	return
}

@(require_results)
getString :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	stringId: Renderer.StringId,
	required: bool,
) -> (
	meta: ^Renderer.Paint(Renderer.String, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	meta, ok = getPaint(module, stringId, Renderer.String, required) or_return
	return
}

@(require_results)
setStringOffset :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	stringId: Renderer.StringId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getString(module, stringId, true) or_return
	meta.offset = offset
	return
}

@(require_results)
removeString :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	stringId: Renderer.StringId,
) -> (
	paint: Renderer.Paint(Renderer.String, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	str, _ := getString(module, stringId, true) or_return
	Text.destroy(str.element.text, module.allocator) or_return
	sdl3.DestroySurface(str.element.surface)
	sdl3.DestroyTexture(str.element.texture)
	paint = removePaint(module, stringId, Renderer.String) or_return
	return
}

@(require_results)
drawString :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
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
			str.element.config.bounds.position + str.offset - module.camera.bounds.position
	}
	updateRenderZIndexPosition(module, str.paintId, str.config.layer, destination) or_return
	bounds: Math.Rectangle = {destination, str.element.config.bounds.size}
	setTextureColor(str.element.texture, str.config.color) or_return
	if !sdl3.RenderTexture(
		module.renderer,
		str.element.texture,
		cast(^sdl3.FRect)&textSurfaceBounds,
		cast(^sdl3.FRect)&bounds,
	) {
		error = .PAINTER_TEXTURE_ROTATED_RENDER_FAILED
		return
	}
	return
}
