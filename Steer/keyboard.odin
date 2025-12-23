package Steer

import "vendor:sdl3"

KeyboardKeyName :: enum {
	W,
	S,
	A,
	D,
	Q,
	E,
	I,
	U,
	F1,
	ESC,
	NUM_1,
	NUM_2,
	NUM_3,
	NUM_4,
	NUM_5,
	NUM_6,
	NUM_7,
	NUM_8,
	NUM_9,
	NUM_0,
	SHIFT,
	CTRL,
}
KeyboardKeyMap :: map[KeyboardKeyName]SteerButton

Keyboard :: struct {
	keyMap:  KeyboardKeyMap,
	mapping: map[sdl3.Keycode]KeyboardKeyName,
}

KeyboardEvent :: struct {
	name:   KeyboardKeyName,
	button: SteerButton,
}
