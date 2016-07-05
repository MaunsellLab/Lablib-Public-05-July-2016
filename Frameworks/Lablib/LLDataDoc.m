//
//  LLDataDoc.m
//  Lablib
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003-2006. All rights reserved.
//

#import "LLDataDoc.h"
#import "LLStandardFileNames.h"
#import "LLSystemUtil.h"

#define	kDefaultThreadingThreshold	8192

@implementation LLDataDoc

- (void) addObserver:(id)anObserver {

    if ([observerArray indexOfObject:anObserver] == NSNotFound) {
        [observerLock lock];
        [observerArray addObject:anObserver];
        [observerLock unlock];
    }
}

- (BOOL)createDataFile;
{
	NSDictionary *attr;
	NSString *dirPath;
	NSFileManager *manager;
	NSSavePanel *savePanel;
    NSURL *fileURL;
    NSAlert *theAlert;
    
	manager = [NSFileManager defaultManager];
	
// First find or create the default data dir

	if (useDefaultDir) {
		if ((dirPath = [LLStandardFileNames defaultDirPath]) == nil) {
			useDefaultDir = NO;
		}
//		fileName = [LLStandardFileNames defaultFileName];
	}
	else {
		dirPath = nil;
//		fileName = [[NSUserDefaults standardUserDefaults] stringForKey:LLLastFileNameKey];
	}
	
// Run the save panel to get the user's input

	savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:@"Save Data"];
	[savePanel setAllowedFileTypes:[LLStandardFileNames allowedFileTypes]];
	if ([savePanel runModal] != NSModalResponseOK) {
//        if ([savePanel runModalForDirectory:dirPath file:fileName] != NSOKButton) {
		return NO;
	}
	
// Create the file

	fileURL = [savePanel URL];
	filePath = [fileURL path];
	[filePath retain]; 
	if ([manager fileExistsAtPath:filePath]) {
		[manager removeItemAtPath:filePath error:NULL];
	}
	attr = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedLong:LLDataFileCreator], NSFileHFSCreatorCode, 
				[NSNumber numberWithUnsignedLong:LLDataFileType], NSFileHFSTypeCode, nil];
	if (![[NSFileManager defaultManager] createFileAtPath:filePath
								contents:nil attributes:attr]) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDisplayPhysical"];
        [theAlert setInformativeText:[NSString stringWithFormat:@"Unable to create file %@", filePath]];
        [theAlert runModal];
        [theAlert release];
//		NSRunAlertPanel(@"LLDataDoc",  @"Unable to create file %@", @"OK", nil, nil, filePath);
        filePath = nil;
		return NO;
	}
	[[NSUserDefaults standardUserDefaults] setObject:[[filePath pathComponents] lastObject] 
						forKey:LLLastFileNameKey];

	dataFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
	[dataFileHandle retain];
	[dataFileHandle writeData:[self dataFileHeaderData]];
	
	[self clearEvents];						// flush all the events in the buffer

	return YES;
}

// Clear all known event definitions

- (BOOL)clearEventDefinitions;
{
	if (dataFileHandle != nil) {
		return NO;
	}
    [eventLock lock];
	[eventDict removeAllObjects];
	[eventsByCode removeAllObjects];
	[data setLength:0];
	lastRead = [data length];
	dataDefinitions = NO;
    [eventLock unlock];
	return YES;
}

// Discard all the events in the buffer

- (void)clearEvents;
{
	[eventLock lock];
	[data setLength:0];
	lastRead = [data length];
	[eventLock unlock];
}

- (void)closeDataFile;
{
	[dataFileHandle closeFile];
	[dataFileHandle release];
	[filePath release];
	filePath = nil;
	dataFileHandle = nil;
}

// Write the header that goes into every data file.  The headerString provides information about whether the binary
// data file was created in 32- or 64-bit mode.

- (NSData *)dataFileHeaderData;
{
	unsigned char stringLength;
	long index, events, dataBytes;
	LLDataEventDef *eventDef;
	NSString *headerString, *dateString;
	NSMutableData *headerData;
//	NSCalendarDate *today;
#ifdef __LP64__
    NSAlert *theAlert;
#endif
    
	headerData = [[[NSMutableData alloc] init] autorelease];
#ifdef __LP64__
    if (!dataDefinitions) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:@"Data definitions are required in 64-bit mode"];
        [theAlert runModal];
        [theAlert release];
        //        NSRunAlertPanel(@"LLDataDoc",  @"Data definitions are required in 64-bit mode", @"OK", nil, nil, nil);
        exit(0);
    }
	headerString = [NSString stringWithFormat:@"\007\005006.3"];
