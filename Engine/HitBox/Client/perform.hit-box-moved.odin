package HitBoxClient

import "../../HitBox"

@(require_results)
hitBoxMovedPerform :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	input: HitBox.HitBoxMovedEvent,
) -> (
	error: TError,
) {
	for hitBoxType in TEntityHitBoxType {
		move(module, input.entityId, hitBoxType, input.change) or_return
	}
	return
}
