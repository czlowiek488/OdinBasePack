package Renderer

import "../../Math"

LineId :: distinct PaintId

LineConfig :: struct #all_or_none {
	start, end: Math.Vector,
}

Line :: struct #all_or_none {
	lineId: LineId,
	config: LineConfig,
}
