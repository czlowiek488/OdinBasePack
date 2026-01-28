package UiClient

import "../../../../OdinBasePack"
import "../../../Memory/Dictionary"
import "../../../Memory/SparseSet"
import "../../HitBox"
import "../../Ui"


@(require_results)
createMapTile :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	config: Ui.MapTileConfig(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	err = Dictionary.set(&module.hitBoxes, config.hitBox, HitBoxE{})
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = SparseSet.set(
		module.tileSS,
		config.entityId,
		Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType){config},
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeMapTile :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	tile, _, err = SparseSet.get(module.tileSS, entityId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if entityId == module.hoveredEntityId {
		endMapHover(module) or_return
	}
	err = SparseSet.remove(module.tileSS, entityId)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(private)
@(require_results)
endMapHover :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hoveredEntityId, hovered := module.hoveredEntityId.?
	if !hovered {
		return
	}
	module.hoveredEntityId = nil
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	tile, _, err = SparseSet.get(module.tileSS, hoveredEntityId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	ctx := module.eventLoop->ctx() or_return
	scheduleMapCallback(module, tile, Ui.TileHover{false, ctx.startedAt}) or_return
	return
}

@(private)
@(require_results)
startMapHover :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if hoveredEntityId, ok := module.hoveredEntityId.?; ok {
		if entityId == hoveredEntityId {
			return
		}
		endMapHover(module) or_return
	}
	module.hoveredEntityId = entityId
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	tile, _, err = SparseSet.get(module.tileSS, entityId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	ctx := module.eventLoop->ctx() or_return
	scheduleMapCallback(module, tile, Ui.TileHover{true, ctx.startedAt}) or_return
	return
}

@(private)
@(require_results)
scheduleMapCallback :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
	event: Ui.TileEvent,
) -> (
	error: TError,
) {
	if tile.config.onEvent == nil {
		return
	}
	tile.config.onEvent(module.eventLoop, tile^, event) or_return
	return
}
