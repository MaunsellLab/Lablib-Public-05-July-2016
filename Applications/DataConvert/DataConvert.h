/*
 *  DataConvert.h
 *  DataConvert
 *
 *  Created by John Maunsell on Sun Jul 28 2002.
 *  Copyright (c) 2002. All rights reserved.
 *
 */

#define kFontSizeToUse		smallSystemFontSize

typedef short FixWindow[4];				// definition for a fixation window

typedef struct sampleData {				// description of event type
    char channel;					// sample channel
    short value;					// sample value
} SampleData;

typedef struct spikedata {				// description of event type
    short channel;					// spike channel
    long time;						// spike time
} SpikeData;

extern NSString *DCDataFormatKey;
extern NSString *DCOverwriteMatlabFilesKey;
extern NSString *DCShowAddressKey;
extern NSString *DCShowDataKey;
extern NSString *DCShowTimeKey;
extern NSString *DCShowTimeOfDayKey;

