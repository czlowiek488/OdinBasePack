package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Animation"
import AnimationClient "../../Animation/Client"
import "../../Renderer"
import ShapeClient "../../Shape/Client"
import "vendor:sdl3"

@(require_results)
setAnimationOffset :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animationId: Renderer.AnimationId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	animation, _ := getPaint(
		manager,
		animationId,
		Renderer.Animation(TShapeName, TAnimationName),
		true,
	) or_return
	animation.offset = offset
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
	shapeName: union {
		TShapeName,
		string,
	}
	switch value in animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
		frame := &value.frameList[0]
		shapeName = frame.shapeName
	case Animation.DynamicAnimationConfig:
		frame := &value.frameList[0]
		shapeName = frame.shapeName
	}
	paintId, paint = createPaint(
		manager,
		metaConfig,
		Renderer.Animation(TShapeName, TAnimationName){0, config, 0, nil, animation},
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
