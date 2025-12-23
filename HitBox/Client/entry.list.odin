package HitBoxClient

import "../../../OdinBasePack"
import "../../HitBox"
import "../../IdPicker"

@(require_results)
getHitBoxEntryList :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
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
	entityHitBox, present, err = getEntityHitBox(manager, entityId, false)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
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

@(private)
@(require_results)
removeHitBoxEntryList :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	hitBoxEntryList: ^HitBox.HitBoxEntryList(TEntityHitBoxType),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	for &hitBoxEntry in hitBoxEntryList.hitBoxEntryList {
		err = IdPicker.freeId(&manager.hitBoxIdPicker, hitBoxEntry.id)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
		removeHitBoxFromGrid(
			manager,
			&manager.gridTypeSlice[hitBoxEntry.type],
			&hitBoxEntry,
		) or_return
	}
	return
}
