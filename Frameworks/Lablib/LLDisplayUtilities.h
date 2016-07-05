/*
 *  DisplayUtilities.h
 *  Lablib
 *
 *  Created by Geoff Ghose on Sat Dec 06 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

enum {RED, GRN, BLU} ColorNames;

typedef struct {
    double red;
    double green;
    double blue;
} RGBDouble;

typedef struct {
    float red;
    float green;
    float blue;
} RGBFloat;

typedef struct {

	RGBDouble	cardinalGreen;
	RGBDouble	cardinalYellow;
	RGBDouble	equalEnergy;
} ColorPatches;

ColorPatches computeKdlColors(RGBDouble CIEx, RGBDouble CIEy);



