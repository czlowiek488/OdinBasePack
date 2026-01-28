package RendererClient

import "../../../OdinBasePack"
import "../../Memory/Dictionary"
import "../../Memory/List"
import "../../Memory/Timer"
import "../../Renderer"

@(require_results)
registerDynamicAnimation :: proc(
	module: ^Module($TImageName, $TBitmapName),
	animationName: string,
	config: Renderer.DynamicAnimationConfig,
) -> (
	error: OdinBasePack.Error,
) {
	animation: Renderer.PainterAnimation
	animation.frameListLength = len(config.frameList)
	if animation.frameListLength == 0 {
		error = .ANIMATION_FRAME_MUST_EXIST
		return
	}
	animation.config = config
	if config.frameList[0].duration != 0 {
		for frame in config.frameList {
			animation.duration += frame.duration
		}
	} else {
		animation.infinite = true
	}
	animation.created = true
	Dictionary.set(
		&module.dynamicAnimationMap,
		animationName,
		Renderer.PainterAnimation(animation),
	) or_return
	return
}

@(require_results)
registerStaticAnimation :: proc(
	module: ^Module($TImageName, $TBitmapName),
	config: Renderer.PainterAnimationConfig,
) -> (
	error: OdinBasePack.Error,
) {
	animation: Renderer.PainterAnimation
	animation.frameListLength = len(config.frameList)
	if animation.frameListLength == 0 {
		error = .ANIMATION_FRAME_MUST_EXIST
		return
	}
	animation.config = config
	if config.frameList[0].duration != 0 {
		for frame in config.frameList {
			animation.duration += frame.duration
		}
	} else {
		animation.infinite = true
	}
	animation.created = true
	Dictionary.set(&module.animationMap, config.animationName, animation) or_return
	module.created = true
	return
}
