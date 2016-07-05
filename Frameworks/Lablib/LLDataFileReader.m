//
//  LLDataReader.m
//  Lablib
//
//  Data file reader for Lablib data format 6 and beyond only.
//
//  Created by John Maunsell on Sun Jul 04 2004.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLDataFileReader.h"
#import "LLProgressIndicator.h"
#import "LLSystemUtil.h"

enum {kSingleDevice = 1, kMultiDevice};

#define kNoEventCode		-1
#define kMaxDevices			8
#define kMaxChannels		16

@implementation LLDataFileReader

// Append a string to an NSMutableData object, after converting C-style subscripts ([0])
// to Matlab-style subscripts ((1)).  We determine that something is a C-style subscript
// if: 1) a '[' followed by a ']'; there is no ' ' immediately preceding the '['; and
// 3) there are only digits between the '[' and ']'.

- (void)appendMatlabString:(NSString *)eventString toData:(NSMutableData *)data;
{
	int subscript;
	NSRange leftBracketRange, rightBracketRange;
	NSScanner *scanner;
	
	for (;;) {
		leftBracketRange = [eventString rangeOfString:@"["];
		if (leftBracketRange.location == NSNotFound) {
			break;
		}
		rightBracketRange = [eventString rangeOfString:@"]"];
		if (rightBracketRange.location == NSNotFound) {
			break;
		}
		if (rightBracketRange.location < leftBracketRange.location) {
			break;
		}
		if (leftBracketRange.location == 0) {
			break;
		}
		if ([eventString characterAtIndex:(leftBracketRange.location - 1)] == ' ') {
			break;
		}
		if ([[eventString substringWithRange:NSMakeRange(leftBracketRange.location, 
				rightBracketRange.location - leftBracketRange.location)] 
				rangeOfString:@" "].location != NSNotFound) {
				break;
		}
		scanner = [NSScanner scannerWithString:[eventString substringWithRange:
					NSMakeRange(leftBracketRange.location + 1, 
					rightBracketRange.location - leftBracketRange.location - 1)]];
		[scanner scanInt:&subscript];
		eventString = [NSString stringWithFormat:@"%@(%d)%@",
					[eventString substringWithRange:NSMakeRange(0, leftBracketRange.location)],
					subscript + 1,
					[eventString substringWithRange:NSMakeRange(rightBracketRange.location + 1,
					([eventString length] - rightBracketRange.location - 1))]];
	}
	[data appendBytes:[eventString UTF8String] 
			length:[eventString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

// Convert an array of long values into a string that is readable by Matlab.  
// This conversion takes into account Matlab's limit on the number of entries
// per line (~25) and entries per line of command (~2000).

- (NSString *)arrayAsMatlabString:(NSArray *)array lValueString:(NSString *)lValueString;
{
	long index;
	NSNumber *number;
	NSMutableString *string;
	
	string = [NSMutableString stringWithFormat:@"%@ = [", lValueString];
	for (index = 0; index < [array count]; index++) {
		number = [array objectAtIndex:index];
		[string appendString:[NSString stringWithFormat:@" %ld", [number longValue]]];
		if (((index % 2000) == 0) && (index > 0)) {
			[string appendString:[NSString stringWithFormat:@"];\n%@ = [%@ ",
				lValueString, lValueString]];
		}
		if (((index % 25) == 0) && (index > 0)) {
			[string appendString:[NSString stringWithFormat:@" ...\n"]];
		}
	}
	[string appendString:@"];\n"];
	return string;
}

// Return the number of bytes that are used to encode a particular data event.  This
// varies because some event are variable length, and the bytes for event types depends
// on how many events there are

- (long)bytesInDataEvent:(DataEvent *)pEvent;
{
	long typeBytes;
	LLDataEventDef *eventDef;
	
	if (numEvents < 0x100) {
		typeBytes = sizeof(char);
	}
	else if (numEvents < 0x10000) {
		typeBytes = sizeof(short);
	}
	else {
		typeBytes = sizeof(long);
	}
	eventDef = [eventsDict objectForKey:pEvent->name];
    if ([eventDef dataBytes] >= 0) { 	// Fixed-length events consist of type, data and time
        return (typeBytes + [eventDef dataBytes] + sizeof(unsigned long));
    }
    else {						// Variable-length events consist of type, length, data and time
        return (typeBytes + sizeof(long) + [pEvent->data length] + sizeof(unsigned long));
    }
}

// Count the different types of events in a file.  These can be used 
// to speed up movement around the file

- (void)countEvents
{
	LLDataEventDef *dataDef;
	unsigned long index, eventCode, trialStartEventCode;
		
    [self rewind];
	eventCounts = calloc(numEvents, sizeof(unsigned long));
	trialStartIndices = [[NSMutableArray alloc] init];
	cumulativeEvents = [[NSMutableArray alloc] init];

// Get the grand count of all events in file, recording trial starts and cumulative events per trial
	
	trialStartEventCode = [self eventCodeForEventName:@"trialStart"];
	trialCount = 0;
	while ((eventCode = [self readEventCode]) != kNoEventCode) {
		if (eventCode == trialStartEventCode) {
			[trialStartIndices addObject:[NSNumber numberWithUnsignedLong:currentEventIndex]];
			[cumulativeEvents addObject:[NSData dataWithBytes:eventCounts 
													length:(numEvents * sizeof(unsigned long))]];
			trialCount++;
		}
		eventCounts[eventCode]++;
    }

// Record the events in the last trial

	[trialStartIndices addObject:[NSNumber numberWithUnsignedLong:currentEventIndex]];
	[cumulativeEvents addObject:[NSData dataWithBytes:eventCounts 
											length:(numEvents * sizeof(unsigned long))]];
	trialCount++;

// Make the enabled events array, and set them all enabled

	enabledEvents = malloc(numEvents * sizeof(BOOL));
	timedEvents = malloc(numEvents * sizeof(BOOL));
	for (index = 0; index < numEvents; index++) {
		enabledEvents[index] = YES;
		
	
// **** The following is a temporary kludge for Microstim data files until we teach DataConvert
// how to do timed events

		dataDef = [eventsByCode objectAtIndex:index];
		if ([[dataDef name] isEqualToString:@"intervalOne"] ||
								[[dataDef name] isEqualToString:@"intervalTwo"]) {
			timedEvents[index] = YES;
			NSLog(@"setting %@ to a timed event", [dataDef name]);
		}
		else {
			timedEvents[index] = NO;
		}
	}
	
// Make the cumulativeEnabledEvents array, and load it

	cumulativeEnabledEvents = malloc(trialCount * sizeof(unsigned long));
	[self setEnabledEvents:enabledEvents];
	
// Figure out how many columns will be needed to display counts

    for (index = maxEventCount = 0; index < numEvents; index++) {
		maxEventCount = MAX(maxEventCount, eventCounts[index]);
    }
}

// Read bytes from the data buffer, starting at the offset of dataIndex, incrementing the pointer afterward

- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes {

    if (dataIndex + numBytes > [fileData length]) {
        return NO;
    }
    [fileData getBytes:buffer range:NSMakeRange(dataIndex, numBytes)];
    dataIndex += numBytes;
    return YES;
}

// Read bytes from the data buffer, using an NSRange

- (BOOL)dataBytes:(Ptr)buffer range:(NSRange)range;
{
	dataIndex = range.location;
	return [self dataBytes:buffer length:range.length];
}

// Report whether the data file has data definitions in its header

- (BOOL)dataDefinitions;
{
	return dataDefinitions;
}

- (LLDataEventDef *)dataEventDefWithIndex:(long)index;
{
	return [eventsByCode objectAtIndex:index];
}

// Return the number specifying the format of the data

- (float)dataFormat;
{
	return dataFormat;
}

- (unsigned long)dataIndex;
{
	return dataIndex;
}

- (void)dataDeviceMixError;
{
    [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:
            @"Cannot process file with mix of single an multi-device data"];
//	NSRunAlertPanel(@"LLDataFileReader",
//			@"Cannot process file with mix of single an multi-device data", 
//			@"OK", nil, nil);
}

- (NSString *)dataString {

    char c, buffer[1024];
	
	[self dataBytes:(Ptr)&c length:1L];					// get length of string
	[self dataBytes:(Ptr)&buffer length:(long)c];		// get string
	buffer[(short)c] = '\0';							// null terminate sting
	return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];			// make NSString
}

- (void)dealloc {

	free(eventCounts);
	free(enabledEvents);
	free(timedEvents);
	free(cumulativeEnabledEvents);
	[trialStartIndices release];
	[cumulativeEvents release];
	
	[eventDesc release];
	[eventsDict release];
	[eventsByCode release];
	[fileData release];
	[fileDate release];
	[fileCreateTime release];
	[fileName release];
	[super dealloc];
}

- (unsigned long)enabledEventsInFile;
{	
	return cumulativeEnabledEvents[trialCount - 1];
}

// Return the code associated with an event name, or -1 if the name isn't known 

- (unsigned long)eventCodeForEventName:(NSString *)name;
{
	LLDataEventDef *theEventDef = [eventsDict objectForKey:name];
	
	return ((theEventDef == nil) ? -1 : [theEventDef code]);
}

- (unsigned long *)eventCounts;
{
	return eventCounts;
}

// Return a string describing one event

- (NSArray *)eventDataAsStrings:(DataEvent *)pEvent prefix:(NSString *)prefix
			suffix:(NSString *)suffix;
{
	return [[eventsByCode objectAtIndex:pEvent->code] 
				eventDataAsStrings:pEvent prefix:prefix suffix:suffix];
}

// Return a string describing the time of one event

- (NSString *)eventTimeAsString:(DataEvent *)pEvent prefix:(NSString *)prefix
			suffix:(NSString *)suffix;
{
	prefix = (prefix == nil) ? @"" : prefix;				// need a valid NSString for prefix
	suffix = (suffix == nil) ? @"" : suffix;				// need a valid NSString for suffix
	return [NSString stringWithFormat:@"%@%@_TrialTime%@ = %ld;\n",
							prefix, pEvent->name, suffix, pEvent->trialTime];
}

/*
Return an NSData object containing a text description of the entire contents of the file, 
formatted as Matlab commands (for a *.m file).

Assumptions are made in making the conversion:

1) The data stream is split into trials, each of which is marked by an event called
"trialStart".

2) Event before the first "trialStart" are prefixed with "file.".  Events after the
first "trialStart" are prefixed with "trials(x).", where x is the count of the trial.

3) Events named "spike", "spike0", "sample", and "sample01" are grouped into cell arrays
within each trial that are called "timestamp{x}" or "AD{x}", where x is the channel number. An 
exception is made if there is only one spike channel.  In that case, the values are put
into a regular array named timestamp.

4) Events named "deviceDataAD" and "deviceDataTimestamp" are similarly grouped into cell arrays
within each trial that are called "device0.AD{x}" and "device0.timestamp{x}, where device0
is repalced with a number appropriate for the data, and x is the channel number.

5) Events that occur more than once per trial receive a subscript "trials(x).myEvent(y)", 
where y is the count of that event within the trial.  The decision is not based on 
sophistocated parsing - it simply looks whether the count for a given event is greater
than the number of trials.

6) Events are assigned a value equal to their data, except those defined has having 
"noData", which are given the time in milliseconds since that start of the trial that contains
them.

7) Events called "fileEnd" are not included in the Matlab conversion
 
*/

- (NSData *)eventsAsMatlabStrings; 
{
	unsigned long event, index, string, stop, trial;
	long *eventTrialCounts;
	BOOL *multiFileEvents, *multiTrialEvents, *pMultiEvents;
	BOOL aborted;
	DataEvent *pEvent;
	LLDataEventDef *eventDef;
	LLProgressIndicator *progress;
	NSArray *eventStrings;
	NSMutableData *data;
	NSMutableString *bufferString;
	NSString *eventName, *eventString, *prefix, *suffix, *headerString, *bundleString;
	NSModalSession session;
	NSAutoreleasePool *autoreleasePool;
	BOOL warned = NO;
	long trialEndEventCode = [self eventCodeForEventName:@"trialEnd"];
	long trialStartEventCode = [self eventCodeForEventName:@"trialStart"];
	long fileEndEventCode = [self eventCodeForEventName:@"fileEnd"];
	NSString *bundledEventPrefixes[] = {@"sample", @"eye", @"spike", @"timestamp", @"VBL", @"vbl", @"eStimData", nil};
	NSString *bundledEventStops[] = {@"calibration", @"zero", @"window", @"eyeCal", @"Break", nil};
	
// We can't do anything if the trial start codes are not defined

	if (trialStartEventCode < 0) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
            @"Cannot convert %@ to Matlab format because it does not contain \"trialStart\" events.", fileName]];
//		NSRunAlertPanel(@"LLDataFileReader",
////			@"Cannot convert %@ to Matlab format because it does not contain \"trialStart\" events.",
//			@"OK", nil, nil, fileName);
	}
	
