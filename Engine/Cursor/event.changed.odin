package Cursor

ChangedEvent :: struct {
	nextState:  State,
	withText:   bool,
	customText: Maybe(string),
}