#else
	headerString = [NSString stringWithFormat:@"\007\005006.%1d", (dataDefinitions) ? 2 : 0];
#endif
	[headerData appendBytes:[headerString cStringUsingEncoding:NSUTF8StringEncoding] length:strlen([headerString cStringUsingEncoding:NSUTF8StringEncoding])];	// format specifier
	events = [eventsByCode count];
	[headerData appendBytes:&events length:sizeof(events)];						// number of events defined

// Write the event descriptions.  Each description consists of its name in pascal string format, and
// the number of data bytes as a long int.  If there are data definitions, these are written
// immediately after these entries
 
	for (index = 0; index < events; index++)	{
		eventDef = [eventsByCode objectAtIndex:index];
		stringLength = [[eventDef name] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		[headerData appendBytes:&stringLength length:sizeof(stringLength)];		// bytes in char name
		[headerData appendBytes:[[eventDef name] cStringUsingEncoding:NSUTF8StringEncoding] length:stringLength];	// name bytes
		dataBytes = [eventDef dataBytes];										// can be negative
		[headerData appendBytes:&dataBytes length:sizeof(dataBytes)];			// data bytes
		[headerData appendData:[eventDef dataDefinition]];
	}

// Write the date and time as strings
	
//	today = [NSCalendarDate calendarDate];
//	dateString = [today descriptionWithCalendarFormat:@"%B %d, %Y"];
    dateString = [LLSystemUtil formattedDateString:[NSDate date] format:@"MMMM dd, yyyy"];
	stringLength = [dateString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[headerData appendBytes:&stringLength length:sizeof(stringLength)];			// number of bytes in char name
	[headerData appendBytes:[dateString cStringUsingEncoding:NSUTF8StringEncoding] length:stringLength];			// name bytes

//	dateString = [today descriptionWithCalendarFormat:@"%H:%M:%S"];
    dateString = [LLSystemUtil formattedDateString:[NSDate date] format:@"HH:mm:ss"];
	stringLength = [dateString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[headerData appendBytes:&stringLength length:sizeof(stringLength)];			// number of bytes in char name
	[headerData appendBytes:[dateString cStringUsingEncoding:NSUTF8StringEncoding] length:stringLength];			// name bytes
	
	return headerData;
}

- (void) dealloc {

	[data release];
    [eventDict release];
    [eventsByCode release];
    [eventLock release];
    [observerLock release];
    [observerArray release];
    [startDate release];
    [super dealloc];
}

/*
Add event definitions.  Definitions are stored in an NSDictionary.  The NSString that
is the name of the event serves as its key.  The only two values that need to be recorded
are its code (event codes are integers that increase from 0), and the number of data bytes
(a value of -1 specifies an event with varying numbers of data bytes from instance to instance.
*/

- (BOOL)defineEvents:(EventDef *)eventDefs number:(unsigned long)numEvents {

    short index;
	EventDef *pDef;
	LLDataEventDef *dataEventDef;
    NSAlert *theAlert;
   
	if (numEvents < 1) {
		return YES;
	}
	if ([eventsByCode count] > 0 && eventsHaveDataDefs) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:@"Attempting to mix events with and without data definitions."];
        [theAlert runModal];
        [theAlert release];
//		NSRunAlertPanel(@"LLDataDoc",  @"Attempting to mix events with and without data definitions.",
//					@"OK", nil, nil);
		exit(0);
	}
	eventsHaveDataDefs = NO;
    [eventLock lock];
    for (index = 0; index < numEvents; index++) {
		pDef = &eventDefs[index];
		if ([eventDict objectForKey:pDef->name] != nil) {
            theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"LLDataDoc"];
            [theAlert setInformativeText:[NSString stringWithFormat:
                @"Attempt to define event \"%@\" more than once (ignored).", pDef->name]];
            [theAlert runModal];
            [theAlert release];
//			NSRunAlertPanel(@"LLDataDoc",  @"Attempt to define event \"%@\" more than once (ignored).",
//					@"OK", nil, nil, pDef->name);
		}
		else {
			dataEventDef = [[[LLDataEventDef alloc] initWithCode:[eventsByCode count]
				name:pDef->name dataBytes:pDef->dataBytes] autorelease];
			[eventsByCode addObject:dataEventDef];
			[eventDict setObject:dataEventDef forKey:pDef->name];
		}
    }
    [eventLock unlock];
    return YES;
}

