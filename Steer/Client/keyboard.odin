package SteerClient

import "../../../OdinBasePack"
import "../../Dictionary"
import "../../Steer"
import "core:log"
import "vendor:sdl3"

@(private)
@(require_results)
loadKeyboardMapping :: proc(
	manager: ^Manager(
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
	manager.steer.keyboard.mapping = Dictionary.create(
		sdl3.Keycode,
		Steer.KeyboardKeyName,
		manager.allocator,
	) or_return
	for keycode, name in mapping {
		Dictionary.set(&manager.steer.keyboard.mapping, keycode, name) or_return
	}
	return
}

@(require_results)
handleKeyboardSDLEvent :: proc(
	manager: ^Manager(
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
	keyboardEvent.name, found = manager.steer.keyboard.mapping[keyId]
	if !found {
		if manager.config.logPressedKey do log.info("Button Pressed - {} > {}", event, keyId)
		return
	}
	if manager.config.logPressedKey do log.info("Button Pressed - {} > {} > {}", event, keyId, keyboardEvent.name)
	switch event {
	case .INVALID:
		error = .INVALID_ENUM_VALUE
		return
	case .PRESSED:
		keyboardEvent.button.pressed = true
	case .RELEASED:
		keyboardEvent.button.released = true
	}
	manager.steer.keyboard.keyMap[keyboardEvent.name] = keyboardEvent.button
	return
}
