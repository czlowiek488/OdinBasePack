package HitBox3Client2

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/IdPicker"
import HitBox "../../HitBox2"

@(require_results)
getHitBoxEntryList :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	required: bool,
) -> (
	hitBoxEntryList: ^[dynamic]HitBox.HitBoxEntry(TEntityHitBoxType),
	present: bool,
	error: OdinBasePack.Error,
) {
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, present = getEntityHitBox(module, entityId, false) or_return
	if !present {
		if required {
			error = OdinBasePack.Error.HIT_BOX_ENTITY_MUST_BE_PRESENT
		}
		return
	}
	hitBox := &entityHitBox.hitBoxList[type]
	hitBoxEntryList = &hitBox.hitBoxEntryList
	if hitBoxEntryList == nil {
		error = OdinBasePack.Error.ARRAY_NOT_EXISTS
		return
	}
	return
}

@(require_results)
getHitBoxBounds :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
) -> (
	bounds: Math.Rectangle,
	error: OdinBasePack.Error,
) {
	min, max: Math.Vector
	entryList, _ := getHitBoxEntryList(module, entityId, type, true) or_return
	for &entry in entryList {
		geometry := getAbsoluteHitBox(&entry)
		minAbs, maxAbs := Math.getGeometryAABB(geometry)
		if min == {0, 0} && max == {0, 0} {
			min = minAbs
			max = maxAbs
		}
		if minAbs.x < min.x {
			min.x = minAbs.x
		}
		if maxAbs.x > max.x {
			max.x = maxAbs.x
		}
		if minAbs.y < min.y {
			min.y = minAbs.y
		}
		if maxAbs.y > max.y {
			max.y = maxAbs.y
		}
	}
	bounds = {min, max - min}
	return
}

@(private)
@(require_results)
removeHitBoxEntryList :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	hitBoxEntryList: ^HitBox.HitBoxEntryList(TEntityHitBoxType),
) -> (
	error: OdinBasePack.Error,
) {
	for &hitBoxEntry in hitBoxEntryList.hitBoxEntryList {
		IdPicker.freeId(module.hitBoxIdPicker, hitBoxEntry.id) or_return
		removeHitBoxFromGrid(
			module,
			&module.gridTypeSlice[hitBoxEntry.type],
			&hitBoxEntry,
		) or_return
	}
	return
}
