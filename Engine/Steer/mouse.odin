package Steer

import "../../Math"
import "vendor:sdl3"

MouseButtonName :: enum {
	LEFT,
	RIGHT,
}

KeyCode :: sdl3.Keycode

KeyEvent :: enum u8 {
	INVALID,
	PRESSED,
	RELEASED,
}

Mouse :: struct {
	positionOnScreen: Math.Vector,
	positionOnMap:    Math.Vector,
	delta:            Math.Vector,
	inWindow:         bool,
	wheelY:           f32,
	buttonMap:        map[MouseButtonName]SteerButton,
}
