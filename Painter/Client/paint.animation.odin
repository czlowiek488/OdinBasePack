package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
setAnimationOffset :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Painter.AnimationId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animation, _, err = AutoSet.get(module.animationAS, animationId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	animation.offset = offset
	setTextureOffset(module, animation.currentTextureId, offset) or_return
	return
}

@(require_results)
setAnimation :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	config: Painter.AnimationConfig(TAnimationName),
) -> (
	animationId: Painter.AnimationId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "config = {}", config)
	anim: Painter.PainterAnimation(TShapeName, TAnimationName)
	switch animationName in config.animationName {
	case TAnimationName:
		anim, err = getStatic(module, animationName)
	case string:
		anim, err = getDynamic(module, animationName)
	}
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animationId, animation, err = AutoSet.set(
		module.animationAS,
		Painter.Animation(TShapeName, TAnimationName){0, config, 0, nil, {0, 0}, anim},
	)
	animation.animationId = animationId
	shapeName: union {
		TShapeName,
		string,
	}
	switch value in animation.animation.config {
	case Painter.PainterAnimationConfig(TShapeName, TAnimationName):
		frame := &value.frameList[0]
		shapeName = frame.shapeName
	case Painter.DynamicAnimationConfig:
		frame := &value.frameList[0]
		shapeName = frame.shapeName
	}
	animation.currentTextureId = createTexture(
		module,
		config.metaConfig,
		Renderer.TextureConfig(TShapeName) {
			shapeName,
			config.rotation,
			config.zoom,
			config.bounds,
			config.staticShift,
		},
	) or_return
	if animation.animation.infinite {
		return
	}
	switch value in animation.animation.config {
	case Painter.PainterAnimationConfig(TShapeName, TAnimationName):
		animation.timeoutId = module.eventLoop->task(
			.TIMEOUT,
			value.frameList[0].duration,
			Painter.PainterEvent(
				Painter.AnimationFrameFinishedEvent{animationId, config.metaConfig.layer},
			),
		) or_return
	case Painter.DynamicAnimationConfig:
		animation.timeoutId = module.eventLoop->task(
			.TIMEOUT,
			value.frameList[0].duration,
			Painter.PainterEvent(
				Painter.AnimationFrameFinishedEvent{animationId, config.metaConfig.layer},
			),
		) or_return
	}
	return
}

@(require_results)
removeAnimation :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Painter.AnimationId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animation, _, err = AutoSet.get(module.animationAS, animationId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if timeoutId, ok := animation.timeoutId.?; ok {
		_ = module.eventLoop->unSchedule(timeoutId, true) or_return
	}
	removeTexture(module, animation.currentTextureId) or_return
	err = AutoSet.remove(module.animationAS, animationId)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getAnimation :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Painter.AnimationId,
	required: bool,
) -> (
	animation: ^Painter.Animation(TShapeName, TAnimationName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation, ok, err = AutoSet.get(module.animationAS, animationId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
