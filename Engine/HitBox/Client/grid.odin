package HitBoxClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../../Memory/List"
import "../../../Memory/SpatialGrid"
import "../../HitBox"
import "core:slice"


@(private = "file")
filterHitBoxEntrySliceUniquelyById :: proc(
	hitBoxEntrySlice: []HitBox.HitBoxEntry($TEntityHitBoxType),
) -> []HitBox.HitBoxEntry(TEntityHitBoxType) {
	return slice.unique_proc(
		hitBoxEntrySlice,
		proc(a, b: HitBox.HitBoxEntry(TEntityHitBoxType)) -> bool {
			return a.id == b.id
		},
	)
}

@(require_results)
@(private = "file")
filterHitBoxEntrySliceUniquelyByEntityId :: proc(
	hitBoxEntrySlice: []HitBox.HitBoxEntry($TEntityHitBoxType),
) -> (
	filtered: [dynamic]HitBox.HitBoxEntry(TEntityHitBoxType),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	filtered = List.create(HitBox.HitBoxEntry(TEntityHitBoxType), context.temp_allocator) or_return
	containerEntityIdList := List.create(HitBox.EntityId, context.temp_allocator) or_return
	for hitBoxEntry in hitBoxEntrySlice {
		exists: bool
		for entityId in containerEntityIdList {
			if hitBoxEntry.entityId == entityId {
				exists = true
				break
			}
		}
		if exists {
			continue
		}
		List.push(&containerEntityIdList, hitBoxEntry.entityId) or_return
		List.push(&filtered, hitBoxEntry) or_return
	}
	return
}

