package UiClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory"
import "../../../Memory/AutoSet"
import "../../../Memory/List"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import "../../../Renderer"
import RendererClient "../../../Renderer/Client"
import "../../HitBox"
import HitBoxClient "../../HitBox/Client"
import SteerClient "../../Steer/Client"
import TimeClient "../../Time/Client"
import "../../Ui"
import "core:log"


@(private)
@(require_results)
getCurrentTileColor :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError),
) -> (
	color: Ui.Color,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	switch v in tile.config.renderConfig {
	case Renderer.AnimationConfig:
		animation, _ := RendererClient.getAnimation(
			module.rendererModule,
			Renderer.AnimationId(tile.painterRenderId),
			true,
		) or_return
		color = animation.config.metaConfig.color
	case Renderer.RectangleConfig:
		meta, _ := RendererClient.getRectangle(
			module.rendererModule,
			Renderer.RectangleId(tile.painterRenderId),
			true,
		) or_return
		color = meta.config.color
	}
	return
}


@(private)
@(require_results)
setCurrentTileColor :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError),
	color: Renderer.ColorDefinition,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	switch v in tile.config.renderConfig {
	case Renderer.AnimationConfig:
		animation: ^Renderer.Animation(TShapeName)
		animation, _, err = RendererClient.getAnimation(
			module.rendererModule,
			Renderer.AnimationId(tile.painterRenderId),
			true,
		)
		module.eventLoop.mapper(err) or_return
		copied := animation^
		err := RendererClient.removeAnimation(
			module.rendererModule,
			Renderer.AnimationId(tile.painterRenderId),
		)
		module.eventLoop.mapper(err) or_return
		copied.config.metaConfig.color = color
		animationId: Renderer.AnimationId
		animationId, err = RendererClient.setAnimation(module.rendererModule, copied.config)
		module.eventLoop.mapper(err) or_return
		tile.painterRenderId = Ui.PainterRenderId(animationId)
	case Renderer.RectangleConfig:
		meta, _, err := RendererClient.getRectangle(
			module.rendererModule,
			Renderer.RectangleId(tile.painterRenderId),
			true,
		)
		module.eventLoop.mapper(err) or_return
		meta.config.color = color
	case Renderer.CircleConfig:
		meta, _, err := RendererClient.getCircle(
			module.rendererModule,
			Renderer.CircleId(tile.painterRenderId),
			true,
		)
		module.eventLoop.mapper(err) or_return
		meta.config.color = color
	}
	return
}


@(require_results)
setCameraTileColor :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
	tileId: Ui.TileId,
	color: Renderer.ColorDefinition,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError)
	tile, _, err = AutoSet.get(module.tileAS, tileId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	setCurrentTileColor(module, tile, color) or_return
	return
}

@(require_results)
handleMouseMotion :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
	change: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	clickedId, ok := module.click.id.?
	if !ok {
		return
	}
	module.click.move += change
	tileOk: bool
	switch v in clickedId {
	case Ui.TileId:
		tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError)
		tile, tileOk, err = AutoSet.get(module.tileAS, v, false)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		if !tileOk {
			return
		}
		scheduleCameraCallback(module, tile, Ui.TileMoved{module.click.move, change}) or_return
	case HitBox.EntityId:
		tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
		tile, tileOk, err = SparseSet.get(module.tileSS, v, false)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		if !tileOk {
			return
		}
		scheduleMapCallback(module, tile, Ui.TileMoved{module.click.move, change}) or_return
	}
	return
}

