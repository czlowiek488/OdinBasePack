package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import ShapeClient "../../Shape/Client"
import "vendor:sdl3"

@(require_results)
createTexture :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.TextureConfig(TShapeName),
	location := #caller_location,
) -> (
	textureId: Renderer.TextureId,
	paint: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(
		module,
		metaConfig,
		Renderer.Texture(TShapeName){0, config},
	) or_return
	textureId = Renderer.TextureId(paintId)
	return
}


@(require_results)
removeTexture :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	textureId: Renderer.TextureId,
	location := #caller_location,
) -> (
	paintCopy: Renderer.Paint(Renderer.Texture(TShapeName), TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintCopy = removePaint(module, textureId, Renderer.Texture(TShapeName)) or_return
	return
}

@(require_results)
getTexture :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	textureId: Renderer.TextureId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(module, textureId, Renderer.Texture(TShapeName), required) or_return
	return
}


@(require_results)
setTextureOffset :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	animationId: Renderer.TextureId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getPaint(module, animationId, Renderer.Texture(TShapeName), true) or_return
	meta.offset = offset
	return
}

@(require_results)
drawTexture :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	texture: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	destination: Math.Vector
	switch texture.config.positionType {
	case Renderer.PositionType.CAMERA:
		destination = texture.element.config.bounds.position + texture.offset
		updateRenderZIndexPosition(
			module,
			texture.paintId,
			texture.config.layer,
			destination,
		) or_return
	case Renderer.PositionType.MAP:
		destination =
			texture.element.config.bounds.position + texture.offset - module.camera.bounds.position
		updateRenderZIndexPosition(
			module,
			texture.paintId,
			texture.config.layer,
			texture.offset - module.camera.bounds.position,
		) or_return
	}
	bounds: Math.Rectangle = {destination, texture.element.config.bounds.size}
	if texture.element.config.zoom != 1 {
		destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
		newSize: Math.Vector = bounds.size * texture.element.config.zoom
		bounds = {destinationCenter - (newSize / 2), newSize}
	}
	destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
	shape, _ := ShapeClient.get(
		module.shapeModule,
		texture.element.config.shapeName,
		true,
	) or_return
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
