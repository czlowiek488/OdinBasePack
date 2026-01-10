package CursorClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Engine/Cursor"
import "../../../Math"
import SteerClient "../../Steer/Client"

@(private)
@(require_results)
getAnimationPosition :: proc(
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
	size: Math.Vector,
) -> (
	position: Math.Vector,
	error: TError,
) {
	position = SteerClient.getMousePositionOnMap(module.steerModule) or_return
	position -= size / 2
	return
}

@(private)
@(require_results)
showAnimation :: proc(
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
	data: Cursor.AnimationChangedEventData(TAnimationName),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	animationId := PainterClient.setAnimation(
		module.painterModule,
		Painter.AnimationConfig(TAnimationName) {
			data.name,
			0,
			1,
			{{0, 0}, data.size},
			{.PANEL_3, 0, nil, .MAP, {.WHITE, 1, 1, nil}},
		},
	) or_return
	PainterClient.setAnimationOffset(
		module.painterModule,
		animationId,
		getAnimationPosition(module, data.size) or_return,
	) or_return
	module.cursorState.animationId = animationId
	return
}

@(private)
@(require_results)
hideAnimation :: proc(
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
	error: TError,
) {
	if animationId, present := module.cursorState.animationId.?; present {
		PainterClient.removeAnimation(module.painterModule, animationId) or_return
		module.cursorState.animationId = nil
	} else {
		error = module.eventLoop.mapper(.CURSOR_ANIMATION_ALREADY_REMOVED)
	}
	return
}
