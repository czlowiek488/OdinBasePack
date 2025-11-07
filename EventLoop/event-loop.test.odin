package BasePackEventLoop

import BasePack "../"
import "core:fmt"
import "core:log"
import "core:testing"

@(private = "file")
TestTask :: union {
	ChangeMessage,
	TriggerSingleTask,
	TriggerSingleTaskThenCallback,
	TriggerTwoTasks,
	AddToResult1,
	AddToResult2,
	ScheduleTaskNextSecond,
	UnScheduleTaskNextSecond,
	ScheduleIntervalTask,
}

@(private = "file")
ChangeMessage :: struct {
	message: string,
}
@(private = "file")
TriggerSingleTask :: struct {}
@(private = "file")
TriggerSingleTaskThenCallbackUnion :: union {
	TriggerSingleTask,
	AddToResult1,
}
@(private = "file")
TriggerSingleTaskThenCallback :: struct {
	callback: TriggerSingleTaskThenCallbackUnion,
}
@(private = "file")
TriggerTwoTasks :: struct {}
@(private = "file")
AddToResult1 :: struct {}
@(private = "file")
AddToResult2 :: struct {}
@(private = "file")
ScheduleTaskNextSecond :: struct {}
@(private = "file")
UnScheduleTaskNextSecond :: struct {}
@(private = "file")
ScheduleIntervalTask :: struct {}

@(private = "file")
TestResult :: union {
	TestResult1,
	TestResult2,
}
@(private = "file")
TestResult1 :: struct {
	testResult1Message: string,
}
@(private = "file")
TestResult2 :: struct {
	testResult2Message: string,
}

@(private = "file")
TestData :: struct {
	counter:         int,
	message:         string,
	scheduledTaskId: Maybe(ReferenceId),
}

@(private = "file")
TestError :: enum {
	NONE,
	ERROR_1,
	ERROR_2,
}

@(private = "file")
TestEventLoop :: EventLoop(
	16,
	.SPSC_MUTEX,
	TestTask,
	TestTask,
	16,
	.SPSC_LOCK_FREE,
	TestResult,
	TestError,
)

@(private = "file")
_mapper :: proc(error: BasePack.Error) -> TestError {
	switch error {
	case .NONE:
		return .NONE
	case .ALLOCATOR_INVALID_ARGUMENT:
		return .ERROR_2
	case .ALLOCATOR_INVALID_POINTER:
		return .ERROR_2
	case .ALLOCATOR_MODE_NOT_IMPLEMENTED:
		return .ERROR_2
	case .ALLOCATOR_OUT_OF_MEMORY:
		return .ERROR_2
	case .INVALID_ENUM_VALUE:
		return .ERROR_2
	case .TIMER_MUST_BE_CREATED:
		return .ERROR_2
	case .TIMER_CURRENT_DURATION_CANNOT_BE_LESS_THAN_0:
		return .ERROR_2
	case .TIMER_DURATION_CANNOT_BE_LESS_THAN_0:
		return .ERROR_2
	case .TIMER_DURATION_CANNOT_BE_EQUAL_0:
		return .ERROR_2
	case .EVENT_LOOP_UNRECOGNIZED_SCHEDULED_TASK_ID:
		return .ERROR_2
	case .EVENT_LOOP_INTERVAL_TASK_MUST_HAVE_MINIMAL_DURATION_EQUAL_TO_1:
		return .ERROR_2
	case .EVENT_LOOP_TASK_ERROR:
		return .ERROR_2
	case .EVENT_LOOP_CANNOT_BE_USED_OUTSIDE_OF_TASK_CONTEXT:
		return .ERROR_2
	case .SPARSE_SET_NOT_CREATED:
		return .ERROR_2
	case .SPARSE_SET_ID_MUST_BE_GREATER_THAN_0:
		return .ERROR_2
	case .SPARSE_SET_DATA_NOT_PRESENT:
		return .ERROR_2
	case .SPARSE_SET_INVALID_ID:
		return .ERROR_2
	case .SPARSE_SET_ALREADY_REMOVED:
		return .ERROR_2
	case .SPARSE_SET_DENSE_LIST_EMPTY:
		return .ERROR_2
	case .AUTO_SET_IS_NOT_CREATED:
		return .ERROR_2
	case .HIT_BOX_FREE_ID_LIST_ALREADY_INITIALIZED:
		return .ERROR_2
	case .STRUCTURE_ID_PICKER_IS_NOT_STARTED:
		return .ERROR_2
	case .PRIORITY_QUEUE_UNEXPECTED_MISS:
		return .ERROR_2
	case .PRIORITY_QUEUE_CANNOT_NOT_EXISTING_INDEX:
		return .ERROR_2
	case .QUEUE_PUSH_ERROR:
		return .ERROR_2
	case .SPCS_QUEUE_OVERFLOW:
		return .ERROR_2
	case .DICTIONARY_KEY_MISSING_WHEN_REQUIRED:
		return .ERROR_2
	case:
		return .ERROR_1
	}
}