@(require_results)
setCameraTileOffset :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
	tileId: Ui.TileId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError)
	tile, _, err = AutoSet.get(module.tileAS, tileId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	switch v in tile.config.renderConfig {
	case Renderer.AnimationConfig:
		err := RendererClient.setAnimationOffset(
			module.rendererModule,
			Renderer.AnimationId(tile.painterRenderId),
			offset,
		)
		module.eventLoop.mapper(err) or_return
	case Renderer.RectangleConfig:
		err := RendererClient.setRectangleOffset(
			module.rendererModule,
			Renderer.RectangleId(tile.painterRenderId),
			offset,
		)
		module.eventLoop.mapper(err) or_return
	case Renderer.CircleConfig:
		err := RendererClient.setCircleOffset(
			module.rendererModule,
			Renderer.CircleId(tile.painterRenderId),
			offset,
		)
		module.eventLoop.mapper(err) or_return
	}
	_, _, err = SpatialGrid.removeFromGrid(&module.tileGrid, tileId, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	geometry, scaledGeometry := getBoundsFromTileRenderConfig(
		module,
		tile.config.renderConfig,
		offset,
	)
	tile.scaledGeometry = scaledGeometry
	tile.geometry = geometry
	if ASSURE_NO_OVERLAPPING_UI {
		assureNoOverlapping(
			module,
			tile.scaledGeometry,
			tile.config.metaConfig.zIndex,
			tile.config.metaConfig.layer,
		) or_return // TODO add bulk movement AND actually assure no overlap!
	}
	_, err = SpatialGrid.insertEntry(
		&module.tileGrid,
		tile.scaledGeometry,
		tileId,
		Ui.TileGridEntry{tile.config.metaConfig.zIndex, tile.config.metaConfig.layer},
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
tick :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	mousePositionOnScreen := SteerClient.getMousePositionOnScreen(module.steerModule) or_return
	cameraEntries: map[Ui.TileId]Ui.TileGridEntry
	cameraEntries, err = SpatialGrid.query(
		&module.tileGrid,
		Math.Circle{mousePositionOnScreen, .5},
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if len(cameraEntries) == 0 {
		endCameraHover(module) or_return
	} else {
		highestZIndex: Renderer.ZIndex = -1
		highestTileId: Ui.TileId
		highestLayerId: Renderer.LayerId
		for tileId, entry in cameraEntries {
			if entry.layer > highestLayerId {
				highestLayerId = entry.layer
				highestZIndex = entry.zIndex
				highestTileId = tileId
				continue
			}
			if entry.layer != highestLayerId {
				continue
			}
			if entry.zIndex == highestZIndex {
				defer OdinBasePack.handleError(
					err,
					"highestZIndex = {} - entry = {}",
					highestZIndex,
					entry,
				)
				err = .UI_TILES_MUST_NOT_OVERLAP
				error = module.eventLoop.mapper(err)
				return
			}
			if entry.zIndex > highestZIndex {
				highestZIndex = entry.zIndex
				highestTileId = tileId
			}
		}
		startCameraHover(module, highestTileId) or_return
	}
	if hoveredTileId, ok := module.hoveredTile.?; ok {
		return
	}
	hoveredEntityId := getCurrentHoveredEntityId(module) or_return
	if entityId, ok := hoveredEntityId.?; ok {
		startMapHover(module, entityId) or_return
		return
	}
	endMapHover(module) or_return
	return
}


@(private = "file")
@(require_results)
getCurrentHoveredEntityId :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TEntityHitBoxType,
	),
) -> (
	entityId: Maybe(HitBox.EntityId),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hoveredEntityList: [dynamic]HitBox.EntityId
	hoveredEntityList, err = List.create(HitBox.EntityId, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	mousePositionOnMap := SteerClient.getMousePositionOnMap(module.steerModule) or_return
	uiMapTile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	ok: bool
	for hitBoxType in module.hitBoxes {
		mapEntries := HitBoxClient.queryEntitiesInRange(
			module.hitBoxModule,
			hitBoxType,
			mousePositionOnMap,
			1,
		) or_return
		for entry in mapEntries {
			uiMapTile, ok, err = SparseSet.get(module.tileSS, entry.entityId, false)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
			if ok {
				if module.hoveredEntityId == entry.entityId {
					entityId = entry.entityId
					return
				}
				err = List.push(&hoveredEntityList, entry.entityId)
				if err != .NONE {
					error = module.eventLoop.mapper(err)
					return
				}
			}
		}
	}
	if len(hoveredEntityList) > 0 {
		entityId = hoveredEntityList[0]
	}
	return
}