/*
Add event definitions.  Definitions are stored in an NSDictionary.  The NSString that
is the name of the event serves as its key.  The only two values that need to be recorded
are its code (event codes are integers that increase from 0), and the number of data bytes
(a value of -1 specifies an event with varying numbers of data bytes from instance to instance.
This variant accepts only events definitions that include data definitions.
*/

- (BOOL)defineEvents:(EventDefinition *)eventDefs count:(unsigned long)numEvents;
{
    short index;
	EventDefinition *pDef;
	LLDataEventDef *dataEventDef;
    NSAlert *theAlert;
   
	if (numEvents < 1) {
		return YES;
	}
	if ([eventsByCode count] > 0 && !eventsHaveDataDefs) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:@"Attempting to mix events with and without data definitions."];
        [theAlert runModal];
        [theAlert release];
//		NSRunAlertPanel(@"LLDataDoc",  @"Attempting to mix events with and without data definitions.",
//					@"OK", nil, nil);
		exit(0);
	}
	eventsHaveDataDefs = YES;
    [eventLock lock];
    for (index = 0; index < numEvents; index++) {
		pDef = &eventDefs[index];
		if ([eventDict objectForKey:pDef->name] != nil) {
            theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"LLDataDoc"];
            [theAlert setInformativeText:[NSString stringWithFormat:
                                          @"Attempt to define event \"%@\" more than once (ignored).", pDef->name]];
            [theAlert runModal];
            [theAlert release];
//			NSRunAlertPanel(@"LLDataDoc",  @"Attempt to define event \"%@\" more than once (ignored).",
//					@"OK", nil, nil, pDef->name);
		}
		else {
//			if (&pDef->definition == 0) {
//                theAlert = [[NSAlert alloc] init];
//                [theAlert setMessageText:@"LLDataDoc"];
//                [theAlert setInformativeText:[NSString stringWithFormat:
//                                              @"Attempt to define event \"%@\" with no data description.", pDef->name]];
//                [theAlert runModal];
//                [theAlert release];
////				NSRunAlertPanel(@"LLDataDoc",  @"Attempt to define event \"%@\" with no data description",
////					@"OK", nil, nil, pDef->name);
//				exit(0);
//			}
			dataEventDef = [[[LLDataEventDef alloc] initWithCode:[eventsByCode count]
					name:pDef->name elementBytes:pDef->elementBytes
					dataDefinition:&pDef->definition] autorelease];
			[eventsByCode addObject:dataEventDef];
			[eventDict setObject:dataEventDef forKey:pDef->name];
		}
    }
	dataDefinitions = YES;
    [eventLock unlock];
    return YES;
}

// Return event with a given name

- (LLDataEventDef *)eventNamed:(NSString *)eventName;
{
    return [eventDict objectForKey:eventName];
}

// Write one data event into the event buffer

