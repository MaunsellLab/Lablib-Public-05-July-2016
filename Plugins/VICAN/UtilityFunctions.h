//
//  UtilityFunctions.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#include "VI.h"

void			announceEvents(void);
NSPoint         azimuthAndElevationForStimLoc(StimLoc loc, TaskState state);
void			requestReset(void);
void			reset(void);
float			spikeRateFromStimDesc(StimDesc *pSD);
float			spikeRateSpontaneous(void);
