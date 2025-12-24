package SPSCQueue

import "../../OdinBasePack"
import "../Memory/Heap"
import "../sds"

Queue :: struct($TCapacity: u64, $TData: typeid) {
	queue: ^sds.SPSC(TCapacity, TData),
}

@(require_results)
create :: proc(
	$TCapacity: u64,
	$TData: typeid,
	allocator: OdinBasePack.Allocator,
) -> (
	queue: ^Queue(TCapacity, TData),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	queue = Heap.allocate(Queue(TCapacity, TData), allocator) or_return
	queue.queue = Heap.allocate(sds.SPSC(TCapacity, TData), allocator) or_return
	return
}

@(require_results)
destroy :: proc(
	queue: ^Queue($TSize, $TData),
	allocator: OdinBasePack.Allocator,
) -> (
	error: OdinBasePack.Error,
) {
	Heap.deAllocate(queue, allocator) or_return
	Heap.deAllocate(queue.queue, allocator) or_return
	return
}

@(require_results)
push :: proc(queue: ^Queue($TSize, $TData), items: ..TData) -> (error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	count := sds.spsc_push_elems(queue.queue, vals = items)
	if count != len(items) {
		error = .SPCS_QUEUE_OVERFLOW
	}
	return
}

@(require_results)
pop :: proc(
	queue: ^Queue($TSize, $TData),
	$TLimit: u64,
	allocator: OdinBasePack.Allocator,
) -> (
	items: []TData,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	when TLimit > TSize {
		#panic("limit exceeds size, use 0 instead")
	}
	localLimit := TLimit
	if TLimit == 0 {
		localLimit = TSize
	}
	err: OdinBasePack.AllocatorError
	items, err = make([]TData, localLimit, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	items = sds.spsc_pop_elems(queue.queue, items)
	return
}
