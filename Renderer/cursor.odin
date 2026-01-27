package Renderer

import "vendor:sdl3"

State :: enum {
	REGULAR,
	SEARCH,
	HARVEST,
}

Shift :: enum {
	REGULAR,
	LEFT_BUTTON_CLICKED,
	RIGHT_BUTTON_CLICKED,
	BOTH_BUTTON_CLICKED,
}

CursorConfig :: struct($TShapeName: typeid) {
	maybeText: Maybe(string),
	shapeName: TShapeName,
}

CursorDataElement :: struct {
	cursor:      ^sdl3.Cursor,
	cursorBoxed: ^sdl3.Cursor,
}

CursorData :: struct($TShapeName: typeid) {
	shifts: [Shift]CursorDataElement,
	config: CursorConfig(TShapeName),
}
