package HitBoxClient

import "../../../../OdinBasePack"
import "../../../Memory/List"
import "../../../Memory/SparseSet"
import "../../HitBox"

@(require_results)
removeEntity :: proc(
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
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, _, err = getEntityHitBox(module, entityId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	for &hitBoxEntryList, type in entityHitBox.hitBoxList {
		removeHitBoxEntryList(module, &hitBoxEntryList) or_return
		err = List.destroy(hitBoxEntryList.hitBoxEntryList, module.allocator)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	err = SparseSet.remove(module.entityHitBoxSS, entityId)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getEntityList :: proc(
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
) -> (
	entityHitBoxList: ^[dynamic]HitBox.EntityHitBox(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	entityHitBoxList, err = SparseSet.list(module.entityHitBoxSS)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
