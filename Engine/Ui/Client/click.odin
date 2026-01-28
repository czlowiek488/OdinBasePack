package UiClient

import "../../../../OdinBasePack"
import "../../../Memory/AutoSet"
import "../../../Memory/SparseSet"
import "../../HitBox"
import "../../Steer"
import "../../Ui"
import "core:log"

@(require_results)
mouseButtonUp :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	button: Steer.MouseButtonName,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if _, ok := module.click.button.?; !ok {
		return
	}
	module.click.button = nil
	module.click.move = {0, 0}
	id, ok := module.click.id.?
	if !ok {
		return
	}
	module.click.id = nil
	switch value in id {
	case Ui.TileId:
		tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError)
		tileOk: bool
		tile, tileOk, err = AutoSet.get(module.tileAS, value, false)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		if !tileOk {
			return
		}
		ctx := module.eventLoop->ctx() or_return
		scheduleCameraCallback(module, tile, Ui.TileClick{false, ctx.startedAt, button}) or_return
	case HitBox.EntityId:
		tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
		tileOk: bool
		tile, tileOk, err = SparseSet.get(module.tileSS, value, false)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		if !tileOk {
			return
		}
		ctx := module.eventLoop->ctx() or_return
		scheduleMapCallback(module, tile, Ui.TileClick{false, ctx.startedAt, button}) or_return
	}
	return
}

@(require_results)
mouseButtonDown :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TError, $TEntityHitBoxType),
	button: Steer.MouseButtonName,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if _, ok := module.click.button.?; ok {
		return
	}
	module.click.button = button
	if hoveredTile, ok := module.hoveredTile.?; ok {
		module.click.id = hoveredTile.tileId
		tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError)
		tile, _, err = AutoSet.get(module.tileAS, hoveredTile.tileId, true)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		ctx := module.eventLoop->ctx() or_return
		scheduleCameraCallback(module, tile, Ui.TileClick{true, ctx.startedAt, button}) or_return
		return
	}
	if entityId, ok := module.hoveredEntityId.?; ok {
		module.click.id = entityId
		tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
		tile, _, err = SparseSet.get(module.tileSS, entityId, true)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		ctx := module.eventLoop->ctx() or_return
		scheduleMapCallback(module, tile, Ui.TileClick{true, ctx.startedAt, button}) or_return
		return
	}
	return
}
