//
//  RFMapUtilityFunctions.h
//  Experiment
//
//  Created by John Maunsell on Fri Apr 04 2003.
//  Copyright (c) 2004. All rights reserved.
//

#include "RF.h"

void			putParameterEvents(void);
void			requestReset(void);
void			reset(void);
BOOL			selectTrial(long *pIndex);
StimTrainData   *stimTrainParameters(double amplitudeUA);
double			spikeRateFromStimValue(double normalizedValue);
double			valueFromIndex(long index, StimParams *pStimParams);
