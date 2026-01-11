package List

import "../../../OdinBasePack"
import "core:slice"
import "core:sort"

@(require_results)
create :: proc(
	$T: typeid,
	allocator: OdinBasePack.Allocator,
	location := #caller_location,
	size: int = 0,
) -> (
	list: [dynamic]T,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	list, err = make([dynamic]T, size, allocator, location)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
push :: proc(
	list: ^$T/[dynamic]$E,
	element: ..E,
	location := #caller_location,
) -> (
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	_, err = append_elems(list, args = element, loc = location)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
removeAt :: proc(
	list: ^$T/[dynamic]$E,
	index: int,
	ordered: bool,
	location := #caller_location,
) -> (
	error: OdinBasePack.Error,
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
destroy :: proc(
	list: $T/[dynamic]$E,
	allocator: OdinBasePack.Allocator,
) -> (
	error: OdinBasePack.Error,
) {
	err := delete(list)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
purge :: proc(list: ^$T/[dynamic]$E) -> (error: OdinBasePack.Error) {
	clear(list)
	return
}

@(require_results)
destroySlice :: proc(
	list: $T/[]$E,
	allocator: OdinBasePack.Allocator,
	location := #caller_location,
) -> (
	error: OdinBasePack.Error,
) {
	err := delete(list, allocator, location)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}


@(require_results)
sortBy :: proc(
	list: $T/[]$E,
	sortingProcedure: proc(a, b: E) -> int,
) -> (
	error: OdinBasePack.Error,
) {
	sort.bubble_sort_proc(list, sortingProcedure)
	return
}

@(require_results)
fromSlice :: proc(
	slicedList: $T/[]$E,
	allocator: OdinBasePack.Allocator,
) -> (
	list: [dynamic]E,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	list, err = slice.to_dynamic(slicedList, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
cloneSlice :: proc(
	slicedList: $T/[]$E,
	allocator: OdinBasePack.Allocator,
) -> (
	result: []E,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	result, err = slice.clone(slicedList, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
cloneToSlice :: proc(
	list: $T/[dynamic]$E,
	allocator: OdinBasePack.Allocator,
) -> (
	result: []E,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	result, err = slice.clone(list[:], allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}
