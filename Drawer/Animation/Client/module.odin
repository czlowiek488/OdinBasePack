package AnimationClient

import "../../../../OdinBasePack"
import "../../../Memory/Dictionary"
import "../../Animation"
import ShapeClient "../../Shape/Client"
import "base:intrinsics"

ModuleConfig :: struct($TAnimationName: typeid, $TShapeName: typeid) {
	animations: map[TAnimationName]Animation.AnimationConfig(TShapeName, TAnimationName),
}

Module :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
	$TAnimationName: typeid,
) where intrinsics.type_is_enum(TAnimationName)
{
	shapeModule:         ^ShapeClient.Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	config:              ModuleConfig(TAnimationName, TShapeName),
	//
	animationMap:        map[TAnimationName]Animation.Animation(TShapeName, TAnimationName),
	dynamicAnimationMap: map[string]Animation.Animation(TShapeName, TAnimationName),
	allocator:           OdinBasePack.Allocator,
	created:             bool,
}

@(require_results)
createModule :: proc(
	shapeModule: ^ShapeClient.Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	config: ModuleConfig($TAnimationName, TShapeName),
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TFileImageName, TBitmapName, TMarkerName, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	module.shapeModule = shapeModule
	module.config = config
	module.allocator = allocator
	//
	module.animationMap = Dictionary.create(
		TAnimationName,
		Animation.Animation(TShapeName, TAnimationName),
		module.allocator,
	) or_return
	module.dynamicAnimationMap = Dictionary.create(
		string,
		Animation.Animation(TShapeName, TAnimationName),
		module.allocator,
	) or_return
	return
}

@(require_results)
loadAnimations :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	for animationName, animationConfig in module.config.animations {
		Dictionary.set(
			&module.animationMap,
			animationName,
			createAnimation(animationConfig) or_return,
		) or_return
	}
	module.created = true
	return
}
