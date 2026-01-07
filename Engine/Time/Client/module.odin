package TimeClient

import "../../../../OdinBasePack"
import "../../../Memory/Timer"
import "../../Time"
import "core:log"
import "vendor:sdl3"

ModuleConfig :: struct {
	unlimitedFps: bool,
}

Module :: struct {
	config:           ModuleConfig,
	//
	frameTime:        Timer.Time,
	frameDelay:       Timer.Time,
	frameStartTime:   Timer.Time,
	frameEndTime:     Timer.Time,
	minimalFrameTime: Timer.Time,
	created:          bool,
}

@(require_results)
createModule :: proc(config: ModuleConfig) -> (module: Module, error: OdinBasePack.Error) {
	module.config = config
	return
}

@(require_results)
setFrameLimit :: proc(module: ^Module) -> (error: OdinBasePack.Error) {
	if module.config.unlimitedFps {
		module.minimalFrameTime = 1
	} else {
		module.minimalFrameTime = 1000 / 60
	}
	module.created = true
	return
}
@(require_results)
getCurrentTime :: proc() -> (time: Timer.Time, error: OdinBasePack.Error) {
	time = Timer.Time(sdl3.GetTicks())
	return
}

@(require_results)
handleFrameTimeAndDelay :: proc(
	module: ^Module,
) -> (
	delay: Timer.Time,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.frameEndTime = getCurrentTime() or_return
	module.frameTime = module.frameEndTime - module.frameStartTime
	if module.frameTime >= module.minimalFrameTime {
		module.frameStartTime = getCurrentTime() or_return
		return
	}
	module.frameDelay = max(module.minimalFrameTime - module.frameTime, 0)
	if module.frameDelay > 0 {
		module.frameEndTime += module.frameDelay
		module.frameTime += module.frameDelay
	}
	module.frameStartTime = getCurrentTime() or_return
	delay = module.frameDelay
	return
}

@(private = "file")
@(require_results)
calculateFps :: proc(time: Timer.Time) -> (fps: Time.Fps, error: OdinBasePack.Error) {
	if time == 0 {
		fps = 0
	} else {
		fps = Time.Fps(1000 / time)
	}
	return
}

@(require_results)
getFps :: proc(module: ^Module) -> (fps: Time.Fps, error: OdinBasePack.Error) {
	fps = calculateFps(module.frameTime) or_return
	return
}

@(require_results)
getPotentialFps :: proc(module: ^Module) -> (fps: Time.Fps, error: OdinBasePack.Error) {
	fps = calculateFps(module.frameTime - module.frameDelay) or_return
	return
}


@(require_results)
getFrameTime :: proc(module: ^Module) -> (frameTime: Timer.Time, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	frameTime = module.frameTime
	return
}
