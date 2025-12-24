package PainterClient

import "../../../../OdinBasePack"
import "../../../Engine/Time"
import TimeClient "../../../Engine/Time/Client"
import "../../../Math"
import "../../../Memory/SparseSet"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "core:fmt"


@(private)
@(require_results)
drawFps :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	@(static) maybeStringId: Maybe(Painter.StringId)
	fps: Time.Fps
	fps, err = TimeClient.getFps(module.timeModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	potentialFps: Time.Fps
	potentialFps, err = TimeClient.getPotentialFps(module.timeModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	fpsText := fmt.aprintf("{} / {}", fps, potentialFps, allocator = context.temp_allocator)
	if stringId, present := maybeStringId.?; present {
		removeString(module, stringId) or_return
	}
	color: Renderer.Color
	color, err = Renderer.getColorFromName(.RED)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	maybeStringId = createString(
		module,
		{.ITEM_PANEL_3, nil, .CAMERA, color},
		{
			{
				{
					1,
					module.config.imageConfig.windowSize.y / module.config.imageConfig.tileScale -
					10,
				},
				{f32(len(fpsText)) * 5, 10},
			},
			fpsText,
		},
	) or_return
	return
}


@(require_results)
drawPaints :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	cameraPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	RendererClient.updateCamera(module.rendererModule, cameraPosition) or_return
	RendererClient.clearScreen(module.rendererModule) or_return
	for renderOrder, layerId in RendererClient.getRenderOrder(module.rendererModule) or_return {
		for &order in SparseSet.list(renderOrder) or_return {
			paint, _ := RendererClient.getPaint(
				module.rendererModule,
				order.paintId,
				Renderer.PaintData(TShapeName),
				false,
			) or_return
			switch &paint in cast(^Renderer.PaintUnion(TShapeName))paint {
			case Renderer.Paint(Renderer.PieMask, TShapeName):
				RendererClient.drawPieMask(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.String, TShapeName):
				RendererClient.drawString(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Rectangle, TShapeName):
				RendererClient.drawRectangle(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Circle, TShapeName):
				RendererClient.drawCircle(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Line, TShapeName):
				RendererClient.drawLine(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Triangle, TShapeName):
				RendererClient.drawTriangle(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Texture(TShapeName), TShapeName):
				RendererClient.drawTexture(module.rendererModule, &paint) or_return
			}
		}
	}
	return
}

@(require_results)
drawAll :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	cameraPosition: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if module.config.drawFps {
		drawFps(module) or_return
	}
	err = drawPaints(module, cameraPosition)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = RendererClient.drawScreen(module.rendererModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
