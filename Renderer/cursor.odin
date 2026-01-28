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

CursorConfig :: struct {
	maybeText: Maybe(string),
	shapeName: int,
}

CursorDataElement :: struct {
	cursor:      ^sdl3.Cursor,
	cursorBoxed: ^sdl3.Cursor,
}

CursorData :: struct {
	shifts: [Shift]CursorDataElement,
	config: CursorConfig,
}