- (void) eventToBuffer:(unsigned long)code dataPtr:(void *)pData bytes:(unsigned long)lengthBytes
					writeLength:(BOOL)writeLength;
{
    unsigned long eventTimeMS;
    unsigned char charCode;
    unsigned short shortCode;
    unsigned long numEvents;
	NSMutableData *eventData;
	
//	eventTimeMS = UnsignedWideToUInt64(AbsoluteDeltaToNanoseconds(UpTime(), startTime)) / 1000000.0;
	eventTimeMS = -[startDate timeIntervalSinceNow] * 1000.0;
	eventData = [[NSMutableData alloc] init];

// Start the event with the code for the event.  The number of bytes used depends
// on the number of events defined.

	numEvents = [eventDict count];
    if (numEvents < 0x100) {					// Bytes for the event code
        charCode = code;
        [eventData appendBytes:(void *)&charCode length:sizeof(charCode)];
    }
    else if (numEvents < 0x10000) {
        shortCode = code;
        [eventData appendBytes:(void *)&shortCode length:sizeof(shortCode)];
    }
    else {
        [eventData appendBytes:(void *)&code length:sizeof(code)];
    }

// On variable length events, the length of the data must be inserted.
// NB: The length might be zero, so we must write the length in all cases

	if (writeLength) {
		[eventData appendBytes:&lengthBytes length:sizeof(unsigned long)];
	}
	
// If there are data, write the data.  

    if (lengthBytes > 0) {
        [eventData appendBytes:pData length:lengthBytes];
    }
	[eventData appendBytes:(void *)&eventTimeMS length:sizeof(unsigned long)];

// If the eventData is big, we use a separate thread to put it into the buffer.  Otherwise
// insert it into the buffer(s) in line here. 

	if (lengthBytes >= threadingThreshold) {
		[NSThread detachNewThreadSelector:@selector(threadedEventToBuffer:) toTarget:self withObject:eventData];
		// Don't release eventData; it will be released by threadedEventToBuffer
	}
	else {
		[eventLock lock];
		[data appendData:eventData];
		if (dataFileHandle != nil) {
			[dataFileHandle writeData:eventData];
		}
		[eventLock unlock];
		[eventData release];
	}
}

- (void)dispatchEvents;
{
    unsigned char charCode;
    unsigned short shortCode;
    unsigned long eventCode, numBytes, numEvents, obs, eTime;
	long dataBytes;
    NSData *eventData;
    NSNumber *eventTime;
	LLDataEventDef *eventDef;
    id anObserver;
	NSAutoreleasePool *threadPool;
	NSDate *nextRelease;
    SEL methodSelector;
    NSAlert *theAlert;
    
// Initialize and get the start time for this schedule

    threadPool = [[NSAutoreleasePool alloc] init];
	nextRelease = [[NSDate alloc] initWithTimeIntervalSinceNow:kLLAutoreleaseIntervalS];
    
    for (; data != nil; ) {
		[eventLock lock];											// Lock before check starts
		if (lastRead < [data length]) {								// Undispatched event?

// Get the event code from the buffer

            numEvents = [eventDict count];							// Get event code
            if (numEvents < 0x100) {
                [self getEventBytes:(void *)&charCode length:sizeof(charCode)];
                eventCode = charCode;
            }
            else  if (numEvents < 0x10000) {
                [self getEventBytes:(void *)&shortCode length:sizeof(shortCode)];
                eventCode = shortCode;
            }
            else {
                [self getEventBytes:(void *)&eventCode length:sizeof(eventCode)];
            }

// Use the code to get the description of the event (name, number of bytes)

			eventDef = [eventsByCode objectAtIndex:eventCode];
			if ([eventDef code] != eventCode) {
                theAlert = [[NSAlert alloc] init];
                [theAlert setMessageText:@"LLDataDoc"];
                [theAlert setInformativeText:[NSString stringWithFormat:
                                @"dispatchEvents: Event \"%@\" code mismatch (%ld v. %ld).",
                                [eventDef name], [eventDef code], eventCode]];
                [theAlert runModal];
                [theAlert release];
//				NSRunAlertPanel(@"LLDataDoc", @"dispatchEvents: Event \"%@\" code mismatch (%ld v. %ld).",
//					@"OK", nil, nil, [eventDef name], [eventDef code], eventCode);
				exit(0);
			}

// Get the event data from the buffer, if this event has data

			dataBytes = [eventDef dataBytes];
            if (dataBytes == 0) {
               eventData = nil;
            }
            else {
                if (dataBytes > 0) {
                    numBytes = dataBytes;							// Fixed length data, get length
                }
                else {												// Variable length data, get length
                    [self getEventBytes:(void *)&numBytes length:sizeof(unsigned long)];
                }
                eventData = [data subdataWithRange:NSMakeRange(lastRead, numBytes)];
                [eventData retain];
                lastRead += numBytes;
            }

// Get the event time

            [self getEventBytes:&eTime length:sizeof(unsigned long)];
            eventTime = [NSNumber numberWithUnsignedLong:eTime];
            [eventTime retain];
            [eventLock unlock];										// Free lock while we dispatch data bytes
            
            // Dispatch the event to all observers that accept it

            methodSelector = NSSelectorFromString([NSString stringWithFormat:@"%@:eventTime:", [eventDef name]]);
            for (obs = 0; obs < [observerArray count]; obs++) {
                anObserver = [observerArray objectAtIndex:obs];
                if ([anObserver respondsToSelector:methodSelector]) {
                    [anObserver performSelector:methodSelector withObject:eventData withObject:eventTime];
                }
            }

// Clean up this event, then go look for more

            [eventTime release];
			[eventData release];
        }        
        else {														// No events left, sleep
			if (!retainEvents) {                                    // If we're not retaining events, clear the buffer
                [data setLength:0];                                 // Not safe to use clearEvents, because events
                lastRead = [data length];                           // might get posted between the unlock and lock.
			}
            [eventLock unlock];
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.025]];
			if ([nextRelease timeIntervalSinceNow] < 0.0) {
				[nextRelease release];
				nextRelease = [[NSDate alloc] initWithTimeIntervalSinceNow:kLLAutoreleaseIntervalS];
				[threadPool release];
				threadPool = [[NSAutoreleasePool alloc] init];
			}
		}
	}
	[nextRelease release];
    [threadPool release];
}