// Make a dictionary for all the events that are to be bundled as samples or timestamps.  We use the event
// name as the key, and store an NSString as the object.  This NSString will be used to compose the output 
// string for the bundled data. Bundled events are written out as an array of values at the end of each 
// trial.

	bundledEvents = [[NSMutableDictionary alloc] init];
	for (event = 0; event < numEvents; event++) {
		eventDef = [eventsByCode objectAtIndex:event];
		eventName = [eventDef name];
		for (index = 0; bundledEventPrefixes[index] != nil; index++) {
			if ([eventName hasPrefix:bundledEventPrefixes[index]]) {
				for (stop = 0; bundledEventStops[stop] != nil; stop++) {
					if ([eventName rangeOfString:bundledEventStops[stop] options:NSCaseInsensitiveSearch].length != 0) {
						break;
					}
				}
				if (bundledEventStops[stop] == nil) {
					[bundledEvents setObject:[[[NSMutableString alloc] init] autorelease] forKey:eventName];
				}
				break;
			}
		}
	}
	
// Initialize for reading file events.  Everything before the first trialStart event goes into the "file" structure
// in the Matlab file. We have to count the occurences of each event before the first trialStart so we know whether
// we have to assign subscripts to the events

	eventTrialCounts = calloc(numEvents, sizeof(long));	// count of each event in current trial
	multiTrialEvents = calloc(numEvents, sizeof(BOOL));				// events with subscript in "file"
	multiFileEvents = calloc(numEvents, sizeof(BOOL));				// events with subscript in "trial"
	data = [[NSMutableData alloc] init];
	headerString = [NSString stringWithFormat:
				@"file.fileName = '%@';\nfile.createDate = '%@';\nfile.createTime = '%@'\n",
				fileName, fileCreateDate, fileCreateTime];
	[data appendBytes:[headerString UTF8String] 
			length:[headerString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	[self rewind];
	while ((pEvent = [self readEvent]) != nil) {
		eventTrialCounts[pEvent->code]++;
		if (pEvent->code == trialStartEventCode) {
			break;
		}
	}
	for (event = 0; event < numEvents; event++) {
		multiFileEvents[event] = eventTrialCounts[event] > 1;
		multiTrialEvents[event] = (eventCounts[event] > eventCounts[trialStartEventCode] &&
												event != trialEndEventCode);
		eventTrialCounts[event] = 0;
	}
	pMultiEvents = multiFileEvents;									// start checking multi file, until first trialStart
	[self rewind];
	trial = 0;
	prefix = [[NSString alloc] initWithString:@"file."];			// prefix must no autorelease
	
// Making the Matlab strings is a long, slow process that involves the generation of many object.
// We set up a progress bar, so the user can abort if necessary.  We also set up our own 
// NSAutoreleasePool and release it periodically, so that the objects we create do not hang
// around until the entire file is parsed.

	progress = [[LLProgressIndicator alloc] init];
	[progress setTitle:[fileName stringByDeletingPathExtension]];
	[progress setMaxValue:[fileData length]];
	[progress setText:@"Converting to Matlab"];
	[progress showWindow:self];
	autoreleasePool = [[NSAutoreleasePool alloc] init];
	session = [NSApp beginModalSessionForWindow:[progress window]];
	aborted = NO;

// Read events sequentially, putting some events immediately, buffering others until trial boundaries

	while (dataIndex < [fileData length]) {
		if ((pEvent = [self readEvent]) == nil) {					// disabled events come back nil
			continue;
		}
		
// Process the event

		if (pEvent->code == fileEndEventCode) {		// don't convert fileEnd
			continue;
		}

// trialStart is the boundary between trials.  We write all the buffered values out, and then clear
// buffers to start the next trial.

		if (pEvent->code == trialStartEventCode) {
			[self writeBuffersToMatlab:data prefix:prefix];	// write out the data we have buffered & clear buffers
			for (event = 0; event < numEvents; event++) {
				eventTrialCounts[event] = 0;
			}
			[prefix release];
			prefix = [[NSString alloc] initWithFormat:@"trials(%ld).", ++trial];
			eventString = [NSString stringWithFormat:@"%@trialStartTime = %ld;\n",
				prefix, pEvent->time];
			[self appendMatlabString:eventString toData:data];
			pMultiEvents = multiTrialEvents;					// at first trialStart, start using multi trial
			continue;
		}
		
// If this is a bundled event, bundle it.  -eventDataElementsAsString returns a space-separated list of 
// formatted data values.  We append these to the appropriate string.  Later, at the next trialStart
// event, we will use this string to create a Matlab command to make an array, using -writeBuffersToMatlab.

		if ((bufferString = [bundledEvents objectForKey:pEvent->name]) != nil) {
			if (trialCount > 0) {										// no bundled events before first trial
				eventDef = [eventsByCode objectAtIndex:pEvent->code];
				if ((bundleString = [eventDef eventDataElementsAsString:pEvent]) != nil) {
					[bufferString appendString:bundleString];
				}
				else {
					if (!warned) {
                        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:
                            [NSString stringWithFormat:@"eventsAsMatlabString: Can't bundle data of type\"%@\", doing nothing.", pEvent->name]];
//						NSRunAlertPanel(@"LLDataFileReader", @"eventsAsMatlabString: Can't bundle data of type\"%@\", doing nothing.",
//							@"OK", nil, nil, pEvent->name);
						warned = YES;
					}
				}
				continue;
			}
		}
		
// If it is not a special case, handle it in the standard way, which will differ depending on whether
// there is more than one instance of this event per trial

		eventDef = [eventsByCode objectAtIndex:pEvent->code];
		if (!pMultiEvents[pEvent->code]) {
			suffix = nil;
		}
		else if ([eventDef isStringData]) {
			suffix = [NSString stringWithFormat:@"{%ld}", eventTrialCounts[pEvent->code] + 1];
		}
		else {
			suffix = [NSString stringWithFormat:@"(%ld)", eventTrialCounts[pEvent->code] + 1];
		}
		eventStrings = [eventDef eventDataAsStrings:pEvent prefix:nil suffix:suffix];
		for (string = 0; string < [eventStrings count]; string++) {
			eventString = [NSString stringWithFormat:@"%@%@;\n", prefix, 
								[eventStrings objectAtIndex:string]];
			[self appendMatlabString:eventString toData:data];
		}

// If this is a timed event, write the time (in addition to the event with the data)

		if (timedEvents[pEvent->code]) {
			[self appendMatlabString:
						[self eventTimeAsString:pEvent prefix:prefix suffix:suffix] toData:data];
		}
		eventTrialCounts[pEvent->code]++;
	
// Run the modal session frequently enough to handle the window events

		if ([progress needsUpdate]) {
			[progress setDoubleValue:dataIndex];				// set progress bar
			if (([NSApp runModalSession:session] != NSModalResponseContinue) || [progress cancelled]) {
				aborted = YES;
				break;
			}
			[autoreleasePool release];								// flush autorelease objects
			autoreleasePool = [[NSAutoreleasePool alloc] init];
		}
	}
	[self writeBuffersToMatlab:data prefix:prefix];			// write out remaining data we have buffered
	[self rewind];
	[NSApp endModalSession:session];
	[progress close];
	[autoreleasePool release];								// flush autorelease objects
	[prefix release];
	[progress release];
	[bundledEvents release];
	free(eventTrialCounts);
	free(multiTrialEvents);
	free(multiFileEvents);
	[data autorelease];										// have to autorelease here
	return (aborted) ? nil : data;
}

- (NSString *)fileCreateDate;
{ 
	return fileCreateDate;
}

- (NSString *)fileCreateTime;
{
	return fileCreateTime;
}

- (NSData *)fileData;
{
	return fileData;
}

- (NSDate *)fileDate;
{
	return fileDate;
}

- (long)fileBytes;
{
	return [fileData length];
}

// Find an event that contains a given file offset value

- (DataEvent *)findEventByIndex:(unsigned long)index line:(long *)pLine;
{
    unsigned long trial;
    DataEvent *pEvent;

    if (index < firstDataEventIndex) {
        *pLine = -1;
        return nil;
    }
    
// Find the trial that contains the sought event

    for (trial = lineCounter = 0; trial < trialCount; trial++) {
        if ([[trialStartIndices objectAtIndex:trial] unsignedLongValue] >= index) {
            break;
        }
        lineCounter = cumulativeEnabledEvents[trial];
    }
    dataIndex = (trial == 0) ? firstDataEventIndex : [[trialStartIndices objectAtIndex:(trial - 1)] unsignedLongValue];

// Scan forward to find the event with the correct index

    for (;;) {
        if ((pEvent = [self readEvent]) == nil) {
            continue;
        }
        if (currentEventIndex + [self bytesInDataEvent:pEvent] > index) {
            break;
        }
        lineCounter++;
    }
    if (currentEventIndex > index) {		// If this event is beyond index the index is in disabled event
        *pLine = -1;
        pEvent = nil;
        return pEvent;
    }
    *pLine = lineCounter;			// Return the lind for this event
    return pEvent;
}

- (DataEvent *)findEventByLine:(unsigned long)line index:(long *)pIndex;
{
    long trial;
    DataEvent *pEvent;

// If the requested event is the last one we read, just set the file index to its location.
// (Note we can't hold onto the last event, because it had NSData that will autorelease.
// If we are sitting right at the event we want to read, we don't need to do anything.
// Other we start at the beginning of the trial list and scan forward to find the trial 
// holding the line we want.

    if (line == lastLineRead) {							// rewind to read it again
		dataIndex = lastIndex;
		lineCounter = line;
    }
    else if (line == lastLineRead + 1) {
		dataIndex = nextIndex;							// restore, in case someone has moved it
		lineCounter = line;
	}
	else {
		trialStartTime = -1;
        for (trial = lineCounter = 0; trial < trialCount; trial++) {
            if (cumulativeEnabledEvents[trial] >= line) {
                break;
            }
            lineCounter = cumulativeEnabledEvents[trial];
        }
        dataIndex = (trial == 0) ? firstDataEventIndex : 
			[[trialStartIndices objectAtIndex:(trial - 1)] unsignedLongValue];
    }    
   
// We are now either immediately before the line we want, or at the start of the trial that
// contains the line we want
          		
    do {
        if ((pEvent = [self readEvent]) == nil) {		// skipping disabled event types
            continue;
        }
        lineCounter++;									// count enabled events
	} while (lineCounter <= line);

    lastLineRead = line;								// remember where we are
	nextIndex = dataIndex;								// save pointer to next event
    lastIndex = currentEventIndex;						// save pointer to this event
    *pIndex = currentEventIndex;						// return the index for this event
    return pEvent;
}

- (unsigned long)firstDataEventIndex;
{
	return firstDataEventIndex;
}

- (id)init;
{
	if ((self = [super init]) != nil) {
		lastLineRead = -10;
	}
	return self;
}

- (id)initWithData:(NSData *)data;
{
	if ((self = [super init]) != nil) {
		[self setFileData:data];
		lastLineRead = -10;
	}
	return self;
}

- (long)length {

	return [fileData length];
}

- (unsigned long)maxEventCount;
{
	return maxEventCount;
}

- (unsigned long)maxEventDataBytes;
{
	return maxEventDataBytes;
}

- (unsigned long)maxEventNameLength;
{
	return maxEventNameLength;
}

- (long)numEvents;								// return the number of event definitions
{
	return [eventsDict count];
}

- (DataEvent *)readEvent;
{
    unsigned char charCode;
    unsigned short shortCode;
	unsigned long numBytes;
    short index, channel;
	long eventCode;
	LLDataEventDef *eventDef;

	if (dataIndex == [fileData length]) {				// at end of file
		return nil;
	}
	
// Get the event code from the buffer, and use it to get the definition for this type

	currentEventIndex = theEvent.fileIndex = dataIndex;
	if (numEvents < 0x100) {
		[self dataBytes:(void *)&charCode length:sizeof(charCode)];
		eventCode = charCode;
	}
	else if (numEvents < 0x10000) {
		[self dataBytes:(void *)&shortCode length:sizeof(shortCode)];
		eventCode = shortCode;
	}
	else {
		[self dataBytes:(void *)&eventCode length:sizeof(eventCode)];
	}
	theEvent.code = eventCode;
	eventDef = [eventsByCode objectAtIndex:eventCode];

// If this type (eventCode) of event is not enabled, we don't need to read
// and return it.  We just need to advance the dataIndex so it is sitting
// at the start of the next event

	if (!enabledEvents[eventCode]) {
		if ([eventDef dataBytes] != 0) {
			if ([eventDef dataBytes] > 0) {
				numBytes = [eventDef dataBytes];				// fixed length data, get length
			}
			else {												// variable length data, get length
				[self dataBytes:(void *)&numBytes length:sizeof(unsigned long)];
			}
			dataIndex += numBytes;
		}
		dataIndex += sizeof(unsigned long);						// advance over the event time stamp
		return nil;
	}
	
// Load the name for this event

	theEvent.name = [eventDef name];

// Get the event data from the buffer, if this event has data

	if ([eventDef dataBytes] == 0) {
	   theEvent.data = nil;
	}
	else {
		if ([eventDef dataBytes] > 0) {
			numBytes = [eventDef dataBytes];				// fixed length data, get length
		}
		else {												// variable length data, get length
			[self dataBytes:(void *)&numBytes length:sizeof(unsigned long)];
		}
		theEvent.data = [fileData subdataWithRange:NSMakeRange(dataIndex, numBytes)];
		dataIndex += numBytes;
	}

// Get the event time.  This is the time that the event was posted.  The trialTime is generally
// of more use.

	[self dataBytes:(Ptr)&theEvent.time length:sizeof(unsigned long)];
	
// Process special events and set the trial time.

    if ([theEvent.name isEqualToString:@"trialStart"]) {
		trialStartTime = theEvent.time;
    }
    theEvent.trialTime = (trialStartTime == -1) ? -1 : theEvent.time - trialStartTime;

// Certain special events cause timebases to be reset or need a relative time

    if ([theEvent.name isEqualToString:@"sampleZero"]) {
		sampleIntervalMS = *(long *)[theEvent.data bytes];
        for (index = 0; index < kADChannels; index++) {
            lastSampleTime[index] = 0;
        }
    }
    else if ([theEvent.name isEqualToString:@"spikeZero"]) {
        spikeStartTime = theEvent.time;
    }
    else if ([theEvent.name isEqualToString:@"sample01"]) {
        theEvent.trialTime = lastSampleTime[0];
        lastSampleTime[0] += sampleIntervalMS;
        lastSampleTime[1] += sampleIntervalMS;
    }
    else if ([theEvent.name isEqualToString:@"sample"]) {
        channel = ((ADData *)[theEvent.data bytes])->channel;
        theEvent.trialTime = lastSampleTime[channel];
        lastSampleTime[channel] += sampleIntervalMS;
    }
    else if ([theEvent.name isEqualToString:@"spike"]) {
        theEvent.trialTime = spikeStartTime - trialStartTime + 
                    ((TimestampData *)[theEvent.data bytes])->time;
    }
    else if ([theEvent.name isEqualToString:@"spike0"]) {
        theEvent.trialTime = spikeStartTime - trialStartTime + 
                    (*(long *)[theEvent.data bytes]);
    }
	return &theEvent;
}

// The following is a reduced version of readEvent that returns only the type of an event.  It is used by 
// countEvents, which really doesn't care about anything else.

- (unsigned long)readEventCode;
{
    unsigned char charCode;
    unsigned short shortCode;
	unsigned long numBytes;
	long eventCode;
	LLDataEventDef *eventDef;

	if (dataIndex == [fileData length]) {
		return kNoEventCode;
	}
	
// Get the event code from the buffer, and use it to get the definition for this type

	currentEventIndex = dataIndex;
	if (numEvents < 0x100) {
		[self dataBytes:(void *)&charCode length:sizeof(charCode)];
		eventCode = charCode;
	}
	else if (numEvents < 0x10000) {
		[self dataBytes:(void *)&shortCode length:sizeof(shortCode)];
		eventCode = shortCode;
	}
	else {
		[self dataBytes:(void *)&eventCode length:sizeof(eventCode)];
	}
	
	if (eventCode >= numEvents) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:
            [NSString stringWithFormat:@"Read event code %ld at 0x%lx but only %ld event defined",
             eventCode, currentEventIndex, numEvents]];
//		NSRunAlertPanel(@"LLDataFileReader",  @"Read event code %ld at 0x%lx but only %ld event defined",
//			@"OK", nil, nil, eventCode, currentEventIndex, numEvents);
		exit(0);
	}
	
