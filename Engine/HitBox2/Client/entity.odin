package HitBox3Client2

import "../../../../OdinBasePack"
import "../../../Memory/List"
import "../../../Memory/SparseSet"
import HitBox "../../HitBox2"

@(require_results)
removeEntity :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
) -> (
	error: OdinBasePack.Error,
) {
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, _ = getEntityHitBox(module, entityId, true) or_return
	for &hitBoxEntryList, type in entityHitBox.hitBoxList {
		removeHitBoxEntryList(module, &hitBoxEntryList) or_return
		List.destroy(hitBoxEntryList.hitBoxEntryList, module.allocator) or_return
	}
	SparseSet.remove(module.entityHitBoxSS, entityId) or_return
	return
}

@(require_results)
getEntityList :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
) -> (
	entityHitBoxList: ^[dynamic]HitBox.EntityHitBox(TEntityHitBoxType),
	error: OdinBasePack.Error,
) {
	entityHitBoxList = SparseSet.list(module.entityHitBoxSS) or_return
	return
}
