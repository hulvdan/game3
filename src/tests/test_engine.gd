extends GutTest


func test_remove_all() -> void:
	var arr := [1, 3, 2, 1]
	bf.remove_all(arr, 1)
	assert(arr == [3, 2])

	arr = [1, 3, 2, 1]
	bf.unstable_remove_all(arr, 1)
	assert(arr == [2, 3])

	arr = [1, 3, 2, 1]
	bf.unstable_remove_all_by_key(arr, func(x): return x == 1)
	assert(arr == [2, 3])