// We've now got the code that we want, but we need to advance the dataIndex
// to the start of the next event, but skipping it over enough bytes. This
// requires figuring out what the event is.

	eventDef = [eventsByCode objectAtIndex:eventCode];			// get the definition for this event
	if ([eventDef dataBytes] != 0) {
		if ([eventDef dataBytes] > 0) {
			numBytes = [eventDef dataBytes];				// fixed length data, get length
		}
		else {												// variable length data, get length
			[self dataBytes:(void *)&numBytes length:sizeof(unsigned long)];
		}
		dataIndex += numBytes;
	}
	dataIndex += sizeof(unsigned long);						// advance over the event time stamp
	return eventCode;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
{
	BOOL result;
    NSFileWrapper *fileWrap;
	
	if (![absoluteURL isFileURL]) {
//		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
		return NO;
	}
	if (![typeName hasPrefix:@"Lablib Data"]) {
//		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
		return NO;
	}
    fileWrap = [[[NSFileWrapper alloc] initWithURL:absoluteURL options:NULL error:NULL] autorelease];
//    fileWrap = [[[NSFileWrapper alloc] initWithPath:[absoluteURL path]] autorelease];
	if ((result = [self setFileData:[fileWrap regularFileContents]])) {
        fileName = [[[absoluteURL path] lastPathComponent] retain];
    }
	return result;
}

- (void)rewind {

	dataIndex = firstDataEventIndex;
	trialStartTime = -1;
}

- (void)setDataIndex:(unsigned long)newIndex;
{
	dataIndex = newIndex;
}

// tally the number of enabled events whenever the enabled events change

- (void)setEnabledEvents:(BOOL *)enabledArray;
{
    long index, trial;
	unsigned long *trialEventCounts;
    
    for (index = 0; index < numEvents; index++) {
        enabledEvents[index] = enabledArray[index];
    }
    for (trial = 0; trial < trialCount; trial++) {
        cumulativeEnabledEvents[trial] = 0;
		trialEventCounts = (unsigned long *)[((NSData *)[cumulativeEvents objectAtIndex:trial]) bytes];
        for (index = 0; index < numEvents; index++) {
            if (enabledEvents[index]) {
                cumulativeEnabledEvents[trial] += trialEventCounts[index];
            }
        }
    }
}

- (BOOL)setFileData:(NSData *)data;
{
    char buffer[1024];
    short length;
    long index, dataBytes;
	NSString *eventName, *dateTimeString;
    NSDateFormatter *dateFormatter;
	LLDataEventDef *dataEventDef;

	fileData = [data copyWithZone:[self zone]];
	eventDesc = [[NSMutableArray alloc] init];
	eventsByCode = [[NSMutableArray alloc] init];
	eventsDict = [[NSMutableDictionary alloc] init];

// Read the header of the data file

    dataIndex = 0;
    [self dataBytes:buffer length:2];
    if (buffer[0] != 7 || buffer[1] < 2 || buffer[1] > 6) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                                   informativeText:@"Cannot parse format specifier in file"];
//		NSRunAlertPanel(@"LLDataFileReader",
//			@"Cannot parse format specifier in file", @"OK", nil, nil);
        return NO;
    }
    length = buffer[1];
    [self dataBytes:buffer length:length];
    if (buffer[0] != '0' || buffer[1] != '0') {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                                   informativeText:@"File's format specifier has bad format"];
//		NSRunAlertPanel(@"LLDataFileReader",  @"File's format specifier has bad format", @"OK", nil, nil);
        return NO;
    }

//#ifdef __BIG_ENDIAN__ and __LITTLE_ENDIAN__

	buffer[length] = '\0';						// null terminate version string
	sscanf(buffer, "%f", &dataFormat);			// get the data format
    if (dataFormat < 6) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
               @"File has wrong data format (%f instead of >= 6)", dataFormat]];
