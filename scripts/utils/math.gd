class_name Math

static func gcd(n1 : int, n2: int) -> int:
	var hcf : int = 1

	if n2 > n1:
		n1 = n1 + n2
		n2 = n1 - n2
		n1 = n1 - n2

	for i in range(1, n2 + 1): if n1 % i == 0 and n2 % i == 0: hcf = i

	return hcf
