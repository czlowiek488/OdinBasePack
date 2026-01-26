package PainterClient

import "../../../OdinBasePack"
import "../../Memory/Dictionary"
import "../../Memory/Timer"
import "../../Painter"


@(require_results)
getStatic :: proc(
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
	name: TAnimationName,
) -> (
	animation: Painter.PainterAnimation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "name = {}", name)
	animation = module.animationMap[name]
	config, configOk := animation.config.(Painter.PainterAnimationConfig(
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
	name: string,
) -> (
	animation: Painter.PainterAnimation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	animation = module.dynamicAnimationMap[name]
	for element in animation.config.(Painter.DynamicAnimationConfig).frameList {
		animation.totalDuration += element.duration
	}
	return
}

@(require_results)
createAnimation :: proc(
	config: Painter.PainterAnimationConfig($TShapeName, $TAnimationName),
) -> (
	animation: Painter.PainterAnimation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
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
	return
}

@(require_results)
createDynamicAnimation :: proc(
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
	config: Painter.DynamicAnimationConfig,
) -> (
	animation: Painter.PainterAnimation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
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
	return
}

@(require_results)
loadDynamicAnimation :: proc(
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
	animationName: string,
	dynamicAnimationConfig: Painter.DynamicAnimationConfig,
) -> (
	error: OdinBasePack.Error,
) {
	animation := createDynamicAnimation(module, dynamicAnimationConfig) or_return
	Dictionary.set(
		&module.dynamicAnimationMap,
		animationName,
		Painter.PainterAnimation(TShapeName, TAnimationName)(animation),
	) or_return
	return
}

@(require_results)
getCurrentFrameDuration :: proc(
	animation: ^Painter.PainterAnimation($TShapeName, $TAnimationName),
) -> (
	duration: Timer.Time,
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Painter.PainterAnimationConfig(TShapeName, TAnimationName):
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
	case Painter.DynamicAnimationConfig:
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
	animation: ^Painter.PainterAnimation($TShapeName, $TAnimationName),
) -> (
	shapeName: union {
		TShapeName,
		string,
	},
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Painter.PainterAnimationConfig(TShapeName, TAnimationName):
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
	case Painter.DynamicAnimationConfig:
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
) -> (
	error: OdinBasePack.Error,
) {
	for animationName, animationConfig in module.config.animations {
		Dictionary.set(
			&module.animationMap,
			animationName,
			createAnimation(animationConfig) or_return,
		) or_return
	}
	module.created = true
	return
}
