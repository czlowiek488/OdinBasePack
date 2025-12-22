package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import ShapeClient "../../Shape/Client"

@(require_results)
createTexture :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.TextureConfig(TShapeName),
	location := #caller_location,
) -> (
	textureId: Renderer.TextureId,
	paint: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(
		manager,
		metaConfig,
		Renderer.Texture(TShapeName){0, config},
	) or_return
	textureId = Renderer.TextureId(paintId)
	return
}


@(require_results)
removeTexture :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	textureId: Renderer.TextureId,
	location := #caller_location,
) -> (
	paintCopy: Renderer.Paint(Renderer.Texture(TShapeName), TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintCopy = removePaint(manager, textureId, Renderer.Texture(TShapeName)) or_return
	return
}

@(require_results)
getTexture :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	textureId: Renderer.TextureId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName, TAnimationName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(manager, textureId, Renderer.Texture(TShapeName), required) or_return
	return
}


@(require_results)
setTextureOffset :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animationId: Renderer.TextureId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getPaint(manager, animationId, Renderer.Texture(TShapeName), true) or_return
	meta.offset = offset
	return
}

@(require_results)
drawTexture :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	texture: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName, TAnimationName),
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
			texture.element.config.bounds.position +
			texture.offset -
			manager.camera.bounds.position
	}
	bounds: Math.Rectangle = {destination, texture.element.config.bounds.size}
	if texture.element.config.zoom != 1 {
		destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
		newSize: Math.Vector = bounds.size * texture.element.config.zoom
		bounds = {destinationCenter - (newSize / 2), newSize}
	}
	destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
	shape, _ := ShapeClient.get(
		manager.shapeManager,
		texture.element.config.shapeName,
		true,
	) or_return
	drawTextureBacked(
		manager,
		shape.texture,
		&shape.bounds,
		&bounds,
		bounds.size / 2,
		texture.config.color,
		shape.direction,
		texture.element.config.rotation,
	) or_return

	return
}
