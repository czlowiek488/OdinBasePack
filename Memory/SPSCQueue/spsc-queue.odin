package SPSCQueue

import "../../../OdinBasePack"
import "../Heap"
import "base:intrinsics"


/*
Heavily inspired by https://github.com/jakubtomsu/sds
*/

Queue :: struct($TCapacity: u64, $TData: typeid) {
	using _: struct #align (64) {
		producerHead: u64,
	},
	using _: struct #align (64) {
		producerTail: u64,
	},
	using _: struct #align (64) {
		consumerHead: u64,
	},
	using _: struct #align (64) {
		consumerTail: u64,
	},
	data:    [TCapacity]TData,
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
	return
}

@(require_results)
push :: proc(queue: ^Queue($TSize, $TData), items: ..TData) -> (error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	values := items
	oldProducerHead := queue.producerHead
	consumerTail := intrinsics.atomic_load_explicit(&queue.consumerTail, .Acquire)
	freeEntries := (TSize + consumerTail - oldProducerHead)
	values = values[:min(len(values), int(freeEntries))]
	if len(values) > 0 {
		newProducerHead := oldProducerHead + u64(len(values))
		queue.producerHead = newProducerHead
		for val, i in values {
			queue.data[(oldProducerHead + u64(i)) % TSize] = val
		}
		intrinsics.atomic_store_explicit(&queue.producerTail, newProducerHead, .Release)
	}
	if len(items) != len(values) {
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
	oldConsumerHead := queue.consumerHead
	producerTail := intrinsics.atomic_load_explicit(&queue.producerTail, .Acquire)
	readyEntries := producerTail - oldConsumerHead
	items = items[:min(len(items), int(readyEntries))]
	if len(items) <= 0 {
		return
	}
	newConsumerHead := oldConsumerHead + u64(len(items))
	queue.consumerHead = newConsumerHead
	for i in 0 ..< len(items) {
		items[i] = queue.data[(oldConsumerHead + u64(i)) % TSize]
	}
	intrinsics.atomic_store_explicit(&queue.consumerTail, newConsumerHead, .Release)
	return
}
