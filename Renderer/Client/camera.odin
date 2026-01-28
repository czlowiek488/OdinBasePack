package RendererClient

import "../../../OdinBasePack"
import "../../Math"

@(require_results)
updateCamera :: proc(module: ^Module, position: Math.Vector) -> (error: OdinBasePack.Error) {
	module.camera.bounds.position = position
	return
}
