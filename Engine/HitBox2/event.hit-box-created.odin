package HitBox3

import "../../Math"

HitBoxCreatedEvent :: struct($TEntityHitBoxType: typeid) {
	hitBoxId: HitBoxId,
	type:     TEntityHitBoxType,
	geometry: Math.Geometry,
}
