//
//  DataFile.m
//  Data Inspector
//
//  Created by John Maunsell on Sun Jul 07 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import "DataFile.h"
#import "DefView.h"
#import "EventView.h"
#import "HexView.h"
#import "PreferenceController.h"
#import "PrintView.h"

#include <math.h>

#define kADChannels			8
#define	kBytesPerLine		16
#define kCharsPerByte		3
#define kHexAddressPadCols	3
#define kMinParamBuffer		256
#define kTextBufferLength	256

enum {kPrintEvents = 0, kPrintHex};
enum {kCharFormat = 0, kShortFormat, kLongFormat, kFloatFormat, kDoubleFormat};

typedef struct {
	short	xOffset;			// value of x eye position at screen center
	short	yOffset;			// value of y eye position at screen center
	double	eyeUnitsPerDeg;			// distance calibration using in eye pos display
} EyeParam;

typedef struct {
	double	frameRate;			// frame rate (Hz)
	double	distanceInches;			// screen distance (inches)
	double	distanceCM;			// screen distance (inches)
	double	widthInches;			// screen width (inches)
	double	heightInches;			// screen height (inches)
	double	widthCM;			// screen width (cm)
	double	heightCM;			// screen height (cm)
	short 	widthPix;			// screen width (pixels)
	short	heightPix;			// screen height (pixels) 
	double 	widthDeg;			// screen width (degrees)
	double	heightDeg;			// screen height (degrees) 
	double	pixPerDeg;			// pixels per degree of angle
} ScreenParam;

enum {kSearchForLine, kSearchForIndex};

@implementation DataFile

static NSSize		charSize;
static unsigned long 	currentEventIndex;
static DataEvent 	dataEvent = {0};
static char			dataFileCreateDate[256];
static char			dataFileCreateTime[256];
static NSString		*dataFileName;
static short 		dataFormat = kCharFormat;
static BOOL			displayEventData = YES;
static BOOL			displayEventTime = YES;
static BOOL			displayFileOffset = YES;
static BOOL			displayTimeOfDay = YES;
static long 		enabledEventLines;
static EnabledArray	enabledEvents;
static long			*eventCountsByTrial[kMaxEvents] = {0};
static long			eventCountsByType[kMaxEvents] = {0};
static short		eventCountTextCols;
static short		eventDataTextCols;
static short		eventIndexTextCols;
static short		eventTimeTextCols = 4;
static EyeParam		eyeParam;
static short		fileDataFormat;
static NSCalendarDate 	*fileStartDate;
static long	 		fileStartTime;
static long			firstDataEventIndex;			// file index for first data event
static double 		fixAzimuthDeg;
static double 		fixElevationDeg;
static double 		fixOffsetDeg;
static double 		fixWidthDeg;
static NSMutableDictionary *fontDefaultAttributes;
static short		formatChars[] = {2, 6, 11, 3, 3};
static short		hexAddressTextCols;
//static NSDrawer		*infoDrawer;
static float		lineDescenderPix;
static short		maxEventNameLength;
static long			maxTrials = 1024;			// dynamically incremented as needed
static BOOL			printMode = kPrintEvents;
static PrintView	*printView;
static short		spikeTicksPerMS;
static ScreenParam	screen;
static long			selectedEventLine = -1;
static long			selectedEventType = -1;
static long 		selectedBytesStart = -1;
static long			selectedBytesStop = -1;
static long			*totalEnabledEvents = NULL;
static short 		trialCountTextCols;
static long			trialCount;
static long			*trialStartIndices = NULL;
static long			trialStartTimeLL = -1;
static long 		unknownEvents;

- (BOOL) adjustArrays
{
    long index;
    static BOOL firstTime = true;
    
    if (!firstTime) {
        maxTrials *= 2;
    }
    else {
        firstTime = false;
    }
    if (trialStartIndices == NULL) {
        trialStartIndices = (long *)malloc(maxTrials * sizeof(long));
    }
    else {
        realloc(trialStartIndices, maxTrials * sizeof(long));
    }
    if (totalEnabledEvents == NULL) {
        totalEnabledEvents = (long *)malloc(maxTrials * sizeof(long));
    }
    else {
        realloc(totalEnabledEvents, maxTrials * sizeof(long));
    }
    if (trialStartIndices == NULL || totalEnabledEvents == NULL) {
        NSLog(@"adjustArrays: bad allocation or reallocation");
        return false;
    }
    for (index = 0; index < numEvents; index++) {
        if (eventCountsByTrial[index] == NULL) {
            eventCountsByTrial[index] = (long *)malloc(maxTrials * sizeof(long));
        }
        else {
            realloc(eventCountsByTrial[index], maxTrials *sizeof(long));
        }
        if (eventCountsByTrial[index] == NULL) {
            NSLog(@"adjustArrays: bad allocation or reallocation");
            return false;
        }
    }
    return true;
}

- (void)adjustParamBuffer:(long)lengthNeeded
{
    if (lengthNeeded < kMinParamBuffer) {
        lengthNeeded = kMinParamBuffer;
    }
    if (lengthNeeded > dataEvent.dataBufferLength) {
        if (dataEvent.pData == nil) {
            dataEvent.pData = malloc(lengthNeeded);
            if (dataEvent.pData == nil) {
                NSLog(@"adjustParamBuffer: bad malloc");
            }
        }
        else {
            free(dataEvent.pData);
           dataEvent.pData = malloc(lengthNeeded);
            if (dataEvent.pData == nil) {
                NSLog(@"adjustParamBuffer: bad allocation");
            }
        }
        dataEvent.dataBufferLength = lengthNeeded;
    }
}

