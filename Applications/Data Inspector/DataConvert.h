/*
 *  Data Inspector.h
 *  Data Inspector
 *
 *  Created by John Maunsell on Sun Jul 28 2002.
 *  Copyright (c) 2002. All rights reserved.
 *
 */

#define kEventNameMax 		31			// maximum length of an event name
#define kFontSizeToUse		smallSystemFontSize
#define kMaxEvents			256			// maximum number of data events
/*
typedef struct event {					// data for one event
	unsigned char type;				// type of event
	long dataBytes;					// number of data bytes in this event
	char *pData;					// pointer to data buffer
	unsigned long dataBufferLength;			// length of data buffer in bytes
	long time;					// time since start of the last trial
	long timeOfDay;					// absolute time
} DataEvent;
*/
typedef struct dataevent {	
	char name[kEventNameMax];			// C string name of event
	long dataBytes;					// Number of data bytes
} DataEventID;

typedef short FixWindow[4];				// definition for a fixation window
/*
typedef struct fixWindowData {
    short index;
    FixWindow window;
} FixWindowData;
*/
typedef struct sampleData {				// description of event type
    char channel;					// sample channel
    short value;					// sample value
} SampleData;

typedef struct spikedata {				// description of event type
    short channel;					// spike channel
    long time;						// spike time
} SpikeData;

typedef BOOL EnabledArray[kMaxEvents];


