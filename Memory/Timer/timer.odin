package Timer

import "../../../OdinBasePack"
import "core:math"

Times :: distinct u8

Time :: distinct int

Timer :: struct {
	created:         bool,
	duration:        Time,
	currentDuration: Time,
	times:           Times,
}

@(require_results)
create :: proc(duration: Time) -> (timer: Timer, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	timer.created = true
	timer.duration = duration
	asserts(&timer) or_return
	return
}

@(require_results)
asserts :: proc(timer: ^Timer) -> (error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error, "timer = {}", timer)
	if !isCreated(timer) {
		error = .TIMER_MUST_BE_CREATED
		return
	}
	if timer.currentDuration < 0 {
		error = .TIMER_CURRENT_DURATION_CANNOT_BE_LESS_THAN_0
	}
	if timer.duration < 0 {
		error = .TIMER_DURATION_CANNOT_BE_LESS_THAN_0
	}
	if timer.duration == 0 {
		error = .TIMER_DURATION_CANNOT_BE_EQUAL_0
		return
	}
	return
}

@(require_results)
getCappedFillPercentage :: proc(
	timer: ^Timer,
) -> (
	fillPercentage: f32,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	asserts(timer) or_return
	fillPercentage = getOverfilledFillPercentage(timer)
	if fillPercentage > 1 {
		fillPercentage = 1
	}
	return
}

@(private = "file")
@(require_results)
getOverfilledFillPercentage :: proc(timer: ^Timer) -> f32 {
	return f32(timer.currentDuration) / f32(timer.duration)
}

@(private = "file")
@(require_results)
progressCurrentDuration :: proc(timer: ^Timer, timeToPass: Time) -> (passed: bool) {
	timer.currentDuration += timeToPass
	passed = timer.currentDuration >= timer.duration
	return
}

@(private = "file")
@(require_results)
cutOverPassedDuration :: proc(timer: ^Timer) -> (appliesAmount: Times) {
	appliesAmount = Times(math.floor(getOverfilledFillPercentage(timer)))
	timer.currentDuration -= Time(appliesAmount) * timer.duration
	return
}

@(require_results)
isCreated :: proc(timer: ^Timer) -> bool {
	return timer.created
}

@(require_results)
restart :: proc(
	timer: ^Timer,
	duration, currentDuration: Time,
	times: Times,
	validate: bool,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	timer.duration = duration
	timer.currentDuration = currentDuration
	timer.times = times
	if validate {
		asserts(timer) or_return
	}
	return
}

@(require_results)
getCurrentDuration :: proc(timer: ^Timer) -> Time {
	return timer.currentDuration
}

@(require_results)
progress :: proc(
	timer: ^Timer,
	timeToPass: Time,
) -> (
	appliesAmount: Times,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	asserts(timer) or_return
	if !progressCurrentDuration(timer, timeToPass) {
		return
	}
	appliesAmount = cutOverPassedDuration(timer)
	timer.times += appliesAmount
	return
}
