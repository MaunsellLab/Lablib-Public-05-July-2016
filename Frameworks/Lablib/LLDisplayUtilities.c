/*
* LLDisplayUtilities.c
* Lablib
*
*   Created by Geoff Ghose on Sat Dec 06 2003.
*   Copyright (c) 2003. All rights reserved.
* 
*/

#import "LLDisplayUtilities.h"
#import <math.h>
#import <stdio.h>

ColorPatches computeKdlColors(RGBDouble CIEx, RGBDouble CIEy) {

	ColorPatches calibratedColor;
	float bmr[4], bmg[4], bmb[4], r[3], g[3], b[3];
//	float bmcg, cardg, cardy, bmbcy;
	float cardg, cardy;
	float gbrb;
	float rede, greene, bluee;
	float x[3], y[3], z[3];
	float rg;
	int i;
        
	x[0] = CIEx.red;
	x[1] = CIEx.green;
	x[2] = CIEx.blue;
	y[0] = CIEy.red;
	y[1] = CIEy.green;
	y[2] = CIEy.blue;
	for (i = 0; i < 3; i++) {
		z[i] = 1 - x[i] - y[i];
	}
	
    //	red = (1.0 - z[BLU] / y[BLU]) / (z[GRN] / y[GRN] - 1.0) - (1.0 - x[BLU] / y[BLU]) / (x[GRN] / y[GRN] - 1.0);
    //	red /= (1.0 - x[RED] / y[RED]) / (x[GRN] / y[GRN] - 1.0) - (1.0 - z[RED] / y[RED]) / (z[GRN] / y[GRN] - 1.0);
    //	green = red * (1.0 - z[RED] / y[RED]) / (z[GRN] / y[GRN] - 1.0) + (1.0 - z[BLU] / y[BLU]) / (z[GRN] / y[GRN] - 1.0);
	for (i = 0; i < 3; i++) {
		r[i] = 0.15514 * x[i] + 0.54312 * y[i] - 0.03286 * z[i];
		g[i] = (-0.15514) * x[i] + 0.45684 * y[i] + 0.03286 * z[i];
		b[i] = 0.01608 * z[i];
	}		
	for (i = 0; i < 3;i++) {
		rg = r[i] + g[i];
		bmr[i] = r[i] / rg;
		bmg[i] = g[i] / rg;
		bmb[i] = b[i] / rg;
	}
	bmr[3] = 0.6654266;
	bmg[3] = 1.0 - bmr[3];
	bmb[3] = 0.0160806;
	cardg = (bmb[3] - bmb[2]) / (bmb[1] - bmb[2]);
	//bmcg = cardg * bmr[1] + (1.0 - cardg) * bmr[2];
    //	bmcr = 2.0 * bmr[3] - bmcg;
	calibratedColor.cardinalGreen.red = 0.0;
	calibratedColor.cardinalGreen.green = cardg;
	calibratedColor.cardinalGreen.blue = 1 - cardg;
	cardy = (bmr[3] - bmr[1]) / (bmr[0] - bmr[1]);
	//bmbcy = cardy * bmb[0] + (1.0 - cardy) * bmb[1];
    //	bmbcb = 2 * bmb[3] - bmbcy;
	calibratedColor.cardinalYellow.red = cardy;
	calibratedColor.cardinalYellow.green = 1 - cardy;
	calibratedColor.cardinalYellow.blue = 0.0;
	gbrb = (bmb[1] - bmb[2]) / (bmr[1] - bmr[2]);
	rede = bmb[3] - bmb[2] - (bmr[3] - bmr[2]) * gbrb;
	rede /= bmb[0] - bmb[2] - (bmr[0] - bmr[2]) * gbrb;
	greene = (bmb[2] - bmb[3]) / (bmb[2] - bmb[1]) + rede * (bmb[0] - bmb[2]) / (bmb[2] - bmb[1]);
	bluee = 1 - rede - greene;
	calibratedColor.equalEnergy.red = rede;
	calibratedColor.equalEnergy.green = greene;
	calibratedColor.equalEnergy.blue = bluee;

	return calibratedColor;
}

