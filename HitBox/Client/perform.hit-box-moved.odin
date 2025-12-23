package HitBoxClient

import "../../../OdinBasePack"
import "../../HitBox"

@(require_results)
hitBoxMovedPerform :: proc(
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
	input: HitBox.HitBoxMovedEvent,
) -> (
	error: TError,
) {
	for hitBoxType in TEntityHitBoxType {
		move(manager, input.entityId, hitBoxType, input.change) or_return
	}
	return
}
