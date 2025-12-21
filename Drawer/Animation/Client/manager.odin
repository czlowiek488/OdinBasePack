package AnimationClient

import "../../../../OdinBasePack"
import "../../../Dictionary"
import "../../Animation"
import ShapeClient "../../Shape/Client"
import "base:intrinsics"

Manager :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
	$TAnimationName: typeid,
) where intrinsics.type_is_enum(TAnimationName)
{
	shapeManager:        ^ShapeClient.Manager(
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
	),
	animationConfigMap:  map[TAnimationName]Animation.AnimationConfig(TShapeName, TAnimationName),
	//
	animationMap:        map[TAnimationName]Animation.Animation(TShapeName, TAnimationName),
	dynamicAnimationMap: map[string]Animation.Animation(TShapeName, TAnimationName),
	allocator:           OdinBasePack.Allocator,
	created:             bool,
}

@(require_results)
createManager :: proc(
	shapeManager: ^ShapeClient.Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	animationConfigMap: map[$TAnimationName]Animation.AnimationConfig(TShapeName, TAnimationName),
	allocator: OdinBasePack.Allocator,
) -> (
	manager: Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	manager.shapeManager = shapeManager
	manager.animationConfigMap = animationConfigMap
	manager.allocator = allocator
	//
	manager.animationMap = Dictionary.create(
		TAnimationName,
		Animation.Animation(TShapeName, TAnimationName),
		manager.allocator,
	) or_return
	manager.dynamicAnimationMap = Dictionary.create(
		string,
		Animation.Animation(TShapeName, TAnimationName),
		manager.allocator,
	) or_return
	return
}

@(require_results)
initializeManager :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	for animationName, animationConfig in manager.animationConfigMap {
		Dictionary.set(
			&manager.animationMap,
			animationName,
			createAnimation(animationConfig) or_return,
		) or_return
	}
	manager.created = true
	return
}
