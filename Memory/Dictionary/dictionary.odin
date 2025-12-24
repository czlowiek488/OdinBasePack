package Dictionary

import "../../../OdinBasePack"
import "core:slice"

@(require_results)
create :: proc(
	$TKey: typeid,
	$TValue: typeid,
	allocator: OdinBasePack.Allocator,
) -> (
	result: map[TKey]TValue,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	result = make(map[TKey]TValue, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
getKeys :: proc(
	dictionary: $M/map[$K]$V,
	allocator: OdinBasePack.Allocator,
) -> (
	keys: []K,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	keys, err = slice.map_keys(dictionary, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
getValues :: proc(
	dictionary: $M/map[$K]$V,
	allocator: OdinBasePack.Allocator,
) -> (
	keys: []V,
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.AllocatorError
	keys, err = slice.map_values(dictionary, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
destroy :: proc(
	dictionary: $M/map[$K]$V,
	allocator: OdinBasePack.Allocator,
) -> (
	error: OdinBasePack.Error,
) {
	err := delete(dictionary)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
remove :: proc(dictionary: ^$M/map[$K]$V, key: K) -> (error: OdinBasePack.Error) {
	delete_key(dictionary, key)
	return
}

@(require_results)
set :: proc(dictionary: ^$M/map[$K]$V, key: K, value: V) -> (error: OdinBasePack.Error) {
	dictionary[key] = value
	return
}

@(require_results)
get :: proc(
	dictionary: $M/map[$K]$V,
	key: K,
	required: bool,
) -> (
	value: ^V,
	present: bool,
	error: OdinBasePack.Error,
) {
	value, present = &dictionary[key]
	if !present && required {
		error = .DICTIONARY_KEY_MISSING_WHEN_REQUIRED
	}
	return
}
