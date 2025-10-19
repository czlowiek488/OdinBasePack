package PriorityQueue

import "core:testing"

@(private = "file")
TestEvent :: struct {
	message: string,
}

@(test)
createPriorityQueueTest :: proc(t: ^testing.T) {
	pq, err := create(TestEvent, context.allocator)
	testing.expect(t, err == .NONE)
	err = destroy(pq, context.allocator)
	testing.expect(t, err == .NONE)
	return
}

@(test)
pushEventTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	err := push(pq, 1, 0, TestEvent{"a"})
	testing.expect(t, err == .NONE)
	queueLen: int
	queueLen, err = length(pq)
	testing.expect(t, queueLen == 1)
	return
}

@(test)
popEventTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	queueLen: int
	queueLen, err = length(pq)
	testing.expect(t, queueLen == 0)
	return
}

@(test)
popPastEventTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	event, found, err := pop(pq, 1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	return
}

@(test)
popWithOnlyFutureEventTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 1, TestEvent{"a"})
	_, found, err := pop(pq, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, !found)
	return
}

@(test)
pushManyEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	err := push(pq, 1, 0, TestEvent{"a"})
	testing.expect(t, err == .NONE)
	err = push(pq, 2, 2, TestEvent{"b"})
	testing.expect(t, err == .NONE)
	err = push(pq, 3, 1, TestEvent{"c"})
	testing.expect(t, err == .NONE)
	queueLen: int
	queueLen, err = length(pq)
	testing.expect(t, queueLen == 3)
	return
}

@(test)
pushManyPopOneEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	return
}

@(test)
pushManyPopTwoEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	event, found, err = pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "b")
	return
}

@(test)
pushManyPopThreeEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	event, found, err = pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "b")
	event, found, err = pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "c")
	return
}

@(test)
pushManyPopOneUnderPriorityEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	event, found, err := pop(pq, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	_, found, err = pop(pq, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, !found)
	return
}

@(test)
popEachPriorityEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	event, found, err := pop(pq, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	event, found, err = pop(pq, 1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "b")
	event, found, err = pop(pq, 2)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "c")
	return
}

@(test)
pushInBetweenEventsTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	err := push(pq, 2, 1, TestEvent{"b"})
	testing.expect(t, err == .NONE)
	return
}

@(test)
pushInBetweenAndPopFirstTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 3, 2, TestEvent{"c"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	return
}

@(test)
trackSingleReferenceTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	testing.expect(t, len(pq.references) == 1)
	testing.expect(t, pq.references[1] == 0)
	return
}

@(test)
trackTwoReferenceTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	testing.expect(t, len(pq.references) == 2)
	testing.expect(t, pq.references[1] == 0)
	testing.expect(t, pq.references[2] == 1)
	return
}

@(test)
popWhenTwoReferenceTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	testing.expect(t, len(pq.references) == 2)
	testing.expect(t, pq.references[1] == 0)
	testing.expect(t, pq.references[2] == 1)
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	testing.expect(t, len(pq.references) == 1)
	testing.expect(t, pq.references[2] == 0)
	return
}

@(test)
popWhenThreeReferenceTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"b"})
	testing.expect(t, len(pq.references) == 3)
	testing.expect(t, pq.references[1] == 0)
	testing.expect(t, pq.references[2] == 1)
	testing.expect(t, pq.references[3] == 2)
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	testing.expect(t, len(pq.references) == 2)
	testing.expect(t, pq.references[2] == 0)
	testing.expect(t, pq.references[3] == 1)
	return
}

@(test)
popTwoWhenThreeReferenceTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	_ = push(pq, 3, 2, TestEvent{"b"})
	testing.expect(t, len(pq.references) == 3)
	testing.expect(t, pq.references[1] == 0)
	testing.expect(t, pq.references[2] == 1)
	testing.expect(t, pq.references[3] == 2)
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	testing.expect(t, len(pq.references) == 2)
	testing.expect(t, pq.references[2] == 0)
	testing.expect(t, pq.references[3] == 1)
	event, found, err = pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "b")
	testing.expect(t, len(pq.references) == 1)
	testing.expect(t, pq.references[3] == 0)
	return
}

@(test)
popTwoWhenOneReferenceTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	testing.expect(t, len(pq.references) == 2)
	testing.expect(t, pq.references[1] == 0)
	testing.expect(t, pq.references[2] == 1)
	event, found, err := pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "a")
	testing.expect(t, len(pq.references) == 1)
	testing.expect(t, pq.references[3] == 0)
	event, found, err = pop(pq, -1)
	testing.expect(t, err == .NONE)
	testing.expect(t, found)
	testing.expect(t, event.data.message == "b")
	testing.expect(t, len(pq.references) == 0)
	return
}

@(test)
pushAndRemoveTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	found, err := remove(pq, 1)
	testing.expect(t, found)
	testing.expect(t, len(pq.references) == 0)
	testing.expect(t, err == .NONE)
	return
}

@(test)
pushTwoAndRemoveTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	_ = push(pq, 2, 1, TestEvent{"b"})
	found, err := remove(pq, 1)
	testing.expect(t, found)
	testing.expect(t, len(pq.references) == 1)
	testing.expect(t, err == .NONE)
	return
}

@(test)
pushAndRemoveTwoTest :: proc(t: ^testing.T) {
	pq, _ := create(TestEvent, context.allocator)
	defer _ = destroy(pq, context.allocator)
	_ = push(pq, 1, 0, TestEvent{"a"})
	found, err := remove(pq, 1)
	testing.expect(t, found)
	testing.expect(t, len(pq.references) == 0)
	testing.expect(t, err == .NONE)
	found, err = remove(pq, 1)
	testing.expect(t, !found)
	testing.expect(t, len(pq.references) == 0)
	testing.expect(t, err == .NONE)
	return
}
