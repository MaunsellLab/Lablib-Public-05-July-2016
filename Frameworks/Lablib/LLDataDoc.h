//
//  LLDataDoc.h
//  Lablib
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLDataEvents.h"
#import "LLDataEventDef.h"

#define kLLAutoreleaseIntervalS		10
#define	kLLInitialBufferSize		1000000
#define	LLDataFileCreator			'LLdi'
#define	LLDataFileType				'DAT6'

@interface LLDataDoc : NSDocument {
	NSMutableData 		*data;					// pointer to NSData (actual event buffer)
	BOOL				dataDefinitions;
	NSFileHandle 		*dataFileHandle;		// handle for writing data to a file
    NSMutableDictionary	*eventDict;				// Dictionary for event info indexed by name (putEvent)
    NSLock				*eventLock;
    NSMutableArray		*eventsByCode;			// Array for event info indexed by event code (getEvent)
	BOOL				eventsHaveDataDefs;		// indicated whether event definitions have data defintions
	NSString			*filePath;
	unsigned long 		lastRead;				// offset to next byte to write
    NSMutableArray		*observerArray;
    NSLock				*observerLock;
	BOOL				retainEvents;			// don't flush events after dispatch
	AbsoluteTime		startTime;
	NSDate              *startDate;
	unsigned long		threadingThreshold;
	BOOL				useDefaultDir;
}

- (void)addObserver:(id)anObserver;
- (BOOL)clearEventDefinitions;
- (void)clearEvents;
- (void)closeDataFile;
- (BOOL)createDataFile;
- (NSData *)dataFileHeaderData;
- (BOOL)defineEvents:(EventDef *)eventDefs number:(unsigned long)count;
- (BOOL)defineEvents:(EventDefinition *)eventDefs count:(unsigned long)numEvents;
- (void)dispatchEvents;
- (LLDataEventDef *)eventNamed:(NSString *)eventName;
- (void)eventToBuffer:(unsigned long)code dataPtr:(void *)pData bytes:(unsigned long)lengthBytes
					writeLength:(BOOL)writeLength;
- (NSString *)fileName; 
- (NSString *)filePath;
- (NSArray *)findViews:(NSView *)view respondingToSelector:(SEL)selector;
- (void)getEventBytes:(void *)pData length:(unsigned long)numBytes;
- (void)putEvent:(NSString *)eventKey;
- (void)putEvent:(NSString *)eventKey withData:(void *)pDdata;
- (void)putEvent:(NSString *)eventKey withData:(char *)pData lengthBytes:(long)length;
- (void)putEvent:(NSString *)eventKey withData:(char *)pData count:(long)count;
- (void)removeObserver:(id)anObserver;
- (void)setRetainEvents:(BOOL)state;
- (void)setThreadingThreshold:(unsigned long)threshold;
- (void)setUseDefaultDataDirectory:(BOOL)state;

@end
