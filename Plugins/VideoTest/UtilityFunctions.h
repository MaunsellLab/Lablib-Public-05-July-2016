//
//  UtilityFunctions.h
//  Experiment
//
//  Created by John Maunsell on Fri Apr 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

#include "VT.h"

StimParams		*getStimParams(long stimType);
void			announceEvents(void);
void			requestReset(void);
void			reset(void);
BOOL			selectTrial(long *pIndex);
StimTrainData   *stimTrainParameters(double amplitudeUA);
double			spikeRateFromStimValue(double normalizedValue);
double			valueFromIndex(long index, StimParams *pStimParams);
