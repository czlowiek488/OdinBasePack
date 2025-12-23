package HitBoxClient

import "../../HitBox"
import "../../Math"

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
