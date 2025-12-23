package HitBox

import "../Math"

HitBoxMovedEvent :: struct {
	entityId: EntityId,
	change:   Math.Vector,
}