@(private = "file")
_destroyTestTaskLoop :: proc(t: ^testing.T, data: ^TestData, eventLoop: ^TestEventLoop) {
	err := destroy(eventLoop, context.allocator)
	testing.expect(t, err == .NONE)
}

@(private = "file")
_testExecutor :: proc(eventLoop: ^TestEventLoop, task: TestTask) -> (error: TestError) {
	data := cast(^TestData)eventLoop.data
	message := fmt.aprintf(
		"horrific message #{}",
		data.counter,
		allocator = context.temp_allocator,
	)
	switch value in task {
	case ChangeMessage:
		data.message = value.message
	case TriggerSingleTask:
		eventLoop->microTask(ChangeMessage{message}) or_return

	case TriggerSingleTaskThenCallback:
		// looking for better way of handling unions that are subsets of different unions like here...
		switch v in value.callback {
		case TriggerSingleTask:
			eventLoop->microTask(v) or_return
		case AddToResult1:
			eventLoop->microTask(v) or_return
		}
	case TriggerTwoTasks:
		eventLoop->microTask(ChangeMessage{message}, ChangeMessage{message}) or_return

	case AddToResult1:
		eventLoop->result(TestResult1{message}) or_return

	case AddToResult2:
		eventLoop->result(TestResult2{message}) or_return
	case ScheduleTaskNextSecond:
		data.scheduledTaskId = eventLoop->task(.TIMEOUT, 1, AddToResult1{}) or_return
	case UnScheduleTaskNextSecond:
		if scheduledTaskId, ok := data.scheduledTaskId.?; ok {
			_ = eventLoop->unSchedule(scheduledTaskId, true) or_return
			data.scheduledTaskId = nil
		}
	case ScheduleIntervalTask:
		data.scheduledTaskId = eventLoop->task(.INTERVAL, 1, AddToResult1{}) or_return
	}
	data.counter += 1
	return
}

@(private = "file")
@(deferred_in_out = _destroyTestTaskLoop)
_createTestTaskLoop :: proc(t: ^testing.T, data: ^TestData) -> (eventLoop: ^TestEventLoop) {
	error: BasePack.Error
	err: BasePack.AllocatorError
	eventLoop, err = new(TestEventLoop, context.allocator)
	testing.expect(t, err == .None)
	testError: TestError
	testError = create(data, eventLoop, _testExecutor, _testExecutor, _mapper, context.allocator)
	testing.expect(t, testError == .NONE)
	return
}

@(test)
initializeEventLoopTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	testing.expect(t, data.counter == 1)
	testing.expect(t, data.message == "no message")
}

@(test)
scheduleSingleTaskWithoutProcessingTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	err := pushTasks(eventLoop, ChangeMessage{"funky message"})
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 1)
	testing.expect(t, data.message == "no message")
}

@(test)
processSingleTaskTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, ChangeMessage{"funky message"})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 2)
	testing.expect(t, data.message == "funky message")
}

@(test)
processTaskWithMicroTaskTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, TriggerSingleTask{})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 3)
	testing.expect(t, data.message == "horrific message #1")
}

@(test)
processTaskWithMicroTaskWithMicroTaskTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, TriggerSingleTaskThenCallback{TriggerSingleTask{}})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 4)
	testing.expect(t, data.message == "horrific message #2")
}

@(test)
triggerTwoTasksTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, TriggerTwoTasks{})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 4)
	testing.expect(t, data.message == "horrific message #1")
}

@(test)
addResult1ToListTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, AddToResult1{})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	resultList: []TestResult
	resultList, err = popResults(eventLoop, -1, context.temp_allocator)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 2)
	testing.expect(t, data.message == "no message")
	testing.expect(t, len(resultList) == 1)
	testResult1, ok := resultList[0].(TestResult1)
	testing.expect(t, ok, "resultList is not typeof TestResult1")
	testing.expect(t, testResult1.testResult1Message == "horrific message #1")
}

