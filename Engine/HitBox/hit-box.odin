package HitBox

import "../../Math"

HitBoxId :: distinct u32

HitBoxEntry :: struct($TEntityHitBoxType: typeid) {
	id:       HitBoxId,
	entityId: EntityId,
	hitBox:   Math.Geometry,
	position: Math.Vector, // position is absolute
	offset:   Math.Vector, // offset is relative to position
	type:     TEntityHitBoxType,
}

HitBoxEntryList :: struct($TEntityHitBoxType: typeid) {
	hitBoxEntryList: [dynamic]HitBoxEntry(TEntityHitBoxType),
}

EntityHitBox :: struct($TEntityHitBoxType: typeid) {
	entityId:   EntityId,
	present:    bool,
	hitBoxList: [TEntityHitBoxType]HitBoxEntryList(TEntityHitBoxType),
}

HitBoxCellMeta :: struct {}

EntityId :: int