- (NSString *)fileName { 

	if (filePath == nil) {
		return nil;
	}
	else {
		return [[filePath pathComponents] lastObject];
	}
} 

- (NSString *)filePath {

	return filePath;
}

// Check all views in an NSView hiearchy for those that respond to a particular selector.
// This is used to find the NSViews in a window that are will accept data events (using
// @selector(acceptsDataEvents)).  This function calls itself recursively to go down
// all the branches of the view hierarchy.

- (NSArray *)findViews:(NSView *)view respondingToSelector:(SEL)selector {

    long v;
    NSArray *returnArray;
    NSMutableArray *responders = nil;
    
    responders = [[NSMutableArray alloc] init];
    if ([view respondsToSelector:selector]) {
        [responders addObject:view];
    }
    if ([view subviews] != nil) {
        for (v = 0; v < [[view subviews] count]; v++) {
        	returnArray = [self findViews:[[view subviews] objectAtIndex:v] respondingToSelector:selector];
            if (returnArray != nil) {
                [responders addObjectsFromArray:returnArray];
            }
        }
    }
    returnArray = ([responders count] > 0) ? [NSArray arrayWithArray:responders] : nil;
    [responders release];
    return returnArray;
}


// Read bytes from the event data buffer.  This method assumes that the eventLock has already been set

- (void) getEventBytes:(void *)pData length:(unsigned long)numBytes;
{
    [data getBytes:pData range:NSMakeRange(lastRead, numBytes)];
    lastRead += numBytes;
}

- (id)init;
{
    if ((self = [super init])) {
        data = [[NSMutableData alloc] initWithCapacity:kLLInitialBufferSize];
        lastRead = [data length];
        eventDict = [[NSMutableDictionary alloc] init];
        eventsByCode = [[NSMutableArray alloc] init];
        eventLock = [[NSLock alloc] init];
        observerLock = [[NSLock alloc] init];
        observerArray = [[NSMutableArray alloc] init];
		useDefaultDir = YES;
        retainEvents = NO;                          // flush event buffer whenever possible
		threadingThreshold = kDefaultThreadingThreshold;
//		startTime = UpTime();
		startDate = [[NSDate date] retain];
        [NSThread detachNewThreadSelector:@selector(dispatchEvents) toTarget:self withObject:nil];
    }
    return self;
}

- (void) putEvent:(NSString *)eventKey;
{
	LLDataEventDef *eventDef;
    NSAlert *theAlert;
	
// Extract the event from the event dictionary

    if ((eventDef = [eventDict objectForKey:eventKey]) == nil) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:[NSString stringWithFormat:
                                      @"putEvent: Attempt to putEvent for \"%@\", which has not been defined",
                                      eventKey]];
        [theAlert runModal];
        [theAlert release];
//        NSRunAlertPanel(@"LLDataDoc", @"putEvent: Attempt to putEvent for \"%@\", which has not been defined",
//            @"OK", nil, nil, eventKey);
        return;
    }
    if ([eventDef dataBytes] != 0) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:[NSString stringWithFormat:
                                      @"putEvent: Event \"%@\" is defined to have data.", eventKey]];
        [theAlert runModal];
        [theAlert release];
