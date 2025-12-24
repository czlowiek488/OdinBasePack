package AutoSet

import "core:testing"

@(private = "file")
TestData :: struct {}

@(test)
createAndRemoveAutoSetTest :: proc(t: ^testing.T) {
	testSet, err := create(int, TestData, context.allocator)
	testing.expect(t, err == .NONE)
	err = destroy(testSet, context.allocator)
	testing.expect(t, err == .NONE)
}
