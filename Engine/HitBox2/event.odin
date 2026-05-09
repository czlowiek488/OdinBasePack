package HitBox3

HitBoxEvent :: union($TEntityHitBoxType: typeid) {
	HitBoxMovedEvent,
	HitBoxCreatedEvent(TEntityHitBoxType),
	HitBoxesRequestedEvent(TEntityHitBoxType),
	HitBoxRemovedEvent,
}
