package HitBox3Client2

import "../../../../OdinBasePack"
import HitBox "../../HitBox2"

@(require_results)
hitBoxesRequestedPerform :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	event: HitBox.HitBoxesRequestedEvent(TEntityHitBoxType),
) -> (
	error: OdinBasePack.Error,
) {
	for hitBoxId, meta in module.gridTypeSlice[event.type].entries {
		module.eventLoop->microTask(
			HitBox.HitBoxEvent(TEntityHitBoxType)(
			HitBox.HitBoxCreatedEvent(TEntityHitBoxType){hitBoxId, event.type, meta.geometry},
			),
		) or_return
	}
	return
}
