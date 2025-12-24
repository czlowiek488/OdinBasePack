package HitBoxClient

import "../../../Math"
import "../../HitBox"

@(require_results)
getAbsoluteHitBox :: proc(
	hitBoxEntry: ^HitBox.HitBoxEntry($TEntityHitBoxType),
) -> (
	hitBox: Math.Geometry,
) {
	hitBox = hitBoxEntry.hitBox
	Math.moveGeometry(&hitBox, hitBoxEntry.offset + hitBoxEntry.position)
	return
}
