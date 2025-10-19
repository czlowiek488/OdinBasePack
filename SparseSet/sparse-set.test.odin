package SparseSet

import BasePack "../"
import "core:testing"

@(private = "file")
Position :: struct {
	x, y: f32,
}
@(private = "file")
SetIdType :: distinct int
@(private = "file")
SetId: SetIdType : 2137

@(private = "file")
TestSSName :: "a name of sparse set"

@(test)
ssCreate :: proc(t: ^testing.T) {
	ss, error := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.sparse), 0)
	testing.expect_value(t, len(ss.denseData), 0)
	testing.expect_value(t, len(ss.denseId), 0)
}

@(test)
ssSet :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	position: Position = {10, 10}

	error := set(ss, SetId, position)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.denseData), 1)
	testing.expect_value(t, len(ss.denseId), 1)
	testing.expect_value(t, ss.denseData[0], position)
	testing.expect_value(t, ss.denseId[0], SetId)
}

@(test)
ssSetHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	position: Position = {10, 10}
	id := 10_000 + SetId
	error := set(ss, id, position)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.sparse), (int(10_000 + SetId) / int(Size)) + 1)
	testing.expect_value(t, len(ss.denseData), 1)
	testing.expect_value(t, len(ss.denseId), 1)
	testing.expect_value(t, ss.denseData[0], position)
	testing.expect_value(t, ss.denseId[0], id)
}

@(test)
ssGet :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	position: Position = {10, 10}
	_ = set(ss, SetId, position)

	data, present, error := get(ss, SetId, true)

	testing.expect_value(t, present, true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, data^, position)
}

@(test)
ssGetHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	position: Position = {10, 10}
	id := 10_000 + SetId
	_ = set(ss, id, position)

	data, present, error := get(ss, id, true)

	testing.expect_value(t, present, true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, data^, position)
}

@(test)
ssGetMissing :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)

	_, present, error := get(ss, SetId, false)

	testing.expect_value(t, present, false)
	testing.expect_value(t, error, BasePack.Error.NONE)
}

@(test)
ssGetMissingHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)

	id := 10_000 + SetId
	_, present, error := get(ss, id, false)

	testing.expect_value(t, present, false)
	testing.expect_value(t, error, BasePack.Error.NONE)
}

@(test)
ssGetMissingRequired :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)

	_, present, error := get(ss, SetId, true)

	testing.expect_value(t, present, false)
	testing.expect_value(t, error, BasePack.Error.SPARSE_SET_DATA_NOT_PRESENT)
}

@(test)
ssGetMissingRequiredHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)

	id := 10_000 + SetId
	_, present, error := get(ss, id, true)

	testing.expect_value(t, present, false)
	testing.expect_value(t, error, BasePack.Error.SPARSE_SET_DATA_NOT_PRESENT)
}

@(test)
ssUnset :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	_ = set(ss, SetId, Position{10, 10})

	error := unset(ss, SetId)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.denseData), 0)
	testing.expect_value(t, len(ss.denseId), 0)
}

@(test)
ssUnsetHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	id := 10_000 + SetId
	_ = set(ss, id, Position{10, 10})

	error := unset(ss, id)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.denseData), 0)
	testing.expect_value(t, len(ss.denseId), 0)
}

@(test)
unsetAndGetOptional :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	_ = set(ss, SetId, Position{10, 10})
	_ = unset(ss, SetId)

	data, present, error := get(ss, SetId, false)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
}

@(test)
unsetAndGetOptionalHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	id := 10_000 + SetId
	_ = set(ss, id, Position{10, 10})
	_ = unset(ss, id)

	data, present, error := get(ss, id, false)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
}

@(test)
unsetAndGetRequired :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	_ = set(ss, SetId, Position{10, 10})
	_ = unset(ss, SetId)

	data, present, error := get(ss, SetId, true)

	testing.expect_value(t, error, BasePack.Error.SPARSE_SET_DATA_NOT_PRESENT)
	testing.expect_value(t, present, false)
}

@(test)
unsetAndGetRequiredHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	id := 10_000 + SetId
	_ = set(ss, id, Position{10, 10})
	_ = unset(ss, id)

	data, present, error := get(ss, id, true)

	testing.expect_value(t, error, BasePack.Error.SPARSE_SET_DATA_NOT_PRESENT)
	testing.expect_value(t, present, false)
}

