package Cursor

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

CursorData :: struct($TShapeName: typeid) {
	cursor: ^sdl3.Cursor,
	config: CursorConfig(TShapeName),
}
