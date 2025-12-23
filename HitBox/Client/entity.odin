package HitBoxClient

import "../../../OdinBasePack"
import "../../HitBox"
import "../../List"
import "../../SparseSet"

@(require_results)
removeEntity :: proc(
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
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, _, err = getEntityHitBox(manager, entityId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	for &hitBoxEntryList, type in entityHitBox.hitBoxList {
		removeHitBoxEntryList(manager, &hitBoxEntryList) or_return
		err = List.destroy(hitBoxEntryList.hitBoxEntryList, manager.allocator)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
	}
	err = SparseSet.remove(manager.entityHitBoxSS, entityId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getEntityList :: proc(
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
) -> (
	entityHitBoxList: ^[dynamic]HitBox.EntityHitBox(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	entityHitBoxList, err = SparseSet.list(manager.entityHitBoxSS)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
