package UiClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/SpatialGrid"
import "../../Ui"


@(require_results)
createCameraTile :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	config: Ui.CameraTileConfig(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
) -> (
	tileId: Ui.TileId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	bounds := getBoundsFromTileRenderConfig(module, config.renderConfig)
	scaledBounds := Math.scaleBounds(bounds, module.tileScale, {0, 0})
	entries: map[Ui.TileId]Ui.TileGridEntry
	entries, err = SpatialGrid.query(&module.tileGrid, scaledBounds, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if len(entries) > 0 {
		error = .UI_CANNOT_CREATE_TILE_THAT_OVERLAPS
		return
	}
	painterRenderId, originalColor := setPainterRender(module, config) or_return
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tileId, tile, err = AutoSet.set(
		module.tileAS,
		Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName) {
			0,
			config,
			painterRenderId,
			bounds,
			scaledBounds,
			originalColor,
		},
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	tile.tileId = tileId
	_, err = SpatialGrid.insertEntry(
		&module.tileGrid,
		tile.scaledBounds,
		tileId,
		Ui.TileGridEntry{},
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeCameraTile :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	tileId: Ui.TileId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tile, _, err = AutoSet.get(module.tileAS, tileId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if hoveredTile, ok := module.hoveredTile.?; ok {
		if tileId == hoveredTile.tileId {
			endCameraHover(module) or_return
		}
	}
	unsetPainterRender(module, tile) or_return
	_, _, err = SpatialGrid.removeFromGrid(&module.tileGrid, tileId, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = AutoSet.remove(module.tileAS, tile.tileId)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(private)
@(require_results)
endCameraHover :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hoveredTile, hovered := module.hoveredTile.?
	if !hovered {
		return
	}
	module.hoveredTile = nil
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tile, _, err = AutoSet.get(module.tileAS, hoveredTile.tileId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if _, ok := tile.config.hoverConfig.?; ok {
		setCurrentTileColor(module, tile, tile.originalColor) or_return
	}
	scheduleCameraCallback(module, tile, Ui.TileHover{false}) or_return
	return
}

@(private)
@(require_results)
startCameraHover :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	tileId: Ui.TileId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if hoveredTile, ok := module.hoveredTile.?; ok {
		if tileId == hoveredTile.tileId {
			return
		}
		endCameraHover(module) or_return
	}
	if hoveredEntityId, ok := module.hoveredEntityId.?; ok {
		endMapHover(module) or_return
	}
	ctx := module.eventLoop->ctx() or_return
	module.hoveredTile = HoveredTile{tileId, ctx.startedAt}
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tile, _, err = AutoSet.get(module.tileAS, tileId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if hoverConfig, ok := tile.config.hoverConfig.?; ok {
		setCurrentTileColor(module, tile, hoverConfig.color) or_return
	}
	scheduleCameraCallback(module, tile, Ui.TileHover{true}) or_return
	return
}

@(private)
@(require_results)
scheduleCameraCallback :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
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
