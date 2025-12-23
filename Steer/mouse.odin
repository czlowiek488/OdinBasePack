package Steer

import "../Math"

MouseButtonName :: enum {
	LEFT,
	RIGHT,
}

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
