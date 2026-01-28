package RendererClient

import "../../../OdinBasePack"
import "../../Memory/Dictionary"
import "../../Memory/List"
import "../../Memory/Timer"
import "../../Renderer"


@(require_results)
getStatic :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	name: int,
) -> (
	animation: Renderer.PainterAnimation(TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "name = {}", name)
	animation = module.animationMap[name]
	config, configOk := animation.config.(Renderer.PainterAnimationConfig(TShapeName))
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
	animation: Renderer.PainterAnimation(TShapeName),
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
	animation: ^Renderer.PainterAnimation($TShapeName),
) -> (
	duration: Timer.Time,
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Renderer.PainterAnimationConfig(TShapeName):
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
	animation: ^Renderer.PainterAnimation($TShapeName),
) -> (
	shapeName: union {
		TShapeName,
		string,
	},
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Renderer.PainterAnimationConfig(TShapeName):
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
