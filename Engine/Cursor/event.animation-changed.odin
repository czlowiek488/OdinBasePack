package Cursor

import "../../Math"

AnimationChangedEventData :: struct($TAnimationName: typeid) {
	name: TAnimationName,
	size: Math.Vector,
}

AnimationChangedEvent :: struct($TAnimationName: typeid) {
	data: Maybe(AnimationChangedEventData(TAnimationName)),
}