- (long)bytesInDataEvent:(DataEvent *)pEvent
{
    if (eventID[pEvent->type].dataBytes >= 0) { 	// Fixed-length events consist of type, data and time
        return (1 + pEvent->dataBytes + sizeof(pEvent->timeOfDay));
    }
    else {						// Variable-length events consist of type, length, data and time
        return (1 + sizeof(long) + pEvent->dataBytes + sizeof(pEvent->timeOfDay));
    }
}

// Count the different types of events in a file that has just been opened.
// These counts are used in various places to speed up movement around the file

- (BOOL)countEvents
{
    DataEvent *pEvent;
    long maxEventCount;
    short index;
    BOOL eof;
    char string[256];
    BOOL dataError = false;

    dataIndex = firstDataEventIndex;
    if (![self adjustArrays]) {
        return NO;
    }

// Scan the entire file, counting events

    trialCount = 0;
    eof = NO;
    while (!eof) {
        if ((pEvent = [self readEventType]) == nil) {
            if (dataIndex >= [fileData length]) {
                eof = YES;
            }
            else {
                unknownEvents++; 
                if (!dataError) {
                    sprintf(string, "Invalid Event at 0x%lx", currentEventIndex);
                    NSRunAlertPanel(@"Invalid Data Event", [NSString stringWithCString:string encoding:NSUTF8StringEncoding], @"OK", nil, nil);
                    dataError = YES;
                }
            }
            continue;
        }
        if ((pEvent->type == [self eventCode:"trialStart"]) && !dataError) {
            trialStartIndices[trialCount] = currentEventIndex;
            for (index = 0; index < numEvents; index++) {
                eventCountsByTrial[index][trialCount] = eventCountsByType[index];
            }
            if (++trialCount >= maxTrials) {
                if (![self adjustArrays]) {
                    return NO;
                }
            }
        }
        eventCountsByType[pEvent->type]++;
    }

// How many columns will be needed to display file offsets in hex

    for (hexAddressTextCols = 1; [fileData length] > (0x1L << (4 * hexAddressTextCols)); hexAddressTextCols++) {};

// How many columns will be needed to display trial numbers in decimal

    trialCountTextCols = log(eventCountsByType[[self eventCode:"trialStart"]]) / log(10.0) + 1;

// Figure out how many columns will be needed to display counts

    for (index = maxEventCount = 0; index < numEvents; index++) {
        if (maxEventCount < eventCountsByType[index]) {
            maxEventCount = eventCountsByType[index];
        }
        eventCountTextCols = log(maxEventCount) / log(10.0) + 1;
    }
    return YES;
}

// Read bytes from the data buffer, relative to the current pointer, incrementing the pointer afterward

- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes
{
    NSRange range;
    
    if (dataIndex + numBytes > [fileData length]) {
        return NO;
    }
    range.location = dataIndex;
    range.length = numBytes;
    [fileData getBytes:buffer range:range];
    dataIndex += numBytes;
    return YES;
}

- (NSString *)dataFileName
{
    return dataFileName;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataFileName release];
    [super dealloc];
}

- (NSAttributedString *)definitionString:(long)line
{
    char textBuffer[256];
    
    sprintf(textBuffer, "%-*ld %-*s %*ld %*ld", eventIndexTextCols, line, maxEventNameLength, eventID[line].name,
            eventDataTextCols, eventID[line].dataBytes, eventCountTextCols, eventCountsByType[line]);
    return [[NSAttributedString alloc] 
            initWithString:[NSString stringWithCString:textBuffer encoding:NSUTF8StringEncoding]
            attributes:fontDefaultAttributes];
}

- (void)enabledEvents:(EnabledArray)array
{
    long index, trial, numberEnabled;
    
    for (index = numberEnabled = 0; index < numEvents; index++) {
        enabledEvents[index] = array[index];
        if (enabledEvents[index]) {
            numberEnabled++;
        }
    }

    [enableButton setEnabled:(numberEnabled < numEvents)];
    [disableButton setEnabled:(numberEnabled > 0)];

    for (trial = 0; trial < trialCount; trial++) {
        totalEnabledEvents[trial] = 0;
        for (index = 0; index < numEvents; index++) {
            if (enabledEvents[index]) {
                totalEnabledEvents[trial] += eventCountsByTrial[index][trial];
            }
        }
    }
    
// If there is a selected event line we need to adjust for the change in enabled events

    if (selectedEventType >= 0) {
    
// If the selected type is no longer enabled, make no line enabled

        if (!enabledEvents[selectedEventType]) {
            selectedEventLine = selectedEventType = selectedBytesStart = selectedBytesStop = -1;
        }
    
// If the selected type is still enabled, get the new line that it is on

        else {
            [self findEventByIndex:selectedBytesStart line:&selectedEventLine];
        }
    }
    [eventView setDisplayableLines:[self eventTextLines]];	// update event view
    [hexView setDisplayableLines:[self hexTextLines]];		// *** should not have to do this when first window is gone
}

