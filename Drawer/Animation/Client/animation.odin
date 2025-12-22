package AnimationClient

import "../../../../OdinBasePack"
import "../../../Dictionary"
import "../../../Timer"
import "../../Animation"


@(require_results)
getStatic :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	name: TAnimationName,
) -> (
	animation: Animation.Animation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	animation = manager.animationMap[name]
	for element in animation.config.(Animation.AnimationConfig(TShapeName, TAnimationName)).frameList {
		animation.totalDuration += element.duration
	}
	return
}
@(require_results)
getDynamic :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	name: string,
) -> (
	animation: Animation.Animation(TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	animation = manager.dynamicAnimationMap[name]
	for element in animation.config.(Animation.DynamicAnimationConfig).frameList {
		animation.totalDuration += element.duration
	}
	return
}

@(require_results)
createAnimation :: proc(
	config: Animation.AnimationConfig($TShapeName, $TAnimationName),
) -> (
	animation: Animation.Animation(TShapeName, TAnimationName),
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
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	config: Animation.DynamicAnimationConfig,
) -> (
	animation: Animation.Animation(TShapeName, TAnimationName),
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
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	animationName: string,
	dynamicAnimationConfig: Animation.DynamicAnimationConfig,
) -> (
	error: OdinBasePack.Error,
) {
	animation := createDynamicAnimation(manager, dynamicAnimationConfig) or_return
	Dictionary.set(
		&manager.dynamicAnimationMap,
		animationName,
		Animation.Animation(TShapeName, TAnimationName)(animation),
	) or_return
	return
}

@(require_results)
getCurrentFrameDuration :: proc(
	animation: ^Animation.Animation($TShapeName, $TAnimationName),
) -> (
	duration: Timer.Time,
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
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
	case Animation.DynamicAnimationConfig:
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
	animation: ^Animation.Animation($TShapeName, $TAnimationName),
) -> (
	shapeName: union {
		TShapeName,
		string,
	},
	error: OdinBasePack.Error,
) {
	switch config in &animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
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
	case Animation.DynamicAnimationConfig:
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
