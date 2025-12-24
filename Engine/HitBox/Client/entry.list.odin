package HitBoxClient

import "../../../../OdinBasePack"
import "../../../Memory/IdPicker"
import "../../HitBox"

@(require_results)
getHitBoxEntryList :: proc(
	module: ^Module(
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

@(private)
@(require_results)
removeHitBoxEntryList :: proc(
	module: ^Module(
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
