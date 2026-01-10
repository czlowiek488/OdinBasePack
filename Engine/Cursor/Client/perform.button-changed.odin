package CursorClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import "../../../Math"
import "../../Steer"

@(require_results)
handleMouseClick :: proc(
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
	buttonName: Steer.MouseButtonName,
	keyEvent: Steer.KeyEvent,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "buttonName = {} - keyEvent = {}", buttonName, keyEvent)
	direction: f32
	switch keyEvent {
	case .INVALID:
		error = .INVALID_ENUM_VALUE
		return
	case .PRESSED:
		direction = 1
	case .RELEASED:
		direction = -1
	}
	change: Math.Vector
	switch buttonName {
	case .LEFT:
		change = {2, 1}
	case .RIGHT:
		change = {-2, 1}
	}
	switch getCursorOffset(module.shift) + (change * direction) {
	case {0, 0}:
		changeShift(module, .REGULAR) or_return
	case {-2, 1}:
		changeShift(module, .LEFT_BUTTON_CLICKED) or_return
	case {2, 1}:
		changeShift(module, .RIGHT_BUTTON_CLICKED) or_return
	case {0, 2}:
		changeShift(module, .BOTH_BUTTON_CLICKED) or_return
	case:
		error = .CURSOR_INVALID_OFFSET
	}
	return
}

@(require_results)
changeShift :: proc(
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
	shift: Painter.Shift,
) -> (
	error: TError,
) {
	module.shift = shift
	changeCursor(module, module.state, module.showText, module.customText) or_return
	return
}
