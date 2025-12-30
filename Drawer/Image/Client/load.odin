package ImageClient

import "../../../../../Packages/jobs"
import "../../../../OdinBasePack"
import "../../../Memory/Dictionary"
import "../../../Memory/Heap"
import "../../../Memory/List"
import "../../Image"
import "core:fmt"
import "core:log"
import "core:time"
import "vendor:sdl3"
import "vendor:sdl3/image"

@(require_results)
get :: proc(module: ^Module($TFileImageName), fileImageName: union {
		TFileImageName,
		string,
	}, required: bool) -> (texture: ^sdl3.Texture, present: bool, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	image: ^Image.DynamicImage
	switch value in fileImageName {
	case TFileImageName:
		image, present = Dictionary.get(module.imageMap, value, true) or_return
	case string:
		image, present = Dictionary.get(module.dynamicImageMap, value, true) or_return
	case:
		error = .INVALID_ENUM_VALUE
		return
	}
	if present {
		texture = image.texture
	}
	if !present && required {
		error = .FILE_IMAGE_MUST_EXISTS
	}
	return
}

@(require_results)
registerDynamicImage :: proc(
	module: ^Module($TFileImageName),
	imageName: string,
	path: string,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	Dictionary.set(&module.dynamicImageMap, imageName, Image.DynamicImage{nil, path}) or_return
	return
}

@(require_results)
createTempAsync :: proc(
	module: ^Module($TFileImageName),
) -> (
	temp: Image.TempAsync(TFileImageName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	temp.queue = sdl3.CreateAsyncIOQueue()
	if temp.queue == nil {
		error = .IMAGE_ASYNC_IO_QUEUE_CREATION_FAILED
		return
	}
	keys := Dictionary.getKeys(module.dynamicImageMap, context.temp_allocator) or_return
	temp.dynamicKeys = List.fromSlice(keys, context.temp_allocator) or_return
	#reverse for key, index in temp.dynamicKeys {
		image := module.dynamicImageMap[key]
		if image.texture != nil {
			unordered_remove(&temp.dynamicKeys, index)
		}
	}
	for name in module.imageMap {
		List.push(&temp.keys, name) or_return
	}
	return
}

destroyTempAsync :: proc(temp: ^Image.TempAsync($TFileImageName)) {
	sdl3.DestroyAsyncIOQueue(temp.queue)
	return
}

