shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float wave = cos(FRAGCOORD.y * 7.15 + TIME) *0.1;
	//if(int(FRAGCOORD.y) % 2 == 0)
	//{
	//	COLOR.rgb -= cos(TIME/2.0)*0.1;
	//}
	COLOR.rgb += wave*0.4;
	//COLOR.r += sin(TIME * 1.2)*0.1;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
