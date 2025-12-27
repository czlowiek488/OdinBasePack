package SparseSet

import "../../../OdinBasePack"
import "../Heap"
import "../List"
import "base:intrinsics"
import "base:runtime"
import "core:slice"
import "core:sort"

@(private = "file")
DataId :: distinct int


@(private = "file")
DataSparse :: struct {
	active: bool,
	index:  DataId,
}

@(private)
Size :: 1_000

@(private = "file")
SparseChunk :: [Size]DataSparse

SparseSet :: struct($TId: typeid, $TData: typeid) {
	trackerIndex: int,
	sparse:       [dynamic]SparseChunk,
	denseData:    [dynamic]TData,
	denseId:      [dynamic]TId,
	created:      bool,
	allocator:    runtime.Allocator,
}

@(require_results)
create :: proc(
	$TId: typeid,
	$TData: typeid,
	allocator: runtime.Allocator,
) -> (
	sparseSet: ^SparseSet(TId, TData),
	error: OdinBasePack.Error,
) {
	when !intrinsics.type_is_struct(TData) {
		#panic("sparse set dense element must always be a struct")
	}
	when !intrinsics.type_is_integer(
		TId,
	) && !intrinsics.type_is_integer(intrinsics.type_core_type(TId)) && !intrinsics.type_is_integer(intrinsics.type_base_type(TId)) {
		#panic("sparse set dense element must be created with integer type")
	}
	sparseSet = Heap.allocate(SparseSet(TId, TData), allocator) or_return
	sparseSet.sparse = List.create(SparseChunk, allocator) or_return
	sparseSet.denseData = List.create(TData, allocator) or_return
	sparseSet.denseId = List.create(TId, allocator) or_return
	sparseSet.created = true
	sparseSet.allocator = allocator
	return
}

destroy :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	allocator: runtime.Allocator,
) -> (
	error: OdinBasePack.Error,
) {
	List.destroy(sparseSet.denseData, allocator) or_return
	List.destroy(sparseSet.denseId, allocator) or_return
	List.destroy(sparseSet.sparse, allocator) or_return
	Heap.deAllocate(sparseSet, allocator) or_return
	return
}

@(private = "file")
getSparseData :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	id: TId,
) -> (
	data: ^DataSparse,
	error: OdinBasePack.Error,
) {
	chunkIndex := int(id) / int(Size)
	chunkId := TId(int(id) % int(Size))
	for _ in len(sparseSet.sparse) - 1 ..< chunkIndex {
		List.push(&sparseSet.sparse, SparseChunk{}) or_return
	}
	data = &sparseSet.sparse[chunkIndex][chunkId]
	return
}

@(require_results)
set :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	id: TId,
	data: TData,
) -> (
	error: OdinBasePack.Error,
) {
	if sparseSet == nil || !sparseSet.created {
		error = .SPARSE_SET_NOT_CREATED
		return
	}
	if id < 0 {
		error = .SPARSE_SET_ID_MUST_BE_GREATER_THAN_0
		return
	}
	sparseData := getSparseData(sparseSet, id) or_return
	sparseData.active = true
	newDenseIndex := cast(DataId)len(sparseSet.denseData)
	sparseData.index = newDenseIndex
	List.push(&sparseSet.denseData, data) or_return
	List.push(&sparseSet.denseId, id) or_return
	return
}

@(require_results)
list :: proc(
	sparseSet: ^SparseSet($TId, $TData),
) -> (
	dense: ^[dynamic]TData,
	error: OdinBasePack.Error,
) {
	if !sparseSet.created {
		error = .SPARSE_SET_NOT_CREATED
		return
	}
	dense = &sparseSet.denseData
	return
}

@(require_results)
get :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	id: TId,
	required: bool,
) -> (
	data: ^TData,
	dataPresent: bool,
	error: OdinBasePack.Error,
) {
	if !sparseSet.created {
		error = .SPARSE_SET_NOT_CREATED
		return
	}
	if id < 0 {
		error = .SPARSE_SET_INVALID_ID
		return
	}
	sparseData := getSparseData(sparseSet, id) or_return
	dataPresent = sparseData.active
	if !dataPresent {
		if required {
			error = .SPARSE_SET_DATA_NOT_PRESENT
		}
		return
	}
	data = &sparseSet.denseData[sparseData.index]
	return
}