@(private)
@(require_results)
queryNearByHitBox :: proc(
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
	type: TEntityHitBoxType,
	hitBox: Math.Geometry,
	logs: bool,
) -> (
	hitBoxEntrySlice: []HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	center := Math.getGeometryCenter(hitBox)
	grid := &module.gridTypeSlice[type]
	result := queryInRange(module, grid, center, f32(grid.config.cellSize)) or_return
	hitBoxEntrySlice, err = Dictionary.getValues(result, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
@(private = "package")
@(require_results)
queryEntitiesNearEntity :: proc(
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
	entityId: HitBox.EntityId,
	entityType, selectType: TEntityHitBoxType,
) -> (
	hitBoxEntryList: [dynamic]HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, _, err = getEntityHitBox(module, entityId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	queryResult := queryNearByEntity(
		module,
		entityHitBox,
		entityType,
		selectType,
		context.temp_allocator,
	) or_return
	if len(queryResult) == 0 {
		hitBoxEntryList, err = List.create(
			HitBox.HitBoxEntry(TEntityHitBoxType),
			context.temp_allocator,
		)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		return
	}
	hitBoxEntryList, err = filterHitBoxEntrySliceUniquelyByEntityId(queryResult)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(private = "file")
isEntityHitBoxPairColliding :: proc(
	entityHitBoxA, entityHitBoxB: ^HitBox.EntityHitBox($TEntityHitBoxType),
) -> (
	result: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for hitBoxEntryListA in entityHitBoxA.hitBoxList {
		for &hitBoxEntryA in hitBoxEntryListA.hitBoxEntryList {
			for hitBoxEntryListB in entityHitBoxB.hitBoxList {
				for &hitBoxEntryB in hitBoxEntryListB.hitBoxEntryList {
					absA := getAbsoluteHitBox(&hitBoxEntryA)
					absB := getAbsoluteHitBox(&hitBoxEntryB)
					if Math.isCollidingGeometryGeometry(absA, absB) {
						result = true
						return
					}
				}
			}
		}
	}
	return
}

@(require_results)
queryHitBoxEntries :: proc(
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
	entityId: HitBox.EntityId,
	entityType: TEntityHitBoxType,
	selectType: TEntityHitBoxType,
	colliding: bool,
) -> (
	nearEntityIdSlice: []HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	nearEntityIdSlice = queryHitBoxEntriesImplementation(
		module,
		entityId,
		entityType,
		selectType,
		colliding,
	) or_return
	return
}

@(require_results)
queryHitBoxEntriesImplementation :: proc(
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
	entityId: HitBox.EntityId,
	entityType: TEntityHitBoxType,
	selectType: TEntityHitBoxType,
	colliding: bool,
) -> (
	nearEntityIdSlice: []HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(
		err,
		"entityId = {} - entityType = {} - selectType = {} - colliding = {}",
		entityId,
		entityType,
		selectType,
		colliding,
	)
	hitBoxEntryList := queryEntitiesNearEntity(module, entityId, entityType, selectType) or_return
	entityHitBoxB: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBoxB, _, err = getEntityHitBox(module, entityId, true)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	nearEntityIdList: [dynamic]HitBox.HitBoxEntry(TEntityHitBoxType)
	nearEntityIdList, err = List.create(
		HitBox.HitBoxEntry(TEntityHitBoxType),
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if colliding {
		entityHitBoxA: ^HitBox.EntityHitBox(TEntityHitBoxType)
		#reverse for &hitBoxEntry, index in hitBoxEntryList {
			entityHitBoxA, _, err = getEntityHitBox(module, hitBoxEntry.entityId, true)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
			isColliding: bool
			isColliding, err = isEntityHitBoxPairColliding(entityHitBoxA, entityHitBoxB)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
			if isColliding {
				err = List.push(&nearEntityIdList, hitBoxEntry)
				if err != .NONE {
					error = module.eventLoop.mapper(err)
					return
				}
			}
		}
	} else {
		for &hitBoxEntry in hitBoxEntryList {
			err = List.push(&nearEntityIdList, hitBoxEntry)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
		}
	}
	nearEntityIdSlice = nearEntityIdList[:]
	return
}
@(private)
@(require_results)
queryNearByEntity :: proc(
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
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType),
	entityType, selectType: TEntityHitBoxType,
	allocator: OdinBasePack.Allocator,
) -> (
	hitBoxEntrySlice: []HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hitBoxEntryList: [dynamic]HitBox.HitBoxEntry(TEntityHitBoxType)
	hitBoxEntryList, err = List.create(HitBox.HitBoxEntry(TEntityHitBoxType), allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	for &hitBoxEntry in entityHitBox.hitBoxList[entityType].hitBoxEntryList {
		abs := getAbsoluteHitBox(&hitBoxEntry)
		singleCollisionList := queryNearByHitBox(module, selectType, abs, true) or_return
		err = List.push(&hitBoxEntryList, ..singleCollisionList[:])
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	hitBoxEntrySlice = filterHitBoxEntrySliceUniquelyById(hitBoxEntryList[:])
	return
}

@(require_results)
queryEntitiesInRange :: proc(
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
	selectType: TEntityHitBoxType,
	pos: Math.Vector,
	range: f32,
) -> (
	hitBoxEntryList: [dynamic]HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	queryResult := queryInRangeEntity(module, selectType, pos, range) or_return
	if len(queryResult) == 0 {
		hitBoxEntryList, err = List.create(
			HitBox.HitBoxEntry(TEntityHitBoxType),
			context.temp_allocator,
		)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		return
	}
	hitBoxEntryList, err = filterHitBoxEntrySliceUniquelyByEntityId(queryResult)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(private)
@(require_results)
queryInRangeEntity :: proc(
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
	selectType: TEntityHitBoxType,
	pos: Math.Vector,
	range: f32,
) -> (
	hitBoxEntryList: []HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	result := queryInRange(module, &module.gridTypeSlice[selectType], pos, range) or_return
	values, err := Dictionary.getValues(result, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	hitBoxEntryList = filterHitBoxEntrySliceUniquelyById(values)
	return
}


@(private)
@(require_results)
queryInRange :: proc(
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
	grid: ^SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	pos: Math.Vector,
	range: f32,
) -> (
	hitBoxEntryList: map[HitBox.HitBoxId]HitBox.HitBoxEntry(TEntityHitBoxType),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hitBoxEntryList, err = SpatialGrid.query(grid, Math.Circle{pos, range}, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}


@(require_results)
getGridHitBoxEntry :: proc(
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
	type: TEntityHitBoxType,
) -> (
	result: ^map[SpatialGrid.CellId]SpatialGrid.Cell(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	grid := &module.gridTypeSlice[type]
	result = &grid.cells
	return
}
