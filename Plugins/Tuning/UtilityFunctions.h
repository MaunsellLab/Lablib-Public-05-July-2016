//
//  UtilityFunctions.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#include "TUN.h"

void		announceEvents(void);
NSPoint		azimuthAndElevationForStimIndex(long index);
void		requestReset(void);
void		reset(void);
float		spikeRateFromStimValue(float normalizedValue);