@(test)
ssGetDense :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	position: Position = {10, 10}
	_ = set(ss, SetId, position)

	dense, error := list(ss)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(dense), 1)
	testing.expect_value(t, dense[0], position)
	testing.expect_value(t, dense[0], ss.denseData[0])
}

@(test)
ssGetDenseHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	position: Position = {10, 10}
	id := 10_000 + SetId
	_ = set(ss, id, position)

	dense, error := list(ss)

	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, len(dense), 1)
	testing.expect_value(t, dense[0], position)
	testing.expect_value(t, dense[0], ss.denseData[0])
}

@(test)
unsetMultipleSets :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	entities: [4]SetIdType = {0, 1, 2, 3}
	for entityId, index in entities {
		inputData: Position = {f32(index), f32(index)}
		error := set(ss, entityId, inputData)
		testing.expect_value(t, error, BasePack.Error.NONE)
	}
	data, present, error := get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	data, present, error = get(ss, entities[1], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{1, 1})
	data, present, error = get(ss, entities[2], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{2, 2})
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = unset(ss, entities[1])
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = unset(ss, entities[2])
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	_, present, error = get(ss, entities[1], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	_, present, error = get(ss, entities[2], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = set(ss, entities[1], Position{10, 10})
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = set(ss, entities[2], Position{20, 20})
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	data, present, error = get(ss, entities[1], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{10, 10})
	data, present, error = get(ss, entities[2], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{20, 20})
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = unset(ss, entities[1])
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = unset(ss, entities[2])
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	_, present, error = get(ss, entities[1], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	_, present, error = get(ss, entities[2], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = set(ss, entities[1], Position{100, 100})
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = set(ss, entities[2], Position{200, 200})
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	data, present, error = get(ss, entities[1], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{100, 100})
	data, present, error = get(ss, entities[2], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{200, 200})
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	dense, getAllError := list(ss)
	testing.expect_value(t, getAllError, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.sparse), 1)
	testing.expect_value(t, len(ss.sparse[0]), Size)
	testing.expect_value(t, len(ss.denseData), 4)
	testing.expect_value(t, len(dense), 4)
}

@(test)
unsetMultipleSetsHighScale :: proc(t: ^testing.T) {
	ss, _ := create(SetIdType, Position, context.allocator)
	defer destroy(ss, context.allocator)
	entities: [4]SetIdType = {10_000, 10_001, 10_002, 10_003}
	for entityId, index in entities {
		inputData: Position = {f32(index), f32(index)}
		error := set(ss, entityId, inputData)
		testing.expect_value(t, error, BasePack.Error.NONE)
	}
	data, present, error := get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	data, present, error = get(ss, entities[1], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{1, 1})
	data, present, error = get(ss, entities[2], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{2, 2})
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = unset(ss, entities[1])
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = unset(ss, entities[2])
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	_, present, error = get(ss, entities[1], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	_, present, error = get(ss, entities[2], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = set(ss, entities[1], Position{10, 10})
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = set(ss, entities[2], Position{20, 20})
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	data, present, error = get(ss, entities[1], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{10, 10})
	data, present, error = get(ss, entities[2], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{20, 20})
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = unset(ss, entities[1])
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = unset(ss, entities[2])
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	_, present, error = get(ss, entities[1], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	_, present, error = get(ss, entities[2], false)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, false)
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	error = set(ss, entities[1], Position{100, 100})
	testing.expect_value(t, error, BasePack.Error.NONE)
	error = set(ss, entities[2], Position{200, 200})
	testing.expect_value(t, error, BasePack.Error.NONE)
	data, present, error = get(ss, entities[0], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{0, 0})
	data, present, error = get(ss, entities[1], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{100, 100})
	data, present, error = get(ss, entities[2], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{200, 200})
	data, present, error = get(ss, entities[3], true)
	testing.expect_value(t, error, BasePack.Error.NONE)
	testing.expect_value(t, present, true)
	testing.expect_value(t, data^, Position{3, 3})

	dense, getAllError := list(ss)
	testing.expect_value(t, getAllError, BasePack.Error.NONE)
	testing.expect_value(t, len(ss.sparse), int(entities[3]) / int(Size) + 1)
	testing.expect_value(t, len(ss.sparse[0]), Size)
	testing.expect_value(t, len(ss.denseData), 4)
	testing.expect_value(t, len(dense), 4)
}
