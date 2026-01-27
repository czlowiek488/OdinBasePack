package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/Dictionary"
import "../../Memory/Timer"
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
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animation, _ = AutoSet.get(module.animationAS, animationId, true) or_return
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
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "config = {}", config)
	anim: Painter.PainterAnimation(TShapeName, TAnimationName)
	switch animationName in config.animationName {
	case TAnimationName:
		anim = getStatic(module, animationName) or_return
	case string:
		anim = getDynamic(module, animationName) or_return
	}
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animationId, animation = AutoSet.set(
		module.animationAS,
		Painter.Animation(TShapeName, TAnimationName){0, config, 0, nil, {0, 0}, anim},
	) or_return
	animation.animationId = animationId
	shapeName: union {
		TShapeName,
		string,
	}
	duration: Timer.Time
	switch value in animation.animation.config {
	case Painter.PainterAnimationConfig(TShapeName, TAnimationName):
		frame := &value.frameList[0]
		duration = frame.duration
		shapeName = frame.shapeName
	case Painter.DynamicAnimationConfig:
		frame := &value.frameList[0]
		duration = frame.duration
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
	Dictionary.set(&module.multiFrameAnimations, animation.animationId, duration) or_return
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
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animation: ^Painter.Animation(TShapeName, TAnimationName)
	animation, _ = AutoSet.get(module.animationAS, animationId, true) or_return
	if !animation.animation.infinite {
		Dictionary.remove(&module.multiFrameAnimations, animation.animationId) or_return
	}
	removeTexture(module, animation.currentTextureId) or_return
	AutoSet.remove(module.animationAS, animationId) or_return
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	animation, ok = AutoSet.get(module.animationAS, animationId, required) or_return
	return
}

@(require_results)
tickAnimation :: proc(
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
	time: Timer.Time,
) -> (
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.Error
	for animationId, &animationTime in module.multiFrameAnimations {
		animationTime -= time
		if animationTime > 0 {
			continue
		}
		animation, _ := getAnimation(module, animationId, true) or_return
		animation.animation.currentFrameIndex += 1
		if animation.animation.frameListLength <= animation.animation.currentFrameIndex {
			animation.animation.currentFrameIndex = 0
		}
		shapeName: union {
			TShapeName,
			string,
		}
		duration: Timer.Time
		switch value in animation.animation.config {
		case Painter.PainterAnimationConfig(TShapeName, TAnimationName):
			frame := &value.frameList[animation.animation.currentFrameIndex]
			shapeName = frame.shapeName
			duration = frame.duration
		case Painter.DynamicAnimationConfig:
			frame := &value.frameList[animation.animation.currentFrameIndex]
			shapeName = frame.shapeName
			duration = frame.duration
		}
		texture, _ := getTexture(module, animation.currentTextureId, true) or_return
		texture.element.config.shapeName = shapeName
		animationTime = duration + animationTime
	}
	return
}
