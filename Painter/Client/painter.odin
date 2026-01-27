package PainterClient

import "../../../OdinBasePack"
import "../../Engine/Time"
import TimeClient "../../Engine/Time/Client"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/SparseSet"
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	@(static) maybeStringId: Maybe(Painter.StringId)
	fps := TimeClient.getFps(module.timeModule) or_return
	potentialFps := TimeClient.getPotentialFps(module.timeModule) or_return
	fpsText := fmt.aprintf("{} / {}", fps, potentialFps, allocator = context.temp_allocator)
	if stringId, present := maybeStringId.?; present {
		removeString(module, stringId) or_return
	}
	maybeStringId = createString(
		module,
		{.USER_INTERFACE, 100_000, nil, .CAMERA, {.RED, 1, 1, nil}},
		{
			{
				{1, module.config.windowSize.y / module.config.tileScale - 10},
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
	RendererClient.updateAllRenderOrder(module.rendererModule) or_return
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	if module.config.drawFps {
		drawFps(module) or_return
	}
	drawPaints(module, cameraPosition) or_return
	RendererClient.drawScreen(module.rendererModule) or_return
	return
}