- (BOOL)enoughRoomInBuffer:(long)filled format:(short)valueFormat length:(short)bufferLength margin:(short)margin
{
    BOOL isEnough;
    
    switch (valueFormat) {
    case kCharFormat:
    case kShortFormat:
    case kLongFormat:
        isEnough = (filled + formatChars[valueFormat] + 1 < bufferLength - margin);
        break;
    case kFloatFormat:
    case kDoubleFormat:
        isEnough = (filled + 8 + formatChars[valueFormat] + 1 < bufferLength - margin);	// Using %e format for float and double
        break;
    }
    return isEnough;
}

- (unsigned char)eventCode:(char *)eventName
{
    long index;
    
    for (index = 0; index < numEvents; index++) {
	if (strcmp((const char *)eventName, eventID[index].name) == 0) { 
            return(index);
        }
    }
    return(-1);
}

- (void)eventSelectionChanged:(long )newSelectionLine clickCount:(short)clicks
{
    DataEvent *pEvent;
    
    if (newSelectionLine == selectedEventLine && clicks < 2) {
        selectedEventLine = selectedEventType = selectedBytesStart = selectedBytesStop = -1;
    }
    else {
        selectedEventLine = newSelectionLine;
        pEvent = [self findEventByLine:selectedEventLine index:&selectedBytesStart];
        selectedEventType = pEvent->type;
        selectedBytesStop = selectedBytesStart + [self bytesInDataEvent:pEvent];
        if (clicks >= 2) {
            [hexView centerViewOnLine:(selectedBytesStart / kBytesPerLine)];
        }
    }
    [hexView setNeedsDisplay:YES];
    [eventView setNeedsDisplay:YES];
}

// Make a text line for an event specified by a line number

- (NSAttributedString *)eventString:(long)line
{
    long index;
    char textBuffer[kTextBufferLength];
    char *pBuffer  = textBuffer;
    long eventIndex, filled;
    static DataEvent *pEvent;
    NSCalendarDate *eventDate;
    NSMutableAttributedString *string;
    
    pEvent = [self findEventByLine:line index:&eventIndex];
    if (displayFileOffset) {
    	pBuffer += sprintf(pBuffer, "0x%0*lx ", hexAddressTextCols, eventIndex);
    }
    if (displayTimeOfDay) {
        eventDate = [fileStartDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 
                        seconds:(long)((pEvent->timeOfDay - fileStartTime) / 1000.0)];
        pBuffer += sprintf(pBuffer, "%02d:%02d:%02d.%03ld ", 
                    [eventDate hourOfDay], [eventDate minuteOfHour], [eventDate secondOfMinute],
                    (long)((pEvent->timeOfDay - fileStartTime) % 1000));
    }
    if (displayEventTime) {
        if (eventIndex >= trialStartIndices[0]) {
            pBuffer += sprintf(pBuffer, "%*ld ", eventTimeTextCols, pEvent->time);
        }
        else {
            pBuffer += sprintf(pBuffer, "%*ld ", eventTimeTextCols, -1L);
        }
    }

// Event name and data

    pBuffer += sprintf(pBuffer, "%-*s ", maxEventNameLength, eventID[pEvent->type].name);
    if (!displayEventData) {
        sprintf(pBuffer, "\r");
    }
    else {
        if (pEvent->type == [self eventCode:"text"]) {
            pBuffer += sprintf(pBuffer, "\"%s\"", pEvent->pData);
        }
        else if (pEvent->type == [self eventCode:"sample01"]) {
            pBuffer += sprintf(pBuffer, "%*d %*d ", formatChars[kShortFormat], ((short *)pEvent->pData)[0], 
                    formatChars[kShortFormat], ((short *)pEvent->pData)[1]);
        }
        else if (pEvent->type == [self eventCode:"spike"]) {
            pBuffer += sprintf(pBuffer, "%*d %*ld ", formatChars[kShortFormat], 
                ((SpikeData *)pEvent->pData)->channel, formatChars[kLongFormat], 
                ((SpikeData *)pEvent->pData)->time);
        }
        else if ((pEvent->type == [self eventCode:"trialStart"]) ||
					(pEvent->type == [self eventCode:"trialEnd"]) ||
					(pEvent->type == [self eventCode:"stimulusOn"]) ||
					(pEvent->type == [self eventCode:"stimulusOff"])) {
			if (fileDataFormat < 6) {
				pBuffer += sprintf(pBuffer, "%*d ", formatChars[kShortFormat],  *(short *)pEvent->pData);
			}
			else {
				pBuffer += sprintf(pBuffer, "%*ld ", formatChars[kLongFormat],  *(long *)pEvent->pData);
			}
		}
        else if (pEvent->type == [self eventCode:"fixWindow"]) {
            pBuffer += sprintf(pBuffer, "%*d:  %*d %*d %*d %*d ", 
                    formatChars[kShortFormat], ((FixWindowData *)pEvent->pData)->index, 
                    formatChars[kShortFormat], ((FixWindowData *)pEvent->pData)->window[0], 
                    formatChars[kShortFormat], ((FixWindowData *)pEvent->pData)->window[1], 
                    formatChars[kShortFormat], ((FixWindowData *)pEvent->pData)->window[2], 
                    formatChars[kShortFormat], ((FixWindowData *)pEvent->pData)->window[3]);
        }
        else {
            for (index = 0; index < pEvent->dataBytes; ) {
                filled = (unsigned long)pBuffer - (unsigned long)textBuffer;
                if (![self enoughRoomInBuffer:filled format:dataFormat length:kTextBufferLength margin:8]) {
                    pBuffer += sprintf(pBuffer, "...");
                    break;
                }
                switch (dataFormat) {
                case kCharFormat:
                    pBuffer += sprintf(pBuffer, "%0*hx ", formatChars[dataFormat], 
                                (unsigned char)pEvent->pData[index]);
                    index += sizeof(char);
                    break;
                case kShortFormat:
                    if (pEvent->dataBytes - index >= sizeof(short)) {
                        pBuffer += sprintf(pBuffer, "%*d ", formatChars[dataFormat],
                                *(short *)&pEvent->pData[index]);
                    }
                    index += sizeof(short);
                    break;
                case kLongFormat:
                    if (pEvent->dataBytes - index >= sizeof(long)) {
                        pBuffer += sprintf(pBuffer, "%*ld ", formatChars[dataFormat],
                                *(long *)&pEvent->pData[index]);
                    }
                    index += sizeof(long);
                    break;
                case kFloatFormat:
                    if (pEvent->dataBytes - index >= sizeof(float)) {
                        pBuffer += sprintf(pBuffer, "% .*e ", formatChars[dataFormat],
                                *(float *)&pEvent->pData[index]);
                    }
                    index += sizeof(float);
                    break;
                case kDoubleFormat:
                    if (pEvent->dataBytes - index >= sizeof(double)) {
                        pBuffer += sprintf(pBuffer, "% .*e ", formatChars[dataFormat],
                                *(double *)&pEvent->pData[index]);
                    }
                    index += sizeof(double);
                    break;
                }
            }
        }
    }
       
    string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithCString:textBuffer encoding:NSUTF8StringEncoding]
            attributes:fontDefaultAttributes];
    if (line == selectedEventLine) {
        [string addAttribute:NSBackgroundColorAttributeName value:[NSColor selectedTextBackgroundColor]
            range:NSMakeRange(0, [string length])];
    }
    return string;
}

