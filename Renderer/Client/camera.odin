package RendererClient

import "../../../OdinBasePack"
import "../../Math"

@(require_results)
updateCamera :: proc(
	module: ^Module($TImageName, $TBitmapName),
	position: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	module.camera.bounds.position = position
	return
}
