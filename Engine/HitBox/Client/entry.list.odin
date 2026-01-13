package HitBoxClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/IdPicker"
import "../../HitBox"

@(require_results)
getHitBoxEntryList :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	required: bool,
) -> (
	hitBoxEntryList: ^[dynamic]HitBox.HitBoxEntry(TEntityHitBoxType),
	present: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, present, err = getEntityHitBox(module, entityId, false)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if !present {
		if required {
			error = .HIT_BOX_ENTITY_MUST_BE_PRESENT
		}
		return
	}
	hitBox := &entityHitBox.hitBoxList[type]
	hitBoxEntryList = &hitBox.hitBoxEntryList
	if hitBoxEntryList == nil {
		error = .ARRAY_NOT_EXISTS
		return
	}
	return
}

@(require_results)
getHitBoxBounds :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
) -> (
	bounds: Math.Rectangle,
	error: TError,
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	hitBoxEntryList: ^HitBox.HitBoxEntryList(TEntityHitBoxType),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	for &hitBoxEntry in hitBoxEntryList.hitBoxEntryList {
		err = IdPicker.freeId(&module.hitBoxIdPicker, hitBoxEntry.id)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		removeHitBoxFromGrid(
			module,
			&module.gridTypeSlice[hitBoxEntry.type],
			&hitBoxEntry,
		) or_return
	}
	return
}
