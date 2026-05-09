package HitBox3

import "../../Math"

HitBoxMovedEvent :: struct {
	entityId: EntityId,
	change:   Math.Vector,
}