//        NSRunAlertPanel(@"LLDataDoc", @"putEvent: Event \"%@\" is defined to have data.",
//            @"OK", nil, nil, eventKey);
        return;
    }
    [self eventToBuffer:[eventDef code] dataPtr:(char *)NULL bytes:0 writeLength:NO];
}

- (void) putEvent:(NSString *)eventKey withData:(void *)pData {

	LLDataEventDef *eventDef;
	long dataBytes;
    NSAlert *theAlert;
	
// Extract the event from the event dictionary

    if ((eventDef = [eventDict objectForKey:eventKey]) == nil) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:[NSString stringWithFormat:
                                      @"putEvent: Attempt to putEvent for \"%@\", which has not been defined",
                                      eventKey]];
        [theAlert runModal];
        [theAlert release];
//        NSRunAlertPanel(@"LLDataDoc", @"putEvent: Attempt to putEvent for \"%@\", which has not been defined",
//            @"OK", nil, nil, eventKey);
        return;
    }
	dataBytes = [eventDef dataBytes];
    if (dataBytes <= 0) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDataDoc"];
        [theAlert setInformativeText:[NSString stringWithFormat:
                                      @"putEvent: Event \"%@\" is defined to have data of fixed length.", eventKey]];
        [theAlert runModal];
        [theAlert release];
//        NSRunAlertPanel(@"LLDataDoc", @"putEvent: Event \"%@\" is not defined to have data of fixed length.",
//            @"OK", nil, nil, eventKey);
        return;
    }
    [self eventToBuffer:[eventDef code] dataPtr:(char *)pData bytes:dataBytes writeLength:NO];
}

- (void)putEvent:(NSString *)eventKey withData:(char *)pData count:(long)count {

	LLDataEventDef *eventDef;
	
	if (count <= 0) {
		return;
	}
	
// Extract the event from the event dictionary

    if ((eventDef = [eventDict objectForKey:eventKey]) == nil) {
        return;
    }
    if ([eventDef dataBytes] > 0) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
              informativeText:[NSString stringWithFormat:
              @"putEvent: Event \"%@\" is defined to have data of variable length.", eventKey]];
        return;
    }
    [self eventToBuffer:[eventDef code] dataPtr:(char *)pData 
							bytes:(count * [eventDef elementBytes]) writeLength:YES];
}

- (void)putEvent:(NSString *)eventKey withData:(char *)pData lengthBytes:(long)length;
{
	LLDataEventDef *eventDef;
	
	if (length <= 0) {
		return;
	}

// Extract the event from the event dictionary

    if ((eventDef = [eventDict objectForKey:eventKey]) == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                    informativeText:[NSString stringWithFormat:
                    @"putEvent: Attempt to putEvent for \"%@\", which has not been defined", eventKey]];
        return;
    }
    if ([eventDef dataBytes] > 0) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                    informativeText:[NSString stringWithFormat:
                    @"putEvent: Event \"%@\" is defined to have data of variable length.", eventKey]];
        return;
    }
    [self eventToBuffer:[eventDef code] dataPtr:(char *)pData bytes:length writeLength:YES];
}

- (void) removeObserver:(id)anObserver;
{
    [observerLock lock];
    [observerArray removeObject:anObserver];
    [observerLock unlock];
}

- (void)setRetainEvents:(BOOL)state;
{
	retainEvents = state;
}

- (void)setThreadingThreshold:(unsigned long)threshold;
{
	threadingThreshold = threshold;
}

- (void)setUseDefaultDataDirectory:(BOOL)state;
{
	useDefaultDir = state;
}

// Very large events take a long time to compose and send to the data event buffer.  We thread them out so
// that data collection and display don't get locked out while the event is posted. 

- (void)threadedEventToBuffer:(NSData *)eventData;
{
	NSAutoreleasePool *threadPool= [[NSAutoreleasePool alloc] init];
	
	[eventLock lock];
	[data appendData:eventData];
	if (dataFileHandle != nil) {
		[dataFileHandle writeData:eventData];
	}
	[eventLock unlock];
	[eventData release];			// eventData is not release by eventToBuffer
	[threadPool release];
}	

@end