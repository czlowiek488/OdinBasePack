package BasePackSpatialGrid

import "../../OdinBasePack"
import "../Dictionary"
import "../List"
import "../Math"
import "core:math"

CellId :: distinct u64
CellSize :: distinct u32

GridConfig :: struct {
	cellSize:  CellSize,
	allocator: OdinBasePack.Allocator,
}

Cell :: struct($TEntryId, $TEntry, $TCellMeta: typeid) {
	entries:  map[TEntryId]TEntry,
	position: Math.Vector,
	meta:     TCellMeta,
}

EntryMeta :: struct {
	cellIdList: [dynamic]CellId,
	geometry:   Math.Geometry,
}

Grid :: struct($TEntryId, $TEntry, $TCellMeta: typeid) {
	config:  GridConfig,
	cells:   map[CellId]Cell(TEntryId, TEntry, TCellMeta),
	entries: map[TEntryId]EntryMeta,
}

@(require_results)
create :: proc(
	$GridType: typeid/Grid($TEntryId, $TEntry, $TCellMeta),
	config: GridConfig,
) -> (
	grid: Grid(TEntryId, TEntry, TCellMeta),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	grid.config = config
	grid.cells = Dictionary.create(
		CellId,
		Cell(TEntryId, TEntry, TCellMeta),
		config.allocator,
	) or_return
	grid.entries = Dictionary.create(TEntryId, EntryMeta, config.allocator) or_return
	return
}

@(require_results)
destroy :: proc(grid: ^Grid($TEntryId, $TEntry, $TCellMeta)) -> (error: OdinBasePack.Error) {
	if len(grid.entries) != 0 {
		error = .SPATIAL_GRID_CANNOT_BE_DESTROYED_WITH_ENTRIES_PRESENT
		return
	}
	if len(grid.cells) != 0 {
		error = .SPATIAL_GRID_CELLS_ARE_EXPECTED_TO_BE_EMPTY
		return
	}
	Dictionary.destroy(grid.cells, grid.config.allocator) or_return
	Dictionary.destroy(grid.entries, grid.config.allocator) or_return
	return
}

@(private)
@(require_results)
hashCell :: proc(x, y: int) -> CellId {
	return CellId((x * 73856093) ~ (y * 19349663))
}

@(private)
@(require_results)
worldToCell :: proc(pos: Math.Vector, cellSize: CellSize) -> (int, int) {
	return int(math.floor(pos.x / f32(cellSize))), int(math.floor(pos.y / f32(cellSize)))
}


@(private)
@(require_results)
getRelative :: proc(
	grid: ^Grid($TEntryId, $TEntry, $TCellMeta),
	pos: Math.Vector,
	min, max: Math.IntVector,
	allocator: OdinBasePack.Allocator,
) -> (
	entries: map[TEntryId]TEntry,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	entries = Dictionary.create(TEntryId, TEntry, allocator) or_return
	cx, cy := worldToCell(pos, grid.config.cellSize)
	for dy in min.y ..= max.y {
		for dx in min.x ..= max.x {
			key := hashCell(cx + dx, cy + dy)
			if cell, ok := Dictionary.get(grid.cells, key, false) or_return; ok {
				for entryId, entry in cell.entries {
					Dictionary.set(&entries, entryId, entry) or_return
				}
			}
		}
	}
	return
}

@(require_results)
insertEntry :: proc(
	grid: ^Grid($TEntryId, $TEntry, $TCellMeta),
	geometry: Math.Geometry,
	entryId: TEntryId,
	entry: TEntry,
	allocator: OdinBasePack.Allocator,
) -> (
	newCellList: [dynamic]^Cell(TEntryId, TEntry, TCellMeta),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	newCellList = List.create(^Cell(TEntryId, TEntry, TCellMeta), allocator) or_return
	min, max := Math.getGeometryAABB(geometry)
	xMin := int(math.floor(min.x / f32(grid.config.cellSize)))
	xMax := int(math.floor(max.x / f32(grid.config.cellSize)))
	yMin := int(math.floor(min.y / f32(grid.config.cellSize)))
	yMax := int(math.floor(max.y / f32(grid.config.cellSize)))
	for y in yMin ..= yMax {
		for x in xMin ..= xMax {
			cellId := hashCell(x, y)
			_, cellPresent := Dictionary.get(grid.cells, cellId, false) or_return
			if !cellPresent {
				Dictionary.set(
					&grid.cells,
					cellId,
					Cell(TEntryId, TEntry, TCellMeta) {
						Dictionary.create(TEntryId, TEntry, grid.config.allocator) or_return,
						Math.Vector{f32(x), f32(y)} * f32(grid.config.cellSize),
						TCellMeta{},
					},
				) or_return
			}
			cell, _ := Dictionary.get(grid.cells, cellId, true) or_return
			if !cellPresent {
				List.push(&newCellList, cell) or_return
			}
			_, entryPresent := Dictionary.get(grid.entries, entryId, false) or_return
			if !entryPresent {
				Dictionary.set(
					&grid.entries,
					entryId,
					EntryMeta{List.create(CellId, grid.config.allocator) or_return, geometry},
				) or_return
			}
			meta, _ := Dictionary.get(grid.entries, entryId, true) or_return
			List.push(&meta.cellIdList, cellId) or_return
			Dictionary.set(&cell.entries, entryId, entry) or_return
		}
	}
	return
}

@(require_results)
removeFromGrid :: proc(
	grid: ^Grid($TEntryId, $TEntry, $TCellMeta),
	entryId: TEntryId,
	allocator: OdinBasePack.Allocator,
) -> (
	removedEntryList: [dynamic]TEntry,
	removedCellMetaList: [dynamic]TCellMeta,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "grid = {} - entryId = {}", grid, entryId)
	removedEntryList = List.create(TEntry, allocator) or_return
	removedCellMetaList = List.create(TCellMeta, allocator) or_return
	meta, _ := Dictionary.get(grid.entries, entryId, true) or_return
	Dictionary.unset(&grid.entries, entryId) or_return
	for cellId in meta.cellIdList {
		cell, present := Dictionary.get(grid.cells, cellId, false) or_return
		if !present {
			return
		}
		for id, entry in cell.entries {
			defer OdinBasePack.handleError(error, "id = {} - entry = {}", id, entry)
			if id != entryId {
				continue
			}
			List.push(&removedEntryList, entry) or_return
			Dictionary.unset(&cell.entries, id) or_return
			if len(cell.entries) != 0 {
				break
			}
			Dictionary.destroy(cell.entries, grid.config.allocator) or_return
			List.push(&removedCellMetaList, cell.meta) or_return
			Dictionary.unset(&grid.cells, cellId) or_return
			break
		}
	}
	List.destroy(meta.cellIdList) or_return
	return
}

@(require_results)
query :: proc(
	grid: ^Grid($TEntryId, $TEntry, $TCellMeta),
	geometry: Math.Geometry,
	allocator: OdinBasePack.Allocator,
) -> (
	entries: map[TEntryId]TEntry,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "geometry = {}", geometry)
	center := Math.getGeometryCenter(geometry)
	min, max := Math.getGeometryAABB(geometry)
	minCell := (min - center) / f32(grid.config.cellSize)
	maxCell := (max - center) / f32(grid.config.cellSize)
	entries = getRelative(
		grid,
		center,
		{int(math.floor(minCell.x)), int(math.floor(minCell.y))},
		{int(math.ceil(maxCell.x)), int(math.ceil(maxCell.y))},
		allocator,
	) or_return
	for entryId, entry in entries {
		meta, _ := Dictionary.get(grid.entries, entryId, true) or_return
		if Math.isCollidingGeometryGeometry(geometry, meta.geometry) {
			continue
		}
		Dictionary.unset(&entries, entryId) or_return
	}
	return
}
