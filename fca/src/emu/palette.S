@@@ 
@@@ http://nesdev.parodius.com/pal.txt ��Ȥ�
@@@ 

#define RGB(r, g, b) .long ((r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10))

	ALIGN

nes_palette:	
	RGB(117,117,117)
	RGB( 39, 27,143)
	RGB(  0,  0,171)
	RGB( 71,  0,159)
	RGB(143,  0,119)
	RGB(171,  0, 19)
	RGB(167,  0,  0)
	RGB(127, 11,  0)
	RGB( 67, 47,  0)
	RGB(  0, 71,  0)
	RGB(  0, 81,  0)
	RGB(  0, 63, 23)
	RGB( 27, 63, 95)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(188,188,188)
	RGB(  0,115,239)
	RGB( 35, 59,239)
	RGB(131,  0,243)
	RGB(191,  0,191)
	RGB(231,  0, 91)
	RGB(219, 43,  0)
	RGB(203, 79, 15)
	RGB(139,115,  0)
	RGB(  0,151,  0)
	RGB(  0,171,  0)
	RGB(  0,147, 59)
	RGB(  0,131,139)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(255,255,255)
	RGB( 63,191,255)
	RGB( 95,151,255)
	RGB(167,139,253)
	RGB(247,123,255)
	RGB(255,119,183)
	RGB(255,119, 99)
	RGB(255,155, 59)
	RGB(243,191, 63)
	RGB(131,211, 19)
	RGB( 79,223, 75)
	RGB( 88,248,152)
	RGB(  0,235,219)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(255,255,255)
	RGB(171,231,255)
	RGB(199,215,255)
	RGB(215,203,255)
	RGB(255,199,255)
	RGB(255,199,219)
	RGB(255,191,179)
	RGB(255,219,171)
	RGB(255,231,163)
	RGB(227,255,163)
	RGB(171,243,191)
	RGB(179,255,207)
	RGB(159,255,243)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
	RGB(  0,  0,  0)
