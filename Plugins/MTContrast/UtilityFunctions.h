//
//  UtilityFunctions.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#include "MTC.h"

void			announceEvents(void);
NSPoint			azimuthAndElevationForStimIndex(long index);
float			contrastFromIndex(short index);
StimParams		*getStimParams(void);
void			putBlockDataEvents(long blocksDone);
void			requestReset(void);
void			reset(void);
BOOL			selectTrial(long *pIndex);
float			spikeRateFromStimValue(float normalizedValue);
long			stimPerBlock(void);
long			stimDoneThisBlock(long blocksDone);
long			repsDoneAtLoc(long loc);
void			updateBlockStatus(void);
float			valueFromIndex(long index, StimParams *pStimParams);
