package SPSCQueue

import "../../../OdinBasePack"
import "core:testing"


@(test)
createsQueueTest :: proc(t: ^testing.T) {
	queue, err := create(4, int, context.allocator)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
	err = destroy(queue, context.allocator)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
}

@(test)
pushItemQueueTest :: proc(t: ^testing.T) {
	queue, _ := create(4, int, context.allocator)
	defer _ = destroy(queue, context.allocator)
	err := push(queue, 1)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
}

@(test)
popItemQueueTest :: proc(t: ^testing.T) {
	queue, _ := create(4, int, context.allocator)
	defer _ = destroy(queue, context.allocator)
	_ = push(queue, 1)
	items, err := pop(queue, 1, context.allocator)
	defer delete(items)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
	testing.expect_value(t, len(items), 1)
	testing.expect_value(t, items[0], 1)
}

@(test)
popTemporaryItemQueueTest :: proc(t: ^testing.T) {
	queue, _ := create(4, int, context.allocator)
	defer _ = destroy(queue, context.allocator)
	_ = push(queue, 1)
	items, err := pop(queue, 1, context.temp_allocator)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
	testing.expect_value(t, len(items), 1)
	testing.expect_value(t, items[0], 1)
}

@(test)
pushManyQueueTest :: proc(t: ^testing.T) {
	queue, _ := create(4, int, context.allocator)
	defer _ = destroy(queue, context.allocator)
	err := push(queue, 1, 2, 3)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
}

@(test)
popManyQueueTest :: proc(t: ^testing.T) {
	queue, _ := create(4, int, context.allocator)
	defer _ = destroy(queue, context.allocator)
	_ = push(queue, 1, 2, 3)
	items, err := pop(queue, 3, context.temp_allocator)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
	testing.expect_value(t, len(items), 3)
	testing.expect_value(t, items[0], 1)
	testing.expect_value(t, items[1], 2)
	testing.expect_value(t, items[2], 3)
	testing.expect_value(t, err, OdinBasePack.Error.NONE)
}

@(test)
pushOverflowQueueTest :: proc(t: ^testing.T) {
	queue, _ := create(4, int, context.allocator)
	defer _ = destroy(queue, context.allocator)
	err := push(queue, 1, 2, 3, 4, 5)
	testing.expect_value(t, err, OdinBasePack.Error.SPCS_QUEUE_OVERFLOW)
}
