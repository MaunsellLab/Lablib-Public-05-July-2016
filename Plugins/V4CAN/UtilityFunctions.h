//
//  UtilityFunctions.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#include "VCAN.h"

void			announceEvents(void);
NSPoint         azimuthAndElevationForStimLoc(StimLoc loc, TaskState state);
void			requestReset(void);
void			reset(void);
float			spikeRateFromStimDesc(StimDesc *pSD);
float			spikeRateSpontaneous(void);
void			updateBlockStatus(void);
