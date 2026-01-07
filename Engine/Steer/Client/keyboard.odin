package SteerClient

import "../../../../OdinBasePack"
import "../../../Memory/Dictionary"
import "../../Steer"
import "core:log"
import "vendor:sdl3"

@(private)
@(require_results)
loadKeyboardMapping :: proc(
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
	mapping: [Steer.KeyboardKeyName]sdl3.Keycode,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.steer.keyboard.mapping = Dictionary.create(
		sdl3.Keycode,
		Steer.KeyboardKeyName,
		module.allocator,
	) or_return
	for keycode, name in mapping {
		Dictionary.set(&module.steer.keyboard.mapping, keycode, name) or_return
	}
	return
}

@(require_results)
handleKeyboardSDLEvent :: proc(
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
	keyId: sdl3.Keycode,
	event: Steer.KeyEvent,
) -> (
	keyboardEvent: Steer.KeyboardEvent,
	found: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	keyboardEvent.name, found = module.steer.keyboard.mapping[keyId]
	if !found {
		if module.keyboard do log.infof("Button Pressed - {} > {}", event, keyId)
		return
	}
	if module.keyboard do log.infof("Button Pressed - {} > {} > {}", event, keyId, keyboardEvent.name)
	switch event {
	case .INVALID:
		error = .INVALID_ENUM_VALUE
		return
	case .PRESSED:
		keyboardEvent.button.pressed = true
	case .RELEASED:
		keyboardEvent.button.released = true
	}
	module.steer.keyboard.keyMap[keyboardEvent.name] = keyboardEvent.button
	return
}