//		NSRunAlertPanel(@"LLDataFileReader",  @"File has wrong data format (%f instead of >= 6)",
//								@"OK", nil, nil, dataFormat);
        return NO;
    }
	dataDefinitions = (dataFormat > 6.0);		// data definitions started with format 6.1
#ifdef __LP64__
    if (dataFormat < 6.3) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                                   informativeText:@"You must run DataConvert in 32-bit mode to read this data file"];
//        NSRunAlertPanel(@"LLDataFileReader",  @"You must run DataConvert in 32-bit mode to read this data file",
//                        @"OK", nil, nil, nil);
        return NO;
    }
#else
    if (dataFormat > 6.2) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                                   informativeText:@"You must run DataConvert in 64-bit mode to read this data file"];
//        NSRunAlertPanel(@"LLDataFileReader",  @"You must run DataConvert in 64-bit mode to read this data file",
//                        @"OK", nil, nil, nil);
        return NO;
    }
#endif

// After the code at the start of the file, the next thing is a count of the number of data
// events defined for the file, followed by the definitions of those events.  Definitions consist
// of a string, which is the name of the event, and a count that specifies the number of data bytes
// that are associated with the event. If there are dataDefinitions for the events, there there
// are addtional data describing the format of the event data.

	[self dataBytes:(Ptr)&numEvents length:sizeof(long)];		// get the count of events
    for (index = 0; index < numEvents; index++) {				// do one event
		eventName = [self dataString];							// name of event
		[self dataBytes:(Ptr)&dataBytes length:sizeof(long)];	// number of data bytes for event
		dataEventDef = [[[LLDataEventDef alloc] initWithCode:index
				name:eventName dataBytes:dataBytes] autorelease];
		if (dataDefinitions) {
			[dataEventDef readDefinitionsFromFile:self];
		}
		[eventsByCode addObject:dataEventDef];
		[eventsDict setObject:dataEventDef forKey:[dataEventDef name]];
		maxEventNameLength = MAX(maxEventNameLength, [eventName length]);
		maxEventDataBytes = MAX(maxEventDataBytes, dataBytes);
    }
	
// Read and format the creation data and time

	[fileCreateDate release];
    [fileDate release];
    [fileCreateTime release];
	fileCreateDate = [self dataString];
	[fileCreateDate retain];
	fileCreateTime = [self dataString];
	[fileCreateTime retain];
    dateTimeString = [NSString stringWithFormat:@"%@ %@", fileCreateDate, fileCreateTime];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy HH:mm:ss"];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
    fileDate = [dateFormatter dateFromString:dateTimeString];
//    fileDate = [[NSDate alloc] initWithString:[fileCreateDate stringByAppendingString:fileCreateTime]
//                               calendarFormat:@"%B %d, %Y %H:%M:%S"];
    [fileDate retain];
    [dateFormatter release];
    firstDataEventIndex = dataIndex;
	[self countEvents];
	[self rewind];
    return YES;
}

/*
Some types of data (e.g. samples) are not written as individual Matlab commands, but are instead
collected throughout a trial and then bundled into a single Matlab command that creates an array. 
The types that fall in this category are determined by the lists *bundledEventPrefixes[] and
*bundledEventStops[] in -eventsAsMatlabStrings.  -writeBuffersToMatlab does the bundling, using
a string of comma-separate values that was composed during the pass through the trial.
*/

- (void)writeBuffersToMatlab:(NSMutableData *)data prefix:(NSString *)prefix;
{
	long v, values;
	LLDataEventDef *def;
	NSEnumerator *enumerator;
	NSString *key;
	NSArray *valueStrings;
	NSMutableString *bundleString, *matlabString;
	
	enumerator = [bundledEvents keyEnumerator];
	while ((key = [enumerator nextObject])) {
		bundleString = [bundledEvents objectForKey:key];
		if ([bundleString length] != 0) {
			valueStrings = [bundleString componentsSeparatedByString:@","];
			values = [valueStrings count] - 1;				// extra "," leaves blank string at end
			def = [eventsDict objectForKey:key];			// get event definition
			matlabString = [NSMutableString stringWithFormat:@"%@%@ = [", prefix, [def name]];
			for (v = 0; v < values; v++) {
				[matlabString appendString:[NSString stringWithFormat:@"%@ ",
								[valueStrings objectAtIndex:v]]];
				if (((v % 2000) == 0) && (v > 0)) {			// command too long for poor old Matlab
					[matlabString appendString:[NSString stringWithFormat:@"];\n%@%@ = [%@%@ ",
						prefix, [def name], prefix, [def name]]];
					}
				if (((v % 25) == 0) && (v > 0)) {			// line too long for poor old Matlab
					[matlabString appendString:[NSString stringWithFormat:@" ...\n"]];
				}
			}
			[matlabString appendString:@"];\n"];				// terminate Matlab command
			[data appendBytes:[matlabString UTF8String] 
					length:[matlabString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
			[bundleString setString:@""];					// clear the string for next trial
		}
	}
}

@end
