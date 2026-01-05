package BasePackSpatialGrid

import "../../Math"
import "../List"
import "core:testing"

@(private = "file")
TestEntryId :: distinct int

@(private = "file")
TestEntry :: struct {}

@(private = "file")
TestCellMeta :: struct {}

@(private = "file")
TestSpatialGrid :: Grid(TestEntryId, TestEntry, TestCellMeta)

@(test)
gridCreation :: proc(t: ^testing.T) {
	grid, err := create(TestSpatialGrid, {100, context.allocator})
	testing.expect(t, err == .NONE)
}

@(test)
gridCreationTemporary :: proc(t: ^testing.T) {
	grid, err := create(TestSpatialGrid, {100, context.temp_allocator})
	testing.expect(t, err == .NONE)
}

@(test)
gridInsertRemoveDestroySingleCell :: proc(t: ^testing.T) {
	grid, _ := create(TestSpatialGrid, {100, context.allocator})
	newCellList, err := insertEntry(
		&grid,
		Math.Rectangle{{2, 2}, {1, 1}},
		1,
		TestEntry{},
		context.allocator,
	)
	testing.expect(t, err == .NONE)
	testing.expect_value(t, len(newCellList), 1)
	err = List.destroy(newCellList, context.allocator)
	testing.expect(t, err == .NONE)

	removedEntryList: [dynamic]TestEntry
	removedCellList: [dynamic]Cell(TestEntryId, TestEntry, TestCellMeta)
	removedEntryList, removedCellList, err = removeFromGrid(&grid, 1, context.allocator)

	testing.expect_value(t, len(removedEntryList), 1)
	testing.expect_value(t, len(removedCellList), 1)
	testing.expect(t, err == .NONE)
	err = List.destroy(removedEntryList, context.allocator)
	testing.expect(t, err == .NONE)
	err = List.destroy(removedCellList, context.allocator)
	testing.expect(t, err == .NONE)
	err = destroy(&grid)
	testing.expect(t, err == .NONE)
}

@(test)
gridInsertRemoveDestroyQuadCell :: proc(t: ^testing.T) {
	grid, _ := create(TestSpatialGrid, {100, context.allocator})
	newCellList, err := insertEntry(
		&grid,
		Math.Rectangle{{-1, -1}, {2, 2}},
		1,
		TestEntry{},
		context.allocator,
	)
	testing.expect(t, err == .NONE)
	testing.expect_value(t, len(newCellList), 4)
	err = List.destroy(newCellList, context.allocator)
	testing.expect(t, err == .NONE)

	removedEntryList: [dynamic]TestEntry
	removedCellList: [dynamic]Cell(TestEntryId, TestEntry, TestCellMeta)
	removedEntryList, removedCellList, err = removeFromGrid(&grid, 1, context.allocator)

	testing.expect_value(t, len(removedEntryList), 4)
	testing.expect_value(t, len(removedCellList), 4)
	testing.expect(t, err == .NONE)
	err = List.destroy(removedEntryList, context.allocator)
	testing.expect(t, err == .NONE)
	err = List.destroy(removedCellList, context.allocator)
	testing.expect(t, err == .NONE)
	err = destroy(&grid)
	testing.expect(t, err == .NONE)
}

@(test)
gridInsertRemoveDestroyTwoCell :: proc(t: ^testing.T) {
	grid, _ := create(TestSpatialGrid, {100, context.allocator})
	newCellList, err := insertEntry(
		&grid,
		Math.Rectangle{{-1, 0}, {2, 1}},
		1,
		TestEntry{},
		context.allocator,
	)
	testing.expect(t, err == .NONE)
	testing.expect_value(t, len(newCellList), 2)
	err = List.destroy(newCellList, context.allocator)
	testing.expect(t, err == .NONE)

	removedEntryList: [dynamic]TestEntry
	removedCellList: [dynamic]Cell(TestEntryId, TestEntry, TestCellMeta)
	removedEntryList, removedCellList, err = removeFromGrid(&grid, 1, context.allocator)

	testing.expect_value(t, len(removedEntryList), 2)
	testing.expect_value(t, len(removedCellList), 2)
	testing.expect(t, err == .NONE)
	err = List.destroy(removedEntryList, grid.config.allocator)
	testing.expect(t, err == .NONE)
	err = List.destroy(removedCellList, grid.config.allocator)
	testing.expect(t, err == .NONE)
	err = destroy(&grid)
	testing.expect(t, err == .NONE)
}

@(test)
gridCellHashing :: proc(t: ^testing.T) {
	input: Math.IntVector = {2, 2}
	cellId := hashCell(input.x, input.y)
	testing.expect_value(t, cellId, 176384388)
}

@(test)
positionToCell :: proc(t: ^testing.T) {
	position: Math.Vector = {100, 100}
	x, y := worldToCell(position, 10)
	testing.expect_value(t, x, 10)
	testing.expect_value(t, y, 10)
}

@(test)
positionToCellNegative :: proc(t: ^testing.T) {
	position: Math.Vector = {-100, -100}
	x, y := worldToCell(position, 10)
	testing.expect_value(t, x, -10)
	testing.expect_value(t, y, -10)
}
