class_name Math

static func gcd(n1 : int, n2: int) -> int:
	var hcf : int = 1

	if n2 > n1:
		n1 = n1 + n2
		n2 = n1 - n2
		n1 = n1 - n2

	for i in range(1, n2 + 1): if n1 % i == 0 and n2 % i == 0: hcf = i

	return hcf


static func calc_fade_distance(size : Vector3i, circular_range : int) -> int:
	var vector_pivot : int = [size.x, size.y, size.z].min()

	@warning_ignore('integer_division') # Don't ask me how I get this. I don't know either.
	return int(ceil(2 * sqrt(circular_range) + vector_pivot * ((circular_range / vector_pivot) / 2)))
