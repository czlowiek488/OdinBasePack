package Platform

import "../../Math"
import "../Steer"

PlatformEvent :: union {
	QuitPlatformEvent,
	MouseMotionPlatformEvent,
	MouseButtonPlatformEvent,
	MouseWheelPlatformEvent,
	KeyboardButtonPlatformEvent,
}
QuitPlatformEvent :: struct {}
MouseMotionPlatformEvent :: struct {
	position: Math.Vector,
	change:   Math.Vector,
}


ClickTarget :: enum {
	MAP,
	UI,
}

MouseButtonPlatformEvent :: struct {
	buttonName: Steer.MouseButtonName,
	down:       bool,
}
MouseWheelPlatformEvent :: struct {
	change: f32,
}
KeyboardButtonPlatformEvent :: struct {
	keyboardEvent: Steer.KeyboardEvent,
	down:          bool,
}
