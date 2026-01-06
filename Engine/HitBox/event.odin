package HitBox

HitBoxEvent :: union($TEntityHitBoxType: typeid) {
	HitBoxMovedEvent,
	HitBoxCreatedEvent(TEntityHitBoxType),
	HitBoxesRequestedEvent(TEntityHitBoxType),
	HitBoxRemovedEvent,
}
