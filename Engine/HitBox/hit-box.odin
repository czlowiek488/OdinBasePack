package HitBox

import "../../Drawer/Painter"
import "../../Math"

HitBoxId :: distinct u32

HitBoxEntry :: struct($TEntityHitBoxType: typeid) {
	id:         HitBoxId,
	entityId:   EntityId,
	hitBox:     Math.Geometry,
	position:   Math.Vector, // position is absolute
	offset:     Math.Vector, // offset is relative to position
	type:       TEntityHitBoxType,
	geometryId: Painter.GeometryId,
	lineId:     Painter.LineId,
}

HitBoxEntryList :: struct($TEntityHitBoxType: typeid) {
	hitBoxEntryList: [dynamic]HitBoxEntry(TEntityHitBoxType),
}

EntityHitBox :: struct($TEntityHitBoxType: typeid) {
	entityId:   EntityId,
	present:    bool,
	hitBoxList: [TEntityHitBoxType]HitBoxEntryList(TEntityHitBoxType),
}

HitBoxCellMeta :: struct {
	rectangleId: Maybe(Painter.RectangleId),
}

EntityId :: int

HitBoxGridDrawConfig :: struct {
	color:              Painter.ColorDefinition,
	gridCell:           bool,
	gridCellConnection: bool,
	hitBox:             bool,
	enabled:            bool,
}
