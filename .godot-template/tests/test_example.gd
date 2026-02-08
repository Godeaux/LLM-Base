class_name TestExample extends GdUnitTestSuite

## Starter test to verify GdUnit4 is working.
## Replace this with real tests as game systems are built.


func test_gdunit4_is_working() -> void:
	assert_bool(true).is_true()


func test_basic_math() -> void:
	assert_int(2 + 2).is_equal(4)
