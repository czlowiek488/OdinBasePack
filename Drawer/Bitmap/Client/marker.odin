package BitmapClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/Dictionary"

@(require_results)
findShapeMarkerMap :: proc(
	module: ^Module($TBitmapName, $TMarkerName),
	maybeBitmapName: Maybe(TBitmapName),
	bounds: Math.Rectangle,
) -> (
	markerVectorMap: map[TMarkerName]Math.Vector,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	markerVectorMap = Dictionary.create(TMarkerName, Math.Vector, module.allocator) or_return
	bitmapName, ok := maybeBitmapName.?
	if !ok {
		return
	}
	for id, vectorList in module.bitmapMap[bitmapName].pixelColorListMap {
		for vector in vectorList {
			if Math.isPointCollidingWithRectangle(bounds, vector) {
				_, markerExists := markerVectorMap[id]
				if markerExists {
					error = .BITMAP_DUPLICATED_MARKER
					return
				}
				Dictionary.set(&markerVectorMap, id, vector - bounds.position) or_return
			}
		}
	}
	return
}
