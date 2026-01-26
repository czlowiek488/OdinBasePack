package PainterClient

import "../../../OdinBasePack"
import "../../Memory/List"
import "../../Memory/SparseSet"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
entitiesMovedPerform :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	input: Painter.EntitiesMovedEvent,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	paint: ^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName)
	tracker: ^Tracker
	ok: bool
	for index in 0 ..< input.count {
		tracker, ok, err = SparseSet.get(module.trackedEntities, input.list[index].entityId, false)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		if ok {
			tracker.position = input.list[index].newPosition
			for paintId in tracker.hooks {
				paint, _, err = RendererClient.getPaint(
					module.rendererModule,
					paintId,
					Renderer.PaintData(TShapeName),
					true,
				)
				if err != .NONE {
					error = module.eventLoop.mapper(err)
					return
				}
				paint.offset = tracker.position
			}
			continue
		}
		list: [dynamic]Renderer.PaintId
		list, err = List.create(Renderer.PaintId, module.allocator)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		err = SparseSet.set(
			module.trackedEntities,
			input.list[index].entityId,
			Tracker{input.list[index].newPosition, list},
		)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	return
}
