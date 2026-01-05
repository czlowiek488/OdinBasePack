package HitBox

import "../../Math"

HitBoxCreatedEvent :: struct($TEntityHitBoxType: typeid) {
	hitBoxId: HitBoxId,
	type:     TEntityHitBoxType,
	geometry: Math.Geometry,
}
