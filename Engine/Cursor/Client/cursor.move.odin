package CursorClient

import PainterClient "../../../Drawer/Painter/Client"
import "../../../Math"
import "core:log"

@(require_results)
handleMouseMove :: proc(
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
	mousePositionOnCamera: Math.Vector,
) -> (
	error: TError,
) {
	hideAxises(module) or_return
	module.mousePositionOnCamera = mousePositionOnCamera
	showAxises(module) or_return
	if textId, ok := module.textId.?; ok {
		str, _ := PainterClient.getString(module.painterModule, textId, true) or_return
		str.element.config.bounds.position = getStrPosition(module) or_return
	}
	if animationId, ok := module.animationId.?; ok {
		animation, _ := PainterClient.getAnimation(
			module.painterModule,
			animationId,
			true,
		) or_return
		PainterClient.setAnimationOffset(
			module.painterModule,
			animationId,
			getAnimationPosition(module, animation.config.bounds.size) or_return,
		) or_return
	}
	return
}
