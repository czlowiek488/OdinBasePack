package RendererClient

import "../../../OdinBasePack"
import "../../Memory/Dictionary"
import "../../Memory/List"
import "../../Memory/Timer"
import "../../Renderer"


@(require_results)
getStatic :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	name: TAnimationName,
) -> (
	animation: Renderer.PainterAnimation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "name = {}", name)
	animation = module.animationMap[name]
	config, configOk := animation.config.(Renderer.PainterAnimationConfig(
		TShapeName,
		TAnimationName,
	))
	if !configOk {
		error = .ANIMATION_FRAME_MUST_EXIST
		return
	}
	for element in config.frameList {
		animation.totalDuration += element.duration
	}
	return
}
@(require_results)
getDynamic :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	name: string,
) -> (
	animation: Renderer.PainterAnimation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	animation = module.dynamicAnimationMap[name]
	for element in animation.config.(Renderer.DynamicAnimationConfig).frameList {
		animation.totalDuration += element.duration
	}
	return
}

@(require_results)
getCurrentFrameDuration :: proc(
	animation: ^Renderer.PainterAnimation($TShapeName, $TAnimationName),
) -> (
	duration: Timer.Time,
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Renderer.PainterAnimationConfig(TShapeName, TAnimationName):
		frameListLength := len(config.frameList)
		if frameListLength == 0 {
			error = .ANIMATION_FRAME_LIST_EMPTY
			return
		} else if frameListLength <= animation.currentFrameIndex {
			error = .ANIMATION_FRAME_MUST_EXIST
			return
		}
		frame := &config.frameList[animation.currentFrameIndex]
		duration = frame.duration
	case Renderer.DynamicAnimationConfig:
		frameListLength := len(config.frameList)
		if frameListLength == 0 {
			error = .ANIMATION_FRAME_LIST_EMPTY
			return
		} else if frameListLength <= animation.currentFrameIndex {
			error = .ANIMATION_FRAME_MUST_EXIST
			return
		}
		frame := &config.frameList[animation.currentFrameIndex]
		duration = frame.duration
	}
	return
}

@(require_results)
getCurrentFrameShapeName :: proc(
	animation: ^Renderer.PainterAnimation($TShapeName, $TAnimationName),
) -> (
	shapeName: union {
		TShapeName,
		string,
	},
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Renderer.PainterAnimationConfig(TShapeName, TAnimationName):
		frameListLength := len(config.frameList)
		if frameListLength == 0 {
			error = .ANIMATION_FRAME_LIST_EMPTY
			return
		} else if frameListLength <= animation.currentFrameIndex {
			error = .ANIMATION_FRAME_MUST_EXIST
			return
		}
		frame := &config.frameList[animation.currentFrameIndex]
		shapeName = frame.shapeName
	case Renderer.DynamicAnimationConfig:
		frameListLength := len(config.frameList)
		if frameListLength == 0 {
			error = .ANIMATION_FRAME_LIST_EMPTY
			return
		} else if frameListLength <= animation.currentFrameIndex {
			error = .ANIMATION_FRAME_MUST_EXIST
			return
		}
		frame := &config.frameList[animation.currentFrameIndex]
		shapeName = frame.shapeName
	}
	return
}

@(require_results)
loadAnimations :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	for animationName, config in module.config.animations {
		animation: Renderer.PainterAnimation(TShapeName, TAnimationName)
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
		Dictionary.set(&module.animationMap, animationName, animation) or_return
	}
	module.created = true
	return
}
