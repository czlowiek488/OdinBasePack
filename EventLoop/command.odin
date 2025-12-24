package BasePackEventLoop

ListCommand :: struct($TSize: int, $TElement: typeid) {
	list:  [TSize]TElement,
	count: int,
}

@(require_results)
appendList :: proc(command: ^ListCommand($TSize, $TElement), element: TElement) -> (ok: bool) {
	if command.count >= TSize {
		return
	}
	command.list[command.count] = element
	command.count += 1
	ok = true
	return
}
