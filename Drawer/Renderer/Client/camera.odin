package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"

@(require_results)
updateCamera :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	position: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	manager.camera.bounds.position = position
	return
}
