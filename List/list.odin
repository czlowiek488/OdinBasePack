package List

import BasePack "../"
import "core:slice"
import "core:sort"

@(require_results)
create :: proc(
	$T: typeid,
	allocator: BasePack.Allocator,
	location := #caller_location,
	size: int = 0,
) -> (
	list: [dynamic]T,
	error: BasePack.Error,
) {
	err: BasePack.AllocatorError
	list, err = make([dynamic]T, size, allocator, location)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
push :: proc(
	list: ^$T/[dynamic]$E,
	element: ..E,
	location := #caller_location,
) -> (
	error: BasePack.Error,
) {
	err: BasePack.AllocatorError
	_, err = append_elems(list, args = element, loc = location)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
removeAt :: proc(
	list: ^$T/[dynamic]$E,
	index: int,
	ordered: bool,
	location := #caller_location,
) -> (
	error: BasePack.Error,
) {
	if index < 0 {
		error = .LIST_NEGATIVE_INDEX
		return
	}
	if len(list) <= index {
		error = .LIST_INDEX_EXCEEDS_LENGTH
		return
	}
	switch ordered {
	case true:
		ordered_remove(list, index, location)
	case false:
		unordered_remove(list, index, location)
	}
	return
}

@(require_results)
destroy :: proc(list: $T/[dynamic]$E, allocator: BasePack.Allocator) -> (error: BasePack.Error) {
	err := delete(list)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
purge :: proc(list: ^$T/[dynamic]$E) -> (error: BasePack.Error) {
	clear(list)
	return
}

@(require_results)
destroySlice :: proc(list: $T/[]$E) -> (error: BasePack.Error) {
	err := delete(list)
	BasePack.parseAllocatorError(err) or_return
	return
}


@(require_results)
sortBy :: proc(list: $T/[]$E, sortingProcedure: proc(a, b: E) -> int) -> (error: BasePack.Error) {
	sort.bubble_sort_proc(list, sortingProcedure)
	return
}

@(require_results)
fromSlice :: proc(
	slicedList: $T/[]$E,
	allocator: BasePack.Allocator,
) -> (
	list: [dynamic]E,
	error: BasePack.Error,
) {
	err: BasePack.AllocatorError
	list, err = slice.to_dynamic(slicedList, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
cloneSlice :: proc(
	slicedList: $T/[]$E,
	allocator: BasePack.Allocator,
) -> (
	result: []E,
	error: BasePack.Error,
) {
	err: BasePack.AllocatorError
	result, err = slice.clone(slicedList, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}
