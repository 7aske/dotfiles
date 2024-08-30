#!/usr/bin/env bash

xrandr | grep '\bconnected\b' | awk '
{
	if ($3 == "primary") {
		split($4, params, "+")
	} else {
		split($3, params, "+")
	}
	split(params[1], res, "x")
	xpos = params[2] / res[1]
	ypos = params[3] / res[2]
	w = res[1]
	h = res[2]
	#print xpos "\t" ypos "\t" w "\t" h "\t" $1
	data[xpos, ypos] = $1 "(" w "x" h ")"
	if (ypos > rows) {
		rows = ypos
	}
}
END{
	for (y = 0; y < rows + 1; y++) {
		for (x = 0; x < NR; x++) 
			printf("%-18s ", data[x, y])
		printf("\n")
	}
}
'
