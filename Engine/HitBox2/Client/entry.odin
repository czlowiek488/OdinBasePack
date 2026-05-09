package HitBox3Client2

import "../../../Math"
import HitBox "../../HitBox2"

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
