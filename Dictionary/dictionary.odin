package Dictionary

import BasePack "../"
import "core:slice"

@(require_results)
create :: proc(
	$TKey: typeid,
	$TValue: typeid,
	allocator: BasePack.Allocator,
) -> (
	result: map[TKey]TValue,
	error: BasePack.Error,
) {
	err: BasePack.AllocatorError
	result = make(map[TKey]TValue, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
getKeys :: proc(
	dictionary: $M/map[$K]$V,
	allocator: BasePack.Allocator,
) -> (
	keys: []K,
	error: BasePack.Error,
) {
	err: BasePack.AllocatorError
	keys, err = slice.map_keys(dictionary, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
destroy :: proc(
	dictionary: $M/map[$K]$V,
	allocator: BasePack.Allocator,
) -> (
	error: BasePack.Error,
) {
	err := delete(dictionary)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
unset :: proc(dictionary: ^$M/map[$K]$V, key: K) -> (error: BasePack.Error) {
	delete_key(dictionary, key)
	return
}

@(require_results)
set :: proc(dictionary: ^$M/map[$K]$V, key: K, value: V) -> (error: BasePack.Error) {
	dictionary[key] = value
	return
}
