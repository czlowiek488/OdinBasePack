package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Animation"
import AnimationClient "../../Animation/Client"
import "../../Renderer"
import ShapeClient "../../Shape/Client"
import "vendor:sdl3"

@(require_results)
drawAnimation :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animation: ^Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "animation = {}", animation.element.animation)
	if animation.element.animation.frameListLength == 0 {
		error = .ANIMATION_FRAME_LIST_EMPTY
		return
	}
	destination: Math.Vector
	switch animation.config.positionType {
	case Renderer.PositionType.CAMERA:
		destination = animation.element.config.bounds.position + animation.offset
	case Renderer.PositionType.MAP:
		destination =
			animation.element.config.bounds.position +
			animation.offset -
			manager.camera.bounds.position
	}
	bounds: Math.Rectangle = {destination, animation.element.config.bounds.size}
	destinationCenter: Math.Vector = Math.getRectangleCenter(bounds)
	switch value in &animation.element.animation.config {
	case Animation.DynamicAnimationConfig:
		frame := &value.frameList[animation.element.animation.currentFrameIndex]
		shape, _ := ShapeClient.get(manager.shapeManager, frame.shapeName, true) or_return
		if animation.element.config.zoom != 1 {
			newSize: Math.Vector = bounds.size * animation.element.config.zoom
			newDestination: Math.Rectangle = {destinationCenter - (newSize / 2), newSize}
			drawTexture(
				manager,
				shape.texture,
				&shape.bounds,
				&newDestination,
				newSize / 2,
				animation.config.color,
				shape.direction,
				animation.element.config.rotation,
			) or_return
		} else {
			drawTexture(
				manager,
				shape.texture,
				&shape.bounds,
				&bounds,
				bounds.size / 2,
				animation.config.color,
				shape.direction,
				animation.element.config.rotation,
			) or_return
		}
	case Animation.AnimationConfig(TShapeName, TAnimationName):
		frame := &value.frameList[animation.element.animation.currentFrameIndex]
		shape, _ := ShapeClient.get(manager.shapeManager, frame.shapeName, true) or_return
		if animation.element.config.zoom != 1 {
			newSize: Math.Vector = bounds.size * animation.element.config.zoom
			newDestination: Math.Rectangle = {
				{destinationCenter.x - (newSize.x / 2), destinationCenter.y - (newSize.y / 2)},
				{newSize.x, newSize.y},
			}
			drawTexture(
				manager,
				shape.texture,
				&shape.bounds,
				&newDestination,
				newSize / 2,
				animation.config.color,
				shape.direction,
				animation.element.config.rotation,
			) or_return
		} else {
			drawTexture(
				manager,
				shape.texture,
				&shape.bounds,
				&bounds,
				bounds.size / 2,
				animation.config.color,
				shape.direction,
				animation.element.config.rotation,
			) or_return
		}
	}

	return
}

@(require_results)
setAnimationOffset :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animationId: Renderer.AnimationId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getPaint(
		manager,
		animationId,
		Renderer.Animation(TShapeName, TAnimationName),
		true,
	) or_return
	meta.offset = offset
	return
}

@(require_results)
setAnimation :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.AnimationConfig(TShapeName, TAnimationName),
	location := #caller_location,
) -> (
	animationId: Renderer.AnimationId,
	paint: ^Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	animation: Animation.Animation(TShapeName, TAnimationName)
	switch animationName in config.animationName {
	case TAnimationName:
		animation = AnimationClient.getStatic(manager.animationManager, animationName) or_return
	case string:
		animation = AnimationClient.getDynamic(manager.animationManager, animationName) or_return
	}
	paintId, paint = createPaint(
		manager,
		metaConfig,
		Renderer.Animation(TShapeName, TAnimationName){0, config, nil, animation},
	) or_return
	animationId = Renderer.AnimationId(paintId)
	return
}

@(require_results)
removeAnimation :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animationId: Renderer.AnimationId,
	location := #caller_location,
) -> (
	paintCopy: Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint, _ := getAnimation(manager, animationId, true) or_return
	paintCopy = removePaint(
		manager,
		animationId,
		Renderer.Animation(TShapeName, TAnimationName),
	) or_return
	return
}

@(require_results)
getAnimation :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animationId: Renderer.AnimationId,
	required: bool,
) -> (
	result: ^Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(
		manager,
		animationId,
		Renderer.Animation(TShapeName, TAnimationName),
		required,
	) or_return
	return
}
