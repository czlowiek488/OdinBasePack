package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
createTexture :: proc(
	module: ^Module,
	metaConfig: Renderer.MetaConfig,
	config: Renderer.TextureConfig,
	location := #caller_location,
) -> (
	textureId: Renderer.TextureId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId, paint := createPaint(module, metaConfig, Renderer.Texture{0, config}) or_return
	textureId = Renderer.TextureId(paintId)
	trackEntity(module, cast(^Renderer.Paint(Renderer.PaintData))paint) or_return
	return
}


@(require_results)
removeTexture :: proc(
	module: ^Module,
	textureId: Renderer.TextureId,
	location := #caller_location,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint := removePaint(module, textureId, Renderer.Texture) or_return
	unTrackEntity(module, &paint) or_return
	return
}

@(require_results)
getTexture :: proc(
	module: ^Module,
	textureId: Renderer.TextureId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Texture),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(module, textureId, Renderer.Texture, required) or_return
	return
}


@(require_results)
setTextureOffset :: proc(
	module: ^Module,
	animationId: Renderer.TextureId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getPaint(module, animationId, Renderer.Texture, true) or_return
	meta.offset = offset
	return
}

@(require_results)
drawTexture :: proc(
	module: ^Module,
	texture: ^Renderer.Paint(Renderer.Texture),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	destination: Math.Vector
	switch texture.config.positionType {
	case Renderer.PositionType.CAMERA:
		destination = texture.element.config.bounds.position + texture.offset
	case Renderer.PositionType.MAP:
		destination =
			texture.element.config.bounds.position + texture.offset - module.camera.bounds.position
	}
	bounds: Math.Rectangle = {destination, texture.element.config.bounds.size}
	if texture.element.config.zoom != 1 {
		destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
		newSize: Math.Vector = bounds.size * texture.element.config.zoom
		bounds = {destinationCenter - (newSize / 2), newSize}
	}
	destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
	shape, _ := getShape(module, texture.element.config.shapeName, true) or_return
	setTextureColor(shape.texture, texture.config.color) or_return
	if !sdl3.RenderTextureRotated(
		module.renderer,
		shape.texture,
		cast(^sdl3.FRect)&shape.bounds,
		cast(^sdl3.FRect)&bounds,
		f64(texture.element.config.rotation),
		sdl3.FPoint(bounds.size / 2),
		.NONE if shape.direction == .LEFT_RIGHT else .HORIZONTAL,
	) {
		error = .PAINTER_TEXTURE_ROTATED_RENDER_FAILED
		return
	}
	return
}
