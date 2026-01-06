package HitBoxClient

import "../../HitBox"

@(require_results)
hitBoxesRequestedPerform :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	event: HitBox.HitBoxesRequestedEvent(TEntityHitBoxType),
) -> (
	error: TError,
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