@(require_results)
remove :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	teRemoveId: TId,
) -> (
	error: OdinBasePack.Error,
) {
	if !sparseSet.created {
		error = .SPARSE_SET_NOT_CREATED
		return
	}
	if teRemoveId < 0 {
		error = .SPARSE_SET_INVALID_ID
		return
	}
	toRemove := getSparseData(sparseSet, teRemoveId) or_return
	if !toRemove.active {
		error = .SPARSE_SET_ALREADY_REMOVED
		return
	}
	toSaveIndex := len(sparseSet.denseData) - 1
	if toSaveIndex == -1 {
		error = .SPARSE_SET_DENSE_LIST_EMPTY
		return
	}
	toSaveId := sparseSet.denseId[toSaveIndex]
	toRemoveIndex := toRemove.index
	toSave := getSparseData(sparseSet, toSaveId) or_return
	toSave^ = toRemove^
	toRemove.index = 0
	toRemove.active = false

	slice.swap(sparseSet.denseData[:], toSaveIndex, int(toRemoveIndex))
	shrink(&sparseSet.denseData, len(sparseSet.denseData) - 1)

	slice.swap(sparseSet.denseId[:], toSaveIndex, int(toRemoveIndex))
	shrink(&sparseSet.denseId, len(sparseSet.denseId) - 1)
	return
}

swapDense :: proc(sparseSet: ^SparseSet($TId, $TData), i, j: int) {
	if i == j {
		return
	}
	sparseSet.denseData[i], sparseSet.denseData[j] = sparseSet.denseData[j], sparseSet.denseData[i]
	sparseSet.denseId[i], sparseSet.denseId[j] = sparseSet.denseId[j], sparseSet.denseId[i]
}

quick_sort_proc :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	f: proc(a: TData, b: TData) -> int,
	lo := 0,
	hi := -1,
) {
	assert(f != nil)
	hui := hi
	if hui < 0 {
		hui = len(sparseSet.denseData) - 1
	}
	if lo >= hui {
		return
	}
	a := sparseSet.denseData
	pivot := a[(lo + hui) / 2]
	i := lo
	j := hui
	loop: for {
		for f(a[i], pivot) < 0 {i += 1}
		for f(pivot, a[j]) < 0 {j -= 1}

		if i >= j {
			break loop
		}

		swapDense(sparseSet, i, j)
		i += 1
		j -= 1
	}
	quick_sort_proc(sparseSet, f, lo, j)
	quick_sort_proc(sparseSet, f, j + 1, hui)
}

insertion_sort :: proc(sparseSet: ^SparseSet($TId, $TData), f: proc(a: TData, b: TData) -> int) {
	n := len(sparseSet.denseData)
	for i in 1 ..< n {
		for j := i; j > 0; j -= 1 {
			if f(sparseSet.denseData[j - 1], sparseSet.denseData[j]) <= 0 {
				break
			}
			swapDense(sparseSet, j, j - 1)
		}
	}
}

@(require_results)
sortBy :: proc(
	sparseSet: ^SparseSet($TId, $TData),
	compare: proc(a, b: TData) -> int,
) -> (
	error: OdinBasePack.Error,
) {
	if sparseSet == nil || !sparseSet.created {
		error = .SPARSE_SET_NOT_CREATED
		return
	}

	count := len(sparseSet.denseData)
	if count <= 1 {
		return
	}
	quick_sort_proc(sparseSet, compare)
	// insertion_sort(sparseSet, compare)

	for newIndex in 0 ..< count {
		id := sparseSet.denseId[newIndex]
		sparseData := getSparseData(sparseSet, id) or_return
		sparseData.index = cast(DataId)newIndex
	}

	return
}
