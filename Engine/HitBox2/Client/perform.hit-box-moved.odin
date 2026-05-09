package HitBox3Client2

import "../../../../OdinBasePack"
import HitBox "../../HitBox2"

@(require_results)
hitBoxMovedPerform :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	input: HitBox.HitBoxMovedEvent,
) -> (
	error: OdinBasePack.Error,
) {
	for hitBoxType in TEntityHitBoxType {
		move(module, input.entityId, hitBoxType, input.change) or_return
	}
	return
}
