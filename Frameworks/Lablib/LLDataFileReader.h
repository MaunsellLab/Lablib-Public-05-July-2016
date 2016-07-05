//
//  LLDataReader.h
//  Lablib
//
//  Created by John Maunsell on Sun Jul 04 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLDataDoc.h"
#import "LLDataEventDef.h"
#import "LLIODevice.h"

@interface LLDataFileReader : NSObject <LLDataReader> {

    BOOL				allocated;
	NSMutableDictionary *bundledEvents;
	unsigned long		*cumulativeEnabledEvents;		// cumulative count of enabled events by trial
	unsigned long		currentEventIndex;
	BOOL				dataDefinitions;
    long				dataIndex;
	float				dataFormat;
	BOOL				*enabledEvents;
	unsigned long		*eventCounts;					// total count of each type of event
	NSMutableArray		*cumulativeEvents;				// count of each type of event for each trial
    NSMutableArray		*eventDesc;
	NSMutableArray		*eventsByCode;
	NSMutableDictionary	*eventsDict;
	NSString			*fileCreateDate;
	NSString			*fileCreateTime;
	NSData				*fileData;
    NSDate              *fileDate;
//    NSCalendarDate		*fileDate;
	NSString			*fileName;
	long				fileStartTime;
	long				firstDataEventIndex;
    long				lastIndex;
    long				lastLineRead;
    long				lastSampleTime[kADChannels];
	unsigned long		lineCounter;
	unsigned long		maxEventCount;
	unsigned long		maxEventDataBytes;
	unsigned long		maxEventNameLength;
	unsigned long		maxTrials;
    long				nextIndex;
	long				numEvents;
	long				sampleIntervalMS;
    long				spikeStartTime;
	DataEvent			theEvent;
	BOOL				*timedEvents;
	unsigned long		trialCount;
	NSMutableArray		*trialStartIndices;
	long				trialStartTime;
}

- (void)appendMatlabString:(NSString *)eventString toData:(NSMutableData *)data;
- (NSString *)arrayAsMatlabString:(NSArray *)array lValueString:(NSString *)lValueString;
- (long)bytesInDataEvent:(DataEvent *)pEvent;
- (void)countEvents;
- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes;
- (BOOL)dataBytes:(Ptr)buffer range:(NSRange)range;
- (BOOL)dataDefinitions;
- (void)dataDeviceMixError;
- (LLDataEventDef *)dataEventDefWithIndex:(long)index;
- (float)dataFormat;
- (unsigned long)dataIndex;
- (NSString *)dataString;
- (unsigned long)enabledEventsInFile;
- (unsigned long)eventCodeForEventName:(NSString *)name;
- (unsigned long *)eventCounts;
- (NSArray *)eventDataAsStrings:(DataEvent *)pEvent prefix:(NSString *)prefix
					suffix:(NSString *)suffix;
- (NSString *)eventTimeAsString:(DataEvent *)pEvent prefix:(NSString *)prefix
			suffix:(NSString *)suffix;
- (NSData *)eventsAsMatlabStrings; 
- (long)fileBytes;
- (NSString *)fileCreateDate;
- (NSString *)fileCreateTime;
- (NSData *)fileData;
//- (NSCalendarDate *)fileDate;
- (NSDate *)fileDate;
- (DataEvent *)findEventByIndex:(unsigned long)index line:(long *)pLine;
- (DataEvent *)findEventByLine:(unsigned long)line index:(long *)pIndex;
- (unsigned long)firstDataEventIndex;
- (id)initWithData:(NSData *)data;
- (long)length;
- (unsigned long)maxEventCount;
- (unsigned long)maxEventDataBytes;
- (unsigned long)maxEventNameLength;
- (long)numEvents;								// return the number of event definitions
- (DataEvent *)readEvent;
- (unsigned long)readEventCode;				
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
- (void)rewind;
- (void)setDataIndex:(unsigned long)newIndex;
- (void)setEnabledEvents:(BOOL *)enabledArray;
- (BOOL)setFileData:(NSData *)data;
- (void)writeBuffersToMatlab:(NSMutableData *)data prefix:(NSString *)prefix;

@end
