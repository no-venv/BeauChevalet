local div = function(n)
	return n/16
end

return {
	_4x4 = {
		{div(0), div(12),div(03),div(15)},
		{div(8), div(04),div(11),div(07)},
		{div(2), div(14),div(01),div(13)},
		{div(10),div(06),div(09),div(05)}
	};
	
	_4x4_random = {
		{div(0), div(12),div(14),div(15)},
		{div(8), div(04),div(7),div(09)},
		{div(9), div(4),div(06),div(13)},
		{div(10),div(06),div(09),div(05)}
	};
}