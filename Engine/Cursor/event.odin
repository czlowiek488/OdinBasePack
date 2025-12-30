package Cursor

CursorEvent :: union($TAnimationName: typeid) {
	AnimationChangedEvent(TAnimationName),
	ChangedEvent,
	CreatedEvent,
}
