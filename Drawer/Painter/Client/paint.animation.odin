package PainterClient

import "../../../../OdinBasePack"
import "../../../AutoSet"
import "../../../Math"
import "../../Animation"
import AnimationClient "../../Animation/Client"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
setAnimationOffset :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Renderer.AnimationId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setAnimationOffset(manager.rendererManager, animationId, offset)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animation, _, err = AutoSet.get(manager.animationAS, animationId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	setTextureOffset(manager, animation.currentTextureId, offset) or_return
	return
}

@(require_results)
setAnimation :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.AnimationConfig(TShapeName, TAnimationName),
) -> (
	animationId: Renderer.AnimationId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	anim: Animation.Animation(TShapeName, TAnimationName)
	switch animationName in config.animationName {
	case TAnimationName:
		anim, err = AnimationClient.getStatic(manager.animationManager, animationName)
	case string:
		anim, err = AnimationClient.getDynamic(manager.animationManager, animationName)
	}
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animationId, animation, err = AutoSet.set(
		manager.animationAS,
		Painter.Animation(TShapeName, TAnimationName) {
			0,
			{
				config.animationName,
				config.rotation,
				config.zoom,
				config.bounds,
				metaConfig.layer,
				metaConfig.attachedEntityId,
				metaConfig.positionType,
				metaConfig.color,
			},
			0,
			nil,
			anim,
		},
	)
	animation.animationId = animationId
	shapeName: union {
		TShapeName,
		string,
	}
	switch value in animation.animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
		frame := &value.frameList[0]
		shapeName = frame.shapeName
	case Animation.DynamicAnimationConfig:
		frame := &value.frameList[0]
		shapeName = frame.shapeName
	}
	animation.currentTextureId = createTexture(
		manager,
		metaConfig,
		Renderer.TextureConfig(TShapeName){shapeName, config.rotation, config.zoom, config.bounds},
	) or_return
	if animation.animation.infinite {
		return
	}
	switch value in animation.animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
		animation.timeoutId = manager.eventLoop->task(
			.TIMEOUT,
			value.frameList[0].duration,
			Painter.PainterEvent(
				Painter.AnimationFrameFinishedEvent{animationId, metaConfig.layer},
			),
		) or_return
	case Animation.DynamicAnimationConfig:
		animation.timeoutId = manager.eventLoop->task(
			.TIMEOUT,
			value.frameList[0].duration,
			Painter.PainterEvent(
				Painter.AnimationFrameFinishedEvent{animationId, metaConfig.layer},
			),
		) or_return
	}
	return
}

@(require_results)
removeAnimation :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Renderer.AnimationId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animation, _, err = AutoSet.get(manager.animationAS, animationId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if timeoutId, ok := animation.timeoutId.?; ok {
		_ = manager.eventLoop->unSchedule(timeoutId, true) or_return
	}
	removeTexture(manager, animation.currentTextureId) or_return
	err = AutoSet.remove(manager.animationAS, animationId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getAnimation :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Renderer.AnimationId,
	required: bool,
) -> (
	animation: ^Painter.Animation(TShapeName, TAnimationName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation, ok, err = AutoSet.get(manager.animationAS, animationId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
