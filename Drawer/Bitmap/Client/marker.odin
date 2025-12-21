package BitmapClient

import "../../../../OdinBasePack"
import "../../../Dictionary"
import "../../../Math"

@(require_results)
findShapeMarkerMap :: proc(
	manager: ^Manager($TBitmapName, $TMarkerName),
	maybeBitmapName: Maybe(TBitmapName),
	bounds: Math.Rectangle,
) -> (
	markerVectorMap: map[TMarkerName]Math.Vector,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	markerVectorMap = Dictionary.create(TMarkerName, Math.Vector, manager.allocator) or_return
	bitmapName, ok := maybeBitmapName.?
	if !ok {
		return
	}
	for id, vectorList in manager.bitmapMap[bitmapName].pixelColorListMap {
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