@(test)
callbackForAddResult1ToListTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, TriggerSingleTaskThenCallback{AddToResult1{}})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	resultList: []TestResult
	resultList, err = popResults(eventLoop, -1, context.temp_allocator)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 3)
	testing.expect(t, data.message == "no message")
	testing.expect(t, len(resultList) == 1)
	testResult1, ok := resultList[0].(TestResult1)
	testing.expect(t, ok, "resultList is not typeof TestResult1")
	testing.expect(t, testResult1.testResult1Message == "horrific message #2")
}

@(test)
addResult2ToListTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, AddToResult2{})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	resultList: []TestResult
	resultList, err = popResults(eventLoop, -1, context.temp_allocator)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 2)
	testing.expect(t, data.message == "no message")
	testing.expect(t, len(resultList) == 1)
	testResult2, ok := resultList[0].(TestResult2)
	testing.expect(t, ok, "resultList is not typeof TestResult2")
	testing.expect(t, testResult2.testResult2Message == "horrific message #1")
}

@(test)
scheduleTaskInNextSecondTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, ScheduleTaskNextSecond{})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	resultList: []TestResult
	resultList, err = popResults(eventLoop, -1, context.temp_allocator)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 2)
	testing.expect(t, data.message == "no message")
	testing.expect(t, len(resultList) == 0)
	err = flush(eventLoop, 1)
	resultList, err = popResults(eventLoop, -1, context.temp_allocator)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 3)
	testing.expect(t, data.message == "no message")
	testing.expect(t, len(resultList) == 1)
}

@(test)
scheduleTaskAndUnScheduleTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, ScheduleTaskNextSecond{}, UnScheduleTaskNextSecond{})
	err := flush(eventLoop, 0)
	testing.expect(t, err == .NONE)
	resultList: []TestResult
	resultList, err = popResults(eventLoop, -1, context.temp_allocator)
	testing.expect(t, err == .NONE)
	testing.expect(t, data.counter == 3)
	testing.expect(t, data.scheduledTaskId == nil)
	testing.expect(t, data.message == "no message")
	testing.expect(t, len(resultList) == 0)
}

@(test)
scheduleIntervalTaskAndPopThriceTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, ScheduleIntervalTask{})
	{
		err := flush(eventLoop, 0)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		testing.expect(t, data.counter == 2)
		testing.expect(t, data.scheduledTaskId == 1)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 0)
	}
	{
		err := flush(eventLoop, 1)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		testing.expect(t, data.counter == 3)
		testing.expect(t, data.scheduledTaskId == 1)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 1)
	}
	{
		err := flush(eventLoop, 2)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		testing.expect(t, data.counter == 4)
		testing.expect(t, data.scheduledTaskId == 1)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 1)
	}
}

@(test)
scheduleIntervalTaskAndPopOnceUnScheduleAndPopTest :: proc(t: ^testing.T) {
	data: TestData = {1, "no message", nil}
	eventLoop := _createTestTaskLoop(t, &data)
	_ = pushTasks(eventLoop, ScheduleIntervalTask{})
	{
		err := flush(eventLoop, 0)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		log.info("data 1", data)
		testing.expect(t, data.counter == 2)
		testing.expect(t, data.scheduledTaskId == 1)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 0)
	}
	{
		err := flush(eventLoop, 1)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		testing.expect(t, data.counter == 3)
		testing.expect(t, data.scheduledTaskId == 1)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 1)
	}
	_ = pushTasks(eventLoop, UnScheduleTaskNextSecond{})
	{
		err := flush(eventLoop, 2)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		testing.expect(t, data.counter == 4)
		testing.expect(t, data.scheduledTaskId == nil)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 0)
	}
	{
		err := flush(eventLoop, 3)
		testing.expect(t, err == .NONE)
		resultList: []TestResult
		resultList, err = popResults(eventLoop, -1, context.temp_allocator)
		testing.expect(t, err == .NONE)
		testing.expect(t, data.counter == 4)
		testing.expect(t, data.scheduledTaskId == nil)
		testing.expect(t, data.message == "no message")
		testing.expect(t, len(resultList) == 0)
	}
}
