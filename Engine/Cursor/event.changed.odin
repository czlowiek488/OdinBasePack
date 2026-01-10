package Cursor

import "../../Drawer/Painter"

ChangedEvent :: struct {
	nextState:  Painter.State,
	withText:   bool,
	customText: Maybe(string),
}
