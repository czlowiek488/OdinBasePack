package Painter

import "../../../../Engine/Core/Command"
import "../../Math"

EntityMove :: struct {
	entityId:    int,
	newPosition: Math.Vector,
}

EntitiesMovedEvent :: Command.ListCommand(32, EntityMove)
