package UiClient

import "../../../OdinBasePack"
import "../../AutoSet"
import "../../Math"
import "../../SpatialGrid"
import "../../Ui"


@(require_results)
createCameraTile :: proc(
	manager: ^Manager(
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
	bounds := getBoundsFromTileRenderConfig(manager, config.renderConfig)
	scaledBounds := Math.scaleBounds(bounds, manager.tileScale, {0, 0})
	entries: map[Ui.TileId]Ui.TileGridEntry
	entries, err = SpatialGrid.query(&manager.tileGrid, scaledBounds, context.temp_allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if len(entries) > 0 {
		error = .UI_CANNOT_CREATE_TILE_THAT_OVERLAPS
		return
	}
	painterRenderId, originalColor := setPainterRender(manager, config) or_return
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tileId, tile, err = AutoSet.set(
		manager.tileAS,
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
		error = manager.eventLoop.mapper(err)
		return
	}
	tile.tileId = tileId
	_, err = SpatialGrid.insertEntry(
		&manager.tileGrid,
		tile.scaledBounds,
		tileId,
		Ui.TileGridEntry{},
		context.temp_allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeCameraTile :: proc(
	manager: ^Manager(
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
	tile, _, err = AutoSet.get(manager.tileAS, tileId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if hoveredTile, ok := manager.hoveredTile.?; ok {
		if tileId == hoveredTile.tileId {
			endCameraHover(manager) or_return
		}
	}
	unsetPainterRender(manager, tile) or_return
	_, _, err = SpatialGrid.removeFromGrid(&manager.tileGrid, tileId, context.temp_allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = AutoSet.remove(manager.tileAS, tile.tileId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(private)
@(require_results)
endCameraHover :: proc(
	manager: ^Manager(
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
	hoveredTile, hovered := manager.hoveredTile.?
	if !hovered {
		return
	}
	manager.hoveredTile = nil
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tile, _, err = AutoSet.get(manager.tileAS, hoveredTile.tileId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if _, ok := tile.config.hoverConfig.?; ok {
		setCurrentTileColor(manager, tile, tile.originalColor) or_return
	}
	scheduleCameraCallback(manager, tile, Ui.TileHover{false}) or_return
	return
}

@(private)
@(require_results)
startCameraHover :: proc(
	manager: ^Manager(
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
	if hoveredTile, ok := manager.hoveredTile.?; ok {
		if tileId == hoveredTile.tileId {
			return
		}
		endCameraHover(manager) or_return
	}
	if hoveredEntityId, ok := manager.hoveredEntityId.?; ok {
		endMapHover(manager) or_return
	}
	ctx := manager.eventLoop->ctx() or_return
	manager.hoveredTile = HoveredTile{tileId, ctx.startedAt}
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
	tile, _, err = AutoSet.get(manager.tileAS, tileId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if hoverConfig, ok := tile.config.hoverConfig.?; ok {
		setCurrentTileColor(manager, tile, hoverConfig.color) or_return
	}
	scheduleCameraCallback(manager, tile, Ui.TileHover{true}) or_return
	return
}

@(private)
@(require_results)
scheduleCameraCallback :: proc(
	manager: ^Manager(
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
	tile.config.onEvent(manager.eventLoop, tile^, event) or_return
	return
}
