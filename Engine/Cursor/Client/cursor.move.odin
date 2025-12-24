package CursorClient

import PainterClient "../../../Drawer/Painter/Client"
import "../../../Math"

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
	mousePositionOnMap: Math.Vector,
) -> (
	error: TError,
) {
	hideAxises(module) or_return
	showAxises(module, mousePositionOnMap / module.config.tileScale) or_return
	textId, textIdPresent := module.textId.?
	if !textIdPresent {
		return
	}
	str, _ := PainterClient.getString(module.painterModule, textId, true) or_return
	str.element.config.bounds.position = getStrPosition(module) or_return
	return
}