loadFiles :: proc(
	module: ^Module($TFileImageName),
	temp: ^Image.TempAsync(TFileImageName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for {
		if temp.asyncIoCount < 3 && (len(temp.dynamicKeys) > 0 || len(temp.keys) > 0) {
			temp.asyncIoCount += 1
			key: union {
				string,
				TFileImageName,
			}
			if len(temp.dynamicKeys) > 0 {
				key = pop(&temp.dynamicKeys)
			} else {
				key = pop(&temp.keys)
			}
			image: Image.DynamicImage
			switch value in key {
			case TFileImageName:
				image = module.imageMap[value]
			case string:
				image = module.dynamicImageMap[value]
			}
			texturePath := fmt.caprintf("{}", image.path)
			asyncFile := sdl3.AsyncIOFromFile(texturePath, "r")
			if asyncFile == nil {
				error = .IMAGE_GETTING_ASYNC_FILE_IO_FAILED
				return
			}
			size := sdl3.GetAsyncIOSize(asyncFile)
			arr := make([]u8, size)
			List.push(
				&temp.loads,
				Image.AsyncLoad(TFileImageName){arr, key, asyncFile, nil},
			) or_return
			if !sdl3.ReadAsyncIO(asyncFile, raw_data(arr), 0, u64(size), temp.queue, nil) {
				error = .IMAGE_READING_ASYNC_FILE_IO_FAILED
				return
			}
		} else {
			outcome: sdl3.AsyncIOOutcome
			if !sdl3.GetAsyncIOResult(temp.queue, &outcome) {
				sdl3.Delay(1)
				continue
			}
			if outcome.type == .WRITE {
				error = .IMAGE_ASYNC_IO_UNEXPECTED_OUTCOME_TYPE
			} else if outcome.type == .READ {
				if outcome.result != .COMPLETE {
					error = .IMAGE_ASYNC_IO_UNEXPECTED_COMPLETE_OUTCOME_RESULT_1
					return
				}
				if !sdl3.CloseAsyncIO(outcome.asyncio, false, temp.queue, nil) {
					error = .IMAGE_CLOSING_ASYNC_IO_FAILED
					return
				}
			} else if outcome.type == .CLOSE {
				if outcome.result != .COMPLETE {
					error = .IMAGE_ASYNC_IO_UNEXPECTED_COMPLETE_OUTCOME_RESULT_2
					return
				}
				temp.asyncIoCount -= 1
				if temp.asyncIoCount == 0 && len(temp.dynamicKeys) == 0 {
					break
				}
			}
		}
	}
	return
}

loadSurfaceInternal :: proc(
	io: ^sdl3.IOStream,
) -> (
	surface: ^sdl3.Surface,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	surface = image.LoadPNG_IO(io)
	if surface == nil {
		error = .FAILED_LOAD_BMP_FILE
		return
	}
	return
}

loadLoad :: proc(
	module: ^Module,
	load: ^Image.AsyncLoad($TFileImageName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	sw: time.Stopwatch
	time.stopwatch_start(&sw)
	io := sdl3.IOFromMem(raw_data(load.data), len(load.data))
	if io == nil {
		error = .IMAGE_CREATING_IO_FROM_MEMORY_FAILED
		return
	}
	defer sdl3.CloseIO(io)
	surface := loadSurfaceInternal(io) or_return
	defer sdl3.DestroySurface(surface)
	load.surface = sdl3.ConvertSurface(surface, .ABGR8888)
	if load.surface == nil {
		error = .IMAGE_SURFACE_CONVERTING_FAILED
		return
	}
	return
}

LoadJobData :: struct($TFileImageName: typeid) {
	module:      ^Module(TFileImageName),
	load:        ^Image.AsyncLoad(TFileImageName),
	error:       ^OdinBasePack.Error,
	error_mutex: ^sdl3.Mutex,
}

@(require_results)
loadLoads :: proc(
	module: ^Module($TFileImageName),
	temp: ^Image.TempAsync(TFileImageName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	error_result: OdinBasePack.Error
	error_mutex := sdl3.CreateMutex()
	defer sdl3.DestroyMutex(error_mutex)
	group: jobs.Group
	sw: time.Stopwatch
	time.stopwatch_start(&sw)
	if module.config.measureLoading {
		log.infof("Loading started = {}", time.stopwatch_duration(sw))
	}
	if len(temp.loads) > 1 {
		if module.config.measureLoading {
			log.infof("Using threads to load texture, count = {}", len(temp.loads))
		}
		for &load in temp.loads {
			job_data := Heap.allocate(
				LoadJobData(TFileImageName),
				context.temp_allocator,
			) or_return
			job_data^ = {module, &load, &error_result, error_mutex}
			job := jobs.make_job(&group, job_data, proc(data: rawptr) {
					jd := (^LoadJobData(TFileImageName))(data)
					if err := loadLoad(jd.module, jd.load); err != nil {
						sdl3.LockMutex(jd.error_mutex)
						jd.error^ = err
						sdl3.UnlockMutex(jd.error_mutex)
					}
				})
			jobs.dispatch(.Medium, job)
		}
		if module.config.measureLoading {
			log.infof("Job scheduled = {}", time.stopwatch_duration(sw))
		}
		jobs.wait(&group)
		if module.config.measureLoading {
			log.infof("Job completed = {}", time.stopwatch_duration(sw))
		}
	} else {
		if module.config.measureLoading {
			log.infof("Loading texture on main thread, count = {}", len(temp.loads))
		}
		for &load in temp.loads {
			loadLoad(module, &load) or_return
		}
		if module.config.measureLoading {
			log.infof("Textures loaded on main thread = {}", time.stopwatch_duration(sw))
		}
	}
	if error_result != .NONE {
		error = error_result
		return
	}
	for &load in temp.loads {
		image: ^Image.DynamicImage
		switch value in load.key {
		case TFileImageName:
			image, _ = Dictionary.get(module.imageMap, value, true) or_return
		case string:
			image, _ = Dictionary.get(module.dynamicImageMap, value, true) or_return
		}
		image.texture = sdl3.CreateTexture(
			module.renderer,
			.ABGR8888,
			.STATIC,
			load.surface.w,
			load.surface.h,
		)
		if image.texture == nil {
			error = .FAILED_CREATION_TEXTURE_FROM_SURFACE
			return
		}
	}
	if module.config.measureLoading {
		log.infof("textures created = {}", time.stopwatch_duration(sw))
	}
	for &load in temp.loads {
		image: ^Image.DynamicImage
		switch value in load.key {
		case TFileImageName:
			image, _ = Dictionary.get(module.imageMap, value, true) or_return
		case string:
			image, _ = Dictionary.get(module.dynamicImageMap, value, true) or_return
		}
		if !sdl3.UpdateTexture(image.texture, nil, load.surface.pixels, load.surface.pitch) {
			error = .IMAGE_TEXTURE_UPDATE_FAILED
			return
		}
	}
	if module.config.measureLoading {
		log.infof("textures updated = {}", time.stopwatch_duration(sw))
	}

	for &load in temp.loads {
		image: ^Image.DynamicImage
		switch value in load.key {
		case TFileImageName:
			image, _ = Dictionary.get(module.imageMap, value, true) or_return
		case string:
			image, _ = Dictionary.get(module.dynamicImageMap, value, true) or_return
		}
		sdl3.SetTextureScaleMode(image.texture, .NEAREST)
	}
	if module.config.measureLoading {
		log.infof("textures mode set = {}", time.stopwatch_duration(sw))
	}

	for &load in temp.loads {
		sdl3.DestroySurface(load.surface)
	}
	if module.config.measureLoading {
		log.infof("load surfaces destroyed = {}", time.stopwatch_duration(sw))
	}
	return
}

@(require_results)
loadImages :: proc(module: ^Module($TFileImageName)) -> (error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	sw: time.Stopwatch
	time.stopwatch_start(&sw)
	jobs.initialize()
	defer jobs.shutdown()
	temp := createTempAsync(module) or_return
	if module.config.measureLoading {
		log.infof("Loading {} Dynamic + {} Files...", len(temp.dynamicKeys), len(temp.keys))
	}
	defer destroyTempAsync(&temp)
	loadFiles(module, &temp) or_return
	if module.config.measureLoading {
		log.infof("Dynamic Files Loaded = {}", time.stopwatch_duration(sw))
	}
	loadLoads(module, &temp) or_return
	if module.config.measureLoading {
		log.infof("Dynamic Textures Loaded = {}", time.stopwatch_duration(sw))
	}
	return
}