// Find the number of text lines that are enabled to be displayed

- (long)eventTextLines
{
    short index;
    
    for (index = enabledEventLines = 0; index < numEvents; index++) {
	if (enabledEvents[index]) {
            enabledEventLines += eventCountsByType[index];
        }
    }
    return enabledEventLines;
}

// Find an event that contains a given file offset value

- (DataEvent *)findEventByIndex:(long)index line:(long *)pLine;
{
    long trial;
    DataEvent *pEvent;
    long lineCounter;

    if (index < firstDataEventIndex) {
        *pLine = -1;
        return nil;
    }
    
// Find the trial that contains the sought event

    for (trial = lineCounter = 0; trial < trialCount; trial++) {
        if (trialStartIndices[trial] >= index) {
            break;
        }
        lineCounter = totalEnabledEvents[trial];
    }
    dataIndex = (trial == 0) ? firstDataEventIndex : trialStartIndices[trial - 1];

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

- (DataEvent *)findEventByLine:(long)line index:(long *)pIndex;
{
    long trial;
    DataEvent *pEvent;
    static long lineCounter = 0;
    static long lastLineRead = -10;
    static long lastIndex;
    static DataEvent lastEvent;
    
    if (line == lastLineRead) {
        pEvent = &lastEvent;
        *pIndex = lastIndex;
        return pEvent;
    }
    
// If we are not sitting right in front of the trial that we want, start at the beginning
// of the trial list and scan forward to find the trial hold the line we want.

    if (line != lastLineRead + 1) {
        for (trial = lineCounter = 0; trial < trialCount; trial++) {
            if (totalEnabledEvents[trial] >= line) {
                break;
            }
            lineCounter = totalEnabledEvents[trial];
        }
        dataIndex = (trial == 0) ? firstDataEventIndex : trialStartIndices[trial - 1];
    }    
   
// We are now either immediately before the line we want, or at the start of the trial that
// contains the line we want
          		
    do {
        if ((pEvent = [self readEvent]) == nil) {
            continue;
        }
        lineCounter++;						// count every event returned (all are enabled)
    } while (lineCounter <= line);
    lastLineRead = line;
    lastEvent = *pEvent;
    *pIndex = lastIndex = currentEventIndex;			// Return the index for this event
    return pEvent;
}

- (void)handleDisplayFormatChange:(NSNotification *)notification
{
    [self readPreferences];
    [eventView setNeedsDisplay:YES];
}

- (void)hexSelectionChanged:(long)newSelectionLine xPix:(short)x clickCount:(short)clicks
{
    short charOnLine, addressChars;
    long byteSelected, eventLine;
    DataEvent *pEvent;
    
    addressChars = hexAddressTextCols + kHexAddressPadCols;
    charOnLine = x / charSize.width;
    if ((charOnLine < addressChars || charOnLine >= addressChars + kBytesPerLine * kCharsPerByte)
                        && clicks < 2) {
         selectedEventLine = selectedEventType = selectedBytesStart = selectedBytesStop = -1;   
    }
    else {
        byteSelected = newSelectionLine * kBytesPerLine + (charOnLine - addressChars) / kCharsPerByte;
	pEvent = [self findEventByIndex:byteSelected line:&eventLine];
        if (eventLine < 0 || (eventLine == selectedEventLine && clicks < 2)) {
            selectedEventLine = selectedEventType = selectedBytesStart = selectedBytesStop = -1;
        }
        else {
            selectedEventLine = eventLine;
            selectedEventType = pEvent->type;
            selectedBytesStart = currentEventIndex;
            selectedBytesStop = selectedBytesStart + [self bytesInDataEvent:pEvent];
            if (clicks >= 2) {
                [eventView centerViewOnLine:selectedEventLine];
            }
        }
    }
    [hexView setNeedsDisplay:YES];
    [eventView setNeedsDisplay:YES];
}

- (long)hexTextLines
{
    long hexLines, fileLength;
    
    fileLength = [fileData length];
    hexLines =  fileLength / kBytesPerLine + ((fileLength % kBytesPerLine) ? 1 : 0);
    return fileLength / kBytesPerLine + ((fileLength % kBytesPerLine) ? 1 : 0);
}

- (NSAttributedString *)hexString:(long)line
{
    short bytes, selectCharStart, selectCharStop;
    long byte, startingIndex, fileLength;
    unsigned char dataBytes[kBytesPerLine];
    char textBuffer[256];
    char *pBuffer = textBuffer;
    long hexLines;
    NSMutableAttributedString *string;
    
    fileLength = [fileData length];
    hexLines =  fileLength / kBytesPerLine + ((fileLength % kBytesPerLine) ? 1 : 0);
    
// There may be fewer than kBytesPerLine available if this is the last line of the file

    bytes = kBytesPerLine;
    if (line * kBytesPerLine + kBytesPerLine > fileLength) {
        bytes = fileLength - line * kBytesPerLine;
    }

// Read the data

    startingIndex = dataIndex;
    dataIndex = line * kBytesPerLine; 
    [self dataBytes:(Ptr)dataBytes length:bytes];
    dataIndex = startingIndex;

// Format the string

    pBuffer += sprintf(pBuffer, "0x%0*lx", hexAddressTextCols, line * kBytesPerLine);
    for (byte = 0; byte < kBytesPerLine; byte++) {
        pBuffer += sprintf(pBuffer, (byte < bytes) ? " %0*x" : "   ", kCharsPerByte - 1, dataBytes[byte]); 
    }
    pBuffer += sprintf(pBuffer, "  ["); 
    for (byte = 0; byte < kBytesPerLine; byte++) {
		pBuffer += sprintf(pBuffer, isprint(dataBytes[byte]) ? "%c" : "¥", dataBytes[byte]); 
    }
    pBuffer += sprintf(pBuffer, "]");

// Make a string to return, highling selected text or header text

    string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithCString:textBuffer encoding:NSUTF8StringEncoding]
            attributes:fontDefaultAttributes];
    
// Highlight any text that is selected

    if ((selectedBytesStart >= line * kBytesPerLine) && (selectedBytesStart < (line + 1) * kBytesPerLine) ||
                (selectedBytesStop >= line * kBytesPerLine) && (selectedBytesStop < (line + 1) * kBytesPerLine) ||
                (selectedBytesStart <= line * kBytesPerLine) && (selectedBytesStop >= (line + 1) * kBytesPerLine)) {
        selectCharStart = hexAddressTextCols + 3 +
            ((selectedBytesStart < line * kBytesPerLine) ? 
                            0 : kCharsPerByte * (selectedBytesStart - (line * kBytesPerLine)));
        selectCharStop = hexAddressTextCols + 3 + kCharsPerByte * kBytesPerLine -
            ((selectedBytesStop >= (line + 1) * kBytesPerLine - 1) ? 0 : 
            kCharsPerByte * (((line + 1) * kBytesPerLine) - selectedBytesStop));
        [string addAttribute:NSBackgroundColorAttributeName value:[NSColor selectedTextBackgroundColor] 
                range:NSMakeRange(selectCharStart, selectCharStop - selectCharStart)];
    }
    
// Highlight any text that is in the header

    if (firstDataEventIndex >= line * kBytesPerLine) {
        selectCharStart = hexAddressTextCols + 3;
        selectCharStop = hexAddressTextCols + 3 + kCharsPerByte * kBytesPerLine -
            ((firstDataEventIndex >= (line + 1) * kBytesPerLine - 1) ? 0 : 
            kCharsPerByte * (((line + 1) * kBytesPerLine) - firstDataEventIndex));
        [string addAttribute:NSBackgroundColorAttributeName 
                value:[[NSColor lightGrayColor] highlightWithLevel:0.50]
                range:NSMakeRange(selectCharStart, selectCharStop - selectCharStart)];
    }
    return string;
}

// Return a string with information from the header of the data file

- (NSMutableAttributedString *)infoString
{
    NSMutableAttributedString *MAstring;
    NSAttributedString *Astring;
    char textBuffer[1024];
    char *pBuffer = textBuffer;
 
    pBuffer += sprintf(pBuffer, "  Created %s\r\r", dataFileCreateDate);
	if (fileDataFormat == 5) {
		pBuffer += sprintf(pBuffer, "  Sample interval %d ms\r", sampleIntervalMS);
		pBuffer += sprintf(pBuffer, "  %d spike ticks per ms\r\r", spikeTicksPerMS);
		pBuffer += sprintf(pBuffer, "  Screen:\r");
		pBuffer += sprintf(pBuffer, "    Frame rate %.2f Hz\r", screen.frameRate);
		pBuffer += sprintf(pBuffer, "    Width %d pixels\r", screen.widthPix);
		pBuffer += sprintf(pBuffer, "    Height %d pixels\r", screen.heightPix);
		pBuffer += sprintf(pBuffer, "    %.2f pixels per degree\r", screen.pixPerDeg);
		pBuffer += sprintf(pBuffer, "    Distance %.2f inches\r\r", screen.distanceInches);
		pBuffer += sprintf(pBuffer, "  Eye position calibration:\r");
		pBuffer += sprintf(pBuffer, "    X offset %d units\r", eyeParam.xOffset);
		pBuffer += sprintf(pBuffer, "    Y offset %d units\r", eyeParam.yOffset);
		pBuffer += sprintf(pBuffer, "    %.1f units per degree\r\r", eyeParam.eyeUnitsPerDeg);
		pBuffer += sprintf(pBuffer, "  Fixation point:\r");
		pBuffer += sprintf(pBuffer, "    Azimuth %.1f degrees\r", fixAzimuthDeg);
		pBuffer += sprintf(pBuffer, "    Elevation %.1f degrees\r", fixElevationDeg);
		pBuffer += sprintf(pBuffer, "    Fixation point width %.1f degree\r", fixWidthDeg);
		pBuffer += sprintf(pBuffer, "    Fixation point offset %.1f degree\r", fixOffsetDeg);
	}
    Astring = [[NSAttributedString alloc] initWithString:[NSString stringWithCString:textBuffer encoding:NSUTF8StringEncoding]];
    MAstring = [[NSMutableAttributedString alloc] init];
    [MAstring appendAttributedString:Astring];
    [Astring release];
    return MAstring;
}

- (id)init
{
   NSFont *font;
    
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisplayFormatChange:)
                name:@"Display Format Changed" object:nil];
        
// Set up the default font attributes

        font = [NSFont userFixedPitchFontOfSize:[NSFont kFontSizeToUse]];
        fontDefaultAttributes = [[NSMutableDictionary alloc] init];
        [fontDefaultAttributes setObject:font forKey:NSFontAttributeName];
        [fontDefaultAttributes retain];
        charSize = [[NSString stringWithString:@"X"] sizeWithAttributes:fontDefaultAttributes];
        lineDescenderPix = [font descender];				// Longest line descender in pixels
        [font release];

        [self readPreferences];
    }
    return self;
}

- (float)lineDescenderPix
{
    return lineDescenderPix;
}

- (float)lineHeightPix
{
    return charSize.height;
}

- (short)numEvents
{
    return numEvents;
}

- (BOOL)openFile:(NSString *)fileName
{
    char c, buffer[1024];
    short length, sNumEvents;
    long index, maxEventData;
    NSNumber *fileType;
    NSDictionary *attributes;
    DataEvent *pEvent;

// Get a file wrapper and data object

    fileWrap = [[NSFileWrapper alloc] initWithPath:fileName];
    attributes = [fileWrap fileAttributes];
    fileData = [fileWrap regularFileContents];

// Check that the OSType of the file is correct

    fileType = [attributes objectForKey:NSFileHFSTypeCode];

// Read the header, starting with the format of the data.  For historic reasons, Lablib
// data files all started with '\007' followed by a character count and a list of characters
// in the form "00x", where "x" is the number of the data formate for the file

    dataIndex = 0;
    [self dataBytes:buffer length:2];
    if (buffer[0] != 7 || buffer[1] < 2 || buffer[1] > 6) {
        NSLog(@"Cannot parse first data bytes in file");
        return NO;
    }
    length = buffer[1];
    [self dataBytes:buffer length:length];
    if (buffer[0] != '0' || buffer[1] != '0') {
        NSLog(@"First data bytes in file do not have the right format");
        return NO;
    }
    fileDataFormat = buffer[2] - '0';				// get the data format

// After the code at the start of the file, the next thing is a count of the number of data
// events defined for the file, followed by the definitions of those events.  Definitions consiste
// of a string, which is the name of the event, and a count that specifies the number of data bytes
// that are associated with the event.

	if (fileDataFormat >= 6) {
		if (buffer[4] >= '2') {
			NSRunAlertPanel(@"Invalid Data Format", @"This data format includes data definitions.  (Use DataConvert?)",
						@"OK", nil, nil);
			exit(0);
		}
		[self dataBytes:(Ptr)&numEvents length:sizeof(long)];
	}
	else {
		[self dataBytes:(Ptr)&sNumEvents length:sizeof(short)];
		numEvents = sNumEvents;
	}
    for (index = maxEventNameLength = maxEventData = 0; index < numEvents; index++) {
        [self dataBytes:(Ptr)&c length:1L];
        [self dataBytes:(Ptr)&eventID[index].name length:(long)c];
        [self dataBytes:(Ptr)&eventID[index].dataBytes length:sizeof(&eventID[index].dataBytes)];
      	if (maxEventNameLength < strlen(eventID[index].name)) { 
                maxEventNameLength = strlen(eventID[index].name);
        }
      	if (maxEventData < eventID[index].dataBytes) { 
                maxEventData = eventID[index].dataBytes;
        }
        enabledEvents[index] = true;				// all events start enabled
    }
	if (fileDataFormat == 5) {
		[self dataBytes:(Ptr)&sampleIntervalMS length:sizeof(sampleIntervalMS)];
		[self dataBytes:(Ptr)&spikeTicksPerMS length:sizeof(spikeTicksPerMS)];

		[self dataBytes:(Ptr)&screen.widthPix length:sizeof(screen.widthPix)];
		[self dataBytes:(Ptr)&screen.heightPix length:sizeof(screen.heightPix)];
		[self dataBytes:(Ptr)&screen.pixPerDeg length:sizeof(screen.pixPerDeg)];
		[self dataBytes:(Ptr)&screen.distanceInches length:sizeof(screen.distanceInches)];
		[self dataBytes:(Ptr)&screen.frameRate length:sizeof(screen.frameRate)];
	  
		[self dataBytes:(Ptr)&eyeParam.xOffset length:sizeof(eyeParam.xOffset)];
		[self dataBytes:(Ptr)&eyeParam.yOffset length:sizeof(eyeParam.yOffset)];
		[self dataBytes:(Ptr)&eyeParam.eyeUnitsPerDeg length:sizeof(eyeParam.eyeUnitsPerDeg)];

		[self dataBytes:(Ptr)&fixAzimuthDeg length:sizeof(fixAzimuthDeg)];
		[self dataBytes:(Ptr)&fixElevationDeg length:sizeof(fixElevationDeg)];
		[self dataBytes:(Ptr)&fixWidthDeg length:sizeof(fixWidthDeg)];
		[self dataBytes:(Ptr)&fixOffsetDeg length:sizeof(fixOffsetDeg)];
	}
    [self dataBytes:(Ptr)&c length:1L];
    [self dataBytes:(Ptr)&dataFileCreateDate length:(long)c];
    dataFileCreateDate[(long)c] = ' ';
    dataFileCreateDate[c + 1] = '\0';
    [self dataBytes:(Ptr)&c length:1L];
    [self dataBytes:(Ptr)&dataFileCreateTime length:(long)c];
    dataFileCreateTime[(long)c] = '\0';
    fileStartDate = [[NSCalendarDate alloc]  
        initWithString:[NSString stringWithCString:strcat(dataFileCreateDate, dataFileCreateTime) encoding:NSUTF8StringEncoding]
        calendarFormat:@"%B %d, %Y %H:%M:%S"];
    firstDataEventIndex = dataIndex;
    pEvent = [self readEvent];					// Read the first event to get the event time at trial start
    fileStartTime = pEvent->timeOfDay;

    dataIndex = firstDataEventIndex;				// Set to the start of data events for counting
    if (![self countEvents]) {					// All events have been enabled for the count
        return(NO);
    }

// Figure out how many columns will be needed to display the data

    eventIndexTextCols = log((double)numEvents) / log(10.0) + 1;
    eventDataTextCols = log((double)maxEventData) / log(10.0) + 1;
    if (eventDataTextCols < 2) {
        eventDataTextCols = 2;
    }

    return YES;
}

- (void)printShowingPrintPanel:(BOOL)flag
{
    NSPrintInfo *printInfo = [self printInfo];
    NSPrintOperation *printOp;
    NSPrintPanel *printPanel;
   
    printView = [[PrintView alloc] initWithInfo:self printInfo:printInfo];
    switch (printMode) {
    case kPrintHex:
        [printView printableLines:[self hexTextLines]];
        break;
    case kPrintEvents:
    default:
        [printView printableLines:[self eventTextLines]];
        break;
    }
    printOp = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
    printPanel = [NSPrintPanel printPanel];
    //    [printOp setAccessoryView:printSelectPanel];
    //  [printPanel addAccessoryController:printSelectPanel];
    [printOp setPrintPanel:printPanel];
    [printOp setShowsPrintPanel:flag];
    [printOp setShowsProgressPanel:flag];
    [printOp runOperation];
    [printView release];
}

- (IBAction)printSelectType:(id)sender 
{
    printMode = [sender selectedRow];
    switch (printMode) {
    case kPrintHex:
        [printView printableLines:[self hexTextLines]];
        break;
    case kPrintEvents:
    default:
        [printView printableLines:[self eventTextLines]];
        break;
    }
}

- (NSString *)printString:(long)line
{
    NSString *string;
    NSAttributedString *attribString;
    
    switch (printMode) {
    case kPrintHex:
        attribString = [self hexString:line];
        break;
    case kPrintEvents:
    default:
        attribString = [self eventString:line];
        break;
    }
    string = [[NSString alloc] initWithString:[attribString string]];
    return string;
}

- (DataEvent *)readEvent
{
    short index, channel;
    static long lastSampleTime[kADChannels] = {0};
    static long spikeStartTime = 0;
    BOOL enabledEvent = NO;

// Nobody wants events that are not enabled. We skip over all disabled events until we find
// an enabled event.

    do {
        currentEventIndex = dataIndex;
        if (![self dataBytes:(Ptr)&dataEvent.type length:1]) {		// read the event code
            return nil;
        }
        if (dataEvent.type >= numEvents) {
            return nil;
        }
        if (eventID[dataEvent.type].dataBytes < 0) {
            if (![self dataBytes:(Ptr)&dataEvent.dataBytes length:sizeof(dataEvent.dataBytes)]) {
                return nil;
            }
        }
        else {
            dataEvent.dataBytes = eventID[dataEvent.type].dataBytes;
        }
        if (enabledEvents[dataEvent.type]) {
            enabledEvent = YES;
        }
        else {
            dataIndex += dataEvent.dataBytes + sizeof(dataEvent.timeOfDay);
        }
    } while (!enabledEvent);

// Read the data bytes

    if (dataEvent.dataBufferLength < dataEvent.dataBytes + 1) {
        [self adjustParamBuffer:dataEvent.dataBytes + 1];
    }
    if (![self dataBytes:(Ptr)dataEvent.pData length:dataEvent.dataBytes]) {
        return nil;
    }
    if (dataEvent.type == [self eventCode:"text"]) {			// NULL terminate text strings
        dataEvent.pData[dataEvent.dataBytes] = '\0';
    }

// Get the time at which this event occurred

    if (![self dataBytes:(Ptr)&dataEvent.timeOfDay length:sizeof(dataEvent.timeOfDay)]) {
        return nil;
    }
    dataEvent.time = (trialStartTimeLL == -1) ? -1 : dataEvent.timeOfDay - trialStartTimeLL;

// Certain special events cause timebases to be reset or need a relative time

    if (dataEvent.type == [self eventCode:"trialStart"]) {
		trialStartTimeLL = dataEvent.timeOfDay;
		dataEvent.time = 0;
    }
    else if (dataEvent.type == [self eventCode:"sampleZero"]) {
        for (index = 0; index < kADChannels; index++) {
            lastSampleTime[index] = 0;
        }
    }
    else if (dataEvent.type == [self eventCode:"spikeZero"]) {
        spikeStartTime = dataEvent.timeOfDay;
    }
    else if (dataEvent.type == [self eventCode:"sample01"]) {
        dataEvent.time = lastSampleTime[0];
        lastSampleTime[0] += sampleIntervalMS;
        lastSampleTime[1] += sampleIntervalMS;
    }
    else if (dataEvent.type == [self eventCode:"sample"]) {
        channel = ((SampleData *)dataEvent.pData)->channel;
        dataEvent.time = lastSampleTime[channel];
        lastSampleTime[channel] += sampleIntervalMS;
    }
    else if (dataEvent.type == [self eventCode:"spike"]) {
        dataEvent.time = spikeStartTime - trialStartTimeLL + 
                    ((SpikeData *)dataEvent.pData)->time;
    }
    else if (dataEvent.type == [self eventCode:"spike0"]) {
        dataEvent.time = spikeStartTime - trialStartTimeLL + 
                    (*(long *)dataEvent.pData);
    }
    return(&dataEvent);
}

// Read event types.  None of the rest of the event is loaded.  This is used only by 
// countEvents.  It is faster than read events and saves time when the whole file is
// being scanned immediately after opening.

- (DataEvent *)readEventType
{
    currentEventIndex = dataIndex;
    if (![self dataBytes:(Ptr)&dataEvent.type length:1]) {		// read the event code
        return nil;
    }
    if (dataEvent.type >= numEvents) {				// check that it is a valid event
        return nil;
    }

// Get the amount by which to advance the data pointer

    if (eventID[dataEvent.type].dataBytes < 0) {
        if (![self dataBytes:(Ptr)&dataEvent.dataBytes length:sizeof(dataEvent.dataBytes)]) {
            return nil;
        }
    }
    else {
        dataEvent.dataBytes = eventID[dataEvent.type].dataBytes;
    }
    dataIndex += dataEvent.dataBytes + sizeof(dataEvent.timeOfDay);	// advance the data pointer
    return(&dataEvent);
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    if (![self openFile:fileName]) {
        return NO;
    }
    dataFileName = [[NSString alloc] initWithString:fileName];
    [defView numEvents:numEvents];				// Give event definition view number of events
    [eventView setDisplayableLines:[self eventTextLines]];	// Give the event view number of enabled events
    [hexView setDisplayableLines:[self hexTextLines]];		// Give the hex view number of displayable lines
   return YES;
}

- (void)readPreferences
{
    NSUserDefaults *defaults;

    defaults = [NSUserDefaults standardUserDefaults];
    dataFormat = [defaults integerForKey:DIDataFormatKey];
    displayEventData = [defaults boolForKey:DIShowDataKey];
    displayEventTime = [defaults boolForKey:DIShowTimeKey];
    displayFileOffset = [defaults boolForKey:DIShowAddressKey];
    displayTimeOfDay = [defaults boolForKey:DIShowTimeOfDayKey];
}

- (NSString *)windowNibName
{
    return @"InspectorDoc";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [defView numEvents:numEvents];			// Give the list of events to the event definition view

// We shouldn't have to do the following, but something seems to be screwed up with the Interface Builder's
// handling of the size of a NSDrawer

    [infoDrawer setContentSize:NSMakeSize(200, 200)];
}

@end