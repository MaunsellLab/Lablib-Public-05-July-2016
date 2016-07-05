//
//  DataFile.m
//  DataConvert
//
//  Created by John Maunsell on Sun Jul 07 2002.
//  Copyright (c) 2005. All rights reserved.
//

#import "DataFile.h"
#import "DefView.h"
#import "EventView.h"
#import "HexView.h"
#import "PrintView.h"

#define kADChannels			8
#define	kBytesPerLine		16
#define kCharsPerByte		3
#define	kEventTimeTextCols	4
#define kHexAddressPadCols	3
#define kTextBufferLength	256

enum {kPrintEvents = 0, kPrintHex};
enum {kCharFormat = 0, kShortFormat, kLongFormat, kFloatFormat, kDoubleFormat};

@implementation DataFile

NSString *LLDataType = @"Lablib data document";
NSString *LLMatlabType = @"Lablib Matlab document";
NSString *LLMatlabText = @"Matlab Text";

static short		formatChars[] = {2, 6, 11, 3, 3};
static PrintView	*printView;

// Read bytes from the data buffer, relative to the current pointer, incrementing the pointer afterward

- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes
{
    NSRange range;
    
    if (dataIndex + numBytes > fileLength) {
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

// Override the dataOfType method to return data in different formats

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError;
{
	if ([typeName isEqualToString:LLDataType]) {
		return [dataReader fileData];
	}
	else {
//		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
		return nil;
	}
}

- (void)dealloc
{
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];

	[defaultsController removeObserver:self forKeyPath:@"values.DCDataFormat"];
	[defaultsController removeObserver:self forKeyPath:@"values.DCShowAddress"];
	[defaultsController removeObserver:self forKeyPath:@"values.DCShowData"];
	[defaultsController removeObserver:self forKeyPath:@"values.DCShowTime"];
	[defaultsController removeObserver:self forKeyPath:@"values.DCShowTimeOfDay"];
	[dataReader release];
    [dataFileName release];
    [super dealloc];
}

// Return a string for one event definition

- (NSAttributedString *)definitionString:(long)line
{
    char textBuffer[256];
    NSAttributedString *aString;
    LLDataEventDef *eventDef = [dataReader dataEventDefWithIndex:line];
	
    sprintf(textBuffer, "%-*ld %-*s %*ld %*ld", eventIndexTextCols, line, 
			(int)[dataReader maxEventNameLength],  [[eventDef name] cStringUsingEncoding:NSASCIIStringEncoding],
            eventDataTextCols, [eventDef dataBytes], eventCountTextCols, [dataReader eventCounts][line]);
    aString = [[[NSAttributedString alloc] 
            initWithString:[NSString stringWithCString:textBuffer encoding:NSASCIIStringEncoding]
            attributes:fontDefaultAttributes] autorelease];
    return aString;
}

- (BOOL)enoughRoomInBuffer:(long)filled format:(short)valueFormat length:(short)bufferLength margin:(short)margin
{
    BOOL isEnough = YES;
    
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

- (void)eventSelectionChanged:(long )newSelectionLine clickCount:(short)clicks;
{
    DataEvent *pEvent;
    
    if (newSelectionLine == selectedEventLine && clicks < 2) {
        selectedEventLine = selectedEventCode = selectedBytesStart = selectedBytesStop = -1;
    }
    else {
        selectedEventLine = newSelectionLine;
        pEvent = [dataReader findEventByLine:selectedEventLine index:&selectedBytesStart];
        selectedEventCode = pEvent->code;
        selectedBytesStop = selectedBytesStart + [dataReader bytesInDataEvent:pEvent];
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
    long index, filled, dataFormat;
    char textBuffer[kTextBufferLength];
    char *pBuffer  = textBuffer;
	long eventIndex;
    DataEvent *pEvent;
    NSDate *eventDate;
    NSDateFormatter *dateFormatter;
    
//    NSCalendarDate *eventDate;
    NSMutableAttributedString *string;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	dataFormat = [defaults integerForKey:DCDataFormatKey];
    if ((pEvent = [dataReader findEventByLine:line index:&eventIndex]) == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:@"DataConvert" informativeText:@"eventString: nil event returned."];
		exit(0);
	}
	index = [pEvent->data length];		// test for valid NSData object
    if ([defaults boolForKey:DCShowAddressKey]) {
    	pBuffer += sprintf(pBuffer, "0x%0*lx ", hexAddressTextCols, eventIndex);
    }
    if ([defaults boolForKey:DCShowTimeOfDayKey]) {
        eventDate = [[dataReader fileDate] dateByAddingTimeInterval:(unsigned long)(pEvent->time / 1000.0)];
//        eventDate = [[dataReader fileDate] dateByAddingYears:0 months:0 days:0 hours:0 minutes:0
//                                                     seconds:(unsigned long)(pEvent->time / 1000.0)];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        pBuffer += sprintf(pBuffer, "%s", [[dateFormatter stringFromDate:eventDate] UTF8String]);
        pBuffer += sprintf(pBuffer, ".%03ld", (unsigned long)(pEvent->time % 1000));
//        pBuffer += sprintf(pBuffer, "%02ld:%02ld:%02ld.%03ld ",
//                    (long)[eventDate hourOfDay], (long)[eventDate minuteOfHour], (long)[eventDate secondOfMinute],
//                    (unsigned long)(pEvent->time % 1000));
        [dateFormatter release];
    }
    if ([defaults boolForKey:DCShowTimeKey]) {
		pBuffer += sprintf(pBuffer, "%*ld ", kEventTimeTextCols, pEvent->trialTime);
    }

// Event name and data

    pBuffer += sprintf(pBuffer, "%-*s ", maxEventNameLength, [pEvent->name cStringUsingEncoding:NSASCIIStringEncoding]);
    if (![defaults boolForKey:DCShowDataKey]) {
        sprintf(pBuffer, "\r");
    }
    else {
//        if ([pEvent->name isEqualToString:@"text"]) {
//            pBuffer += sprintf(pBuffer, "\"%s\"", (char *)[pEvent->data bytes]);
//        }
        if ([pEvent->name isEqualToString:@"text"]) {
            pBuffer += sprintf(pBuffer, "\"%.*s\"", (int)[pEvent->data length], (char *)[pEvent->data bytes]);
        }
        else if ([pEvent->name isEqualToString:@"sample01"]) {
            pBuffer += sprintf(pBuffer, "%*d %*d ", formatChars[kShortFormat], ((short *)[pEvent->data bytes])[0], 
                    formatChars[kShortFormat], ((short *)[pEvent->data bytes])[1]);
        }
         else if ([pEvent->name isEqualToString:@"spike"]) {
            pBuffer += sprintf(pBuffer, "%*d %*ld ", formatChars[kShortFormat], 
                ((SpikeData *)[pEvent->data bytes])->channel, formatChars[kLongFormat], 
                ((SpikeData *)[pEvent->data bytes])->time);
        }
        else if (([pEvent->name isEqualToString:@"trialStart"]) ||
					([pEvent->name isEqualToString:@"trialEnd"]) ||
					([pEvent->name isEqualToString:@"stimulusOn"]) ||
					([pEvent->name isEqualToString:@"stimulusOff"])) {
				pBuffer += sprintf(pBuffer, "%*ld ", formatChars[kLongFormat],  *(long *)[pEvent->data bytes]);
		}
         else if ([pEvent->name isEqualToString:@"fixWindow"]) {
            pBuffer += sprintf(pBuffer, "%*ld:  %*f %*f %*f %*f ", 
                    formatChars[kShortFormat], ((FixWindowData *)[pEvent->data bytes])->index, 
                    formatChars[kShortFormat], ((FixWindowData *)[pEvent->data bytes])->windowUnits.origin.x, 
                    formatChars[kShortFormat], ((FixWindowData *)[pEvent->data bytes])->windowUnits.origin.y, 
                    formatChars[kShortFormat], ((FixWindowData *)[pEvent->data bytes])->windowUnits.size.width, 
                    formatChars[kShortFormat], ((FixWindowData *)[pEvent->data bytes])->windowUnits.size.height);
        }
        else {
            for (index = 0; index < [pEvent->data length]; ) {
                filled = (unsigned long)pBuffer - (unsigned long)textBuffer;
                if (![self enoughRoomInBuffer:filled format:dataFormat length:kTextBufferLength margin:8]) {
					pBuffer += sprintf(pBuffer, "...");
					break;
                }
                switch (dataFormat) {
                case kCharFormat:
                    pBuffer += sprintf(pBuffer, "%0*hhx ", formatChars[dataFormat], 
                                *(unsigned char *)([pEvent->data bytes] + index));
                    index += sizeof(char);
                    break;
                case kShortFormat:
                    if ([pEvent->data length] - index >= sizeof(short)) {
                        pBuffer += sprintf(pBuffer, "%*d ", formatChars[dataFormat],
                                *(short *)([pEvent->data bytes] + index));
                    }
                    index += sizeof(short);
                    break;
                case kLongFormat:
                    if ([pEvent->data length] - index >= sizeof(long)) {
                        pBuffer += sprintf(pBuffer, "%*ld ", formatChars[dataFormat],
                                *(long *)([pEvent->data bytes] + index));
                    }
                    index += sizeof(long);
                    break;
                case kFloatFormat:
                    if ([pEvent->data length] - index >= sizeof(float)) {
                        pBuffer += sprintf(pBuffer, "% .*e ", formatChars[dataFormat],
                                *(float *)([pEvent->data bytes] + index));
                    }
                    index += sizeof(float);
                    break;
                case kDoubleFormat:
                    if ([pEvent->data length] - index >= sizeof(double)) {
                        pBuffer += sprintf(pBuffer, "% .*e ", formatChars[dataFormat],
                                *(double *)([pEvent->data bytes] + index));
                    }
                    index += sizeof(double);
                    break;
                }
            }
        }
    }
    string = [[NSMutableAttributedString alloc] 
              initWithString:[NSString stringWithCString:textBuffer encoding:NSASCIIStringEncoding]
            attributes:fontDefaultAttributes];
    if (line == selectedEventLine) {
        [string addAttribute:NSBackgroundColorAttributeName value:[NSColor selectedTextBackgroundColor]
            range:NSMakeRange(0, [string length])];
    }
    return string;
}

- (void)hexSelectionChanged:(long)newSelectionLine xPix:(short)x clickCount:(short)clicks
{
    short charOnLine, addressChars;
    unsigned long byteSelected;
    long eventLine;
    DataEvent *pEvent;
    
    addressChars = hexAddressTextCols + kHexAddressPadCols;
    charOnLine = x / charSize.width;

// If there was a double click outside the data byte field, ignore it

    if ((charOnLine < addressChars || charOnLine >= addressChars + kBytesPerLine * kCharsPerByte)
                        && clicks < 2) {
         selectedEventLine = selectedBytesStart = selectedEventCode = selectedBytesStop = -1;
    }
    else {
        byteSelected = newSelectionLine * kBytesPerLine + (charOnLine - addressChars) / kCharsPerByte;
		pEvent = [dataReader findEventByIndex:byteSelected line:&eventLine];
        if (pEvent == nil || (eventLine == selectedEventLine && clicks < 2)) {
            selectedEventLine = selectedBytesStart = selectedEventCode = selectedBytesStop = -1;
        }
        else {
            selectedEventLine = eventLine;
            selectedEventCode = pEvent->code;
            selectedBytesStart = pEvent->fileIndex;
            selectedBytesStop = selectedBytesStart + [dataReader bytesInDataEvent:pEvent];
            if (clicks >= 2) {
                [eventView centerViewOnLine:selectedEventLine];
            }
        }
    }
    [hexView setNeedsDisplay:YES];
    [eventView setNeedsDisplay:YES];
}

- (NSAttributedString *)hexString:(long)line
{
    short bytes, selectCharStart, selectCharStop;
    long byte, startingIndex;
    unsigned char dataBytes[kBytesPerLine];
    char textBuffer[256];
    char *pBuffer = textBuffer;
    NSMutableAttributedString *string;
    
// There may be fewer than kBytesPerLine available if this is the last line of the file

    bytes = kBytesPerLine;
    if (line * kBytesPerLine + kBytesPerLine > fileLength) {
        bytes = fileLength - line * kBytesPerLine;
    }

// Read the data

    startingIndex = [dataReader dataIndex];
    [dataReader dataBytes:(Ptr)dataBytes range:NSMakeRange(line * kBytesPerLine, bytes)];
    [dataReader setDataIndex:startingIndex];

// Format the string

    pBuffer += sprintf(pBuffer, "0x%0*lx", hexAddressTextCols, line * kBytesPerLine);
    for (byte = 0; byte < kBytesPerLine; byte++) {
        if (byte < bytes) {
            pBuffer += sprintf(pBuffer, " %0*x", kCharsPerByte - 1, dataBytes[byte]);
        }
        else {
            pBuffer += sprintf(pBuffer, "   "); 

        }
    }
    pBuffer += sprintf(pBuffer, "  ["); 
    for (byte = 0; byte < kBytesPerLine; byte++) {
		if (byte >= bytes) {
			break;
		}
		if (isprint(dataBytes[byte])) {
			pBuffer += sprintf(pBuffer, "%c", dataBytes[byte]);
		}
		else {
			pBuffer += sprintf(pBuffer, "*");
		}
    }
    pBuffer += sprintf(pBuffer, "]");

// Make a string to return, highling selected text or header text

    string = [[NSMutableAttributedString alloc] 
              initWithString:[NSString stringWithCString:textBuffer encoding:NSASCIIStringEncoding]
              attributes:fontDefaultAttributes];
    
// Highlight any text that is selected

    if (((selectedBytesStart >= line * kBytesPerLine) && (selectedBytesStart < (line + 1) * kBytesPerLine)) ||
                ((selectedBytesStop >= line * kBytesPerLine) && (selectedBytesStop < (line + 1) * kBytesPerLine)) ||
                ((selectedBytesStart <= line * kBytesPerLine) && (selectedBytesStop >= (line + 1) * kBytesPerLine))) {
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

    Astring = [[NSAttributedString alloc] initWithString:
			[NSString stringWithFormat:@ "  Data Format %.1f\r  created %@", 
			[dataReader dataFormat], [[dataReader fileDate] description]]];
    MAstring = [[[NSMutableAttributedString alloc] init] autorelease];
    [MAstring appendAttributedString:Astring];
    [Astring release];
    return MAstring;
}

- (id)init
{
    NSFont *font;
    NSUserDefaultsController *defaultsController;
	
    if ((self = [super init]) != nil) {
        
		printMode = kPrintEvents;
		
// Set up the default font attributes

        font = [NSFont userFixedPitchFontOfSize:[NSFont kFontSizeToUse]];
        fontDefaultAttributes = [[NSMutableDictionary alloc] init];
        [fontDefaultAttributes setObject:font forKey:NSFontAttributeName];
        [fontDefaultAttributes retain];
        charSize = [@"X" sizeWithAttributes:fontDefaultAttributes];
        lineDescenderPix = [font descender];				// Longest line descender in pixels
		selectedEventLine = selectedBytesStart = selectedEventCode = selectedBytesStop = -1;

// Set up to monitor changes to the display preferences

		defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[defaultsController addObserver:self forKeyPath:@"values.DCDataFormat"
						options:NSKeyValueObservingOptionNew context:nil];
		[defaultsController addObserver:self forKeyPath:@"values.DCShowAddress"
						options:NSKeyValueObservingOptionNew context:nil];
		[defaultsController addObserver:self forKeyPath:@"values.DCShowData"
						options:NSKeyValueObservingOptionNew context:nil];
		[defaultsController addObserver:self forKeyPath:@"values.DCShowTime"
						options:NSKeyValueObservingOptionNew context:nil];
		[defaultsController addObserver:self forKeyPath:@"values.DCShowTimeOfDay"
						options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (float)lineDescenderPix;
{
    return lineDescenderPix;
}

- (float)lineHeightPix;
{
    return charSize.height;
}

// The following method gets called whenever one of our display preferences get changed.  We just have to ask
// the eventView to redisplay

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [eventView setNeedsDisplay:YES];
}

- (void)printShowingPrintPanel:(BOOL)flag
{
    NSPrintInfo *printInfo = [self printInfo];
    NSPrintOperation *printOp;
    NSPrintPanel *printPanel;
    
    printView = [[PrintView alloc] initWithInfo:self printInfo:printInfo];
    switch (printMode) {
    case kPrintHex:
        [printView printableLines:hexTextLines];
        break;
    case kPrintEvents:
    default:
        [printView printableLines:[dataReader enabledEventsInFile]];
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
        [printView printableLines:hexTextLines];
        break;
    case kPrintEvents:
    default:
        [printView printableLines:[dataReader enabledEventsInFile]];
        break;
    }
}

- (NSString *)printString:(long)line;
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

// This is the method that is called when it is time to read the contents of a document

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	dataReader = [[LLDataFileReader alloc] init];
	if (![dataReader readFromURL:absoluteURL ofType:typeName error:outError]) {
		[dataReader release];
		dataReader = nil;
		return NO;
	}
    dataFileName = [[NSString alloc] initWithString:
				[[[absoluteURL path] stringByDeletingPathExtension] lastPathComponent]];

// Get the formatting values that are based on the file contents

    eventIndexTextCols = log((double)[dataReader numEvents]) / log(10.0) + 1;
	maxEventNameLength = [dataReader maxEventNameLength];
	eventCountTextCols = log([dataReader maxEventCount]) / log(10.0) + 1;
    eventDataTextCols = MAX(2, log((double)[dataReader maxEventDataBytes]) / log(10.0) + 1);
    fileLength = [dataReader fileBytes];
	firstDataEventIndex = [dataReader firstDataEventIndex];
    for (hexAddressTextCols = 1; fileLength > (0x1L << (4 * hexAddressTextCols)); hexAddressTextCols++) {};
    hexTextLines =  fileLength / kBytesPerLine + ((fileLength % kBytesPerLine) ? 1 : 0);
	return YES;
}

- (void)setEnabledEvents:(BOOL *)array
{
    long index, numEnabled, numEvents;
    
	[dataReader setEnabledEvents:array];
	numEvents = [dataReader numEvents];
    for (index = numEnabled = 0; index < numEvents; index++) {
		numEnabled += array[index];
    }
    [enableButton setEnabled:(numEnabled < numEvents)];
    [disableButton setEnabled:(numEnabled > 0)];
    
// If there is a selected event line we need to adjust for the change in enabled events

    if (selectedEventCode >= 0) {
    
// If the selected type is no longer enabled, make no line enabled

        if (!array[selectedEventCode]) {
            selectedEventLine = selectedBytesStart = selectedEventCode = selectedBytesStop = -1;
        }
    
// If the selected type is still enabled, get the new line that it is on

        else {
			[dataReader findEventByIndex:selectedBytesStart line:&selectedEventLine];
        }
    }
    [eventView setDisplayableLines:[dataReader enabledEventsInFile]];	// update event view
    [hexView setDisplayableLines:hexTextLines];		// *** should not have to do this when first window is gone
}

- (NSString *)windowNibName;
{
    return @"ConverterDoc";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    [defView setNumEvents:[dataReader numEvents]];                      // Give event definition view number of events
    [eventView setDisplayableLines:[dataReader enabledEventsInFile]];	// Give the event view number of enabled events
    [hexView setDisplayableLines:hexTextLines];                         // Give the hex view number of displayable lines

// We shouldn't have to do the following, but something seems to be screwed up with the Interface Builder's
// handling of the size of a NSDrawer

    [infoDrawer setContentSize:NSMakeSize(200, 200)];
    
    //   [[aController window] makeKeyAndOrderFront:self];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
{
    BOOL result;
    NSData *eventData;
	NSFileWrapper *matlabFileWrapper;

	
	if ([typeName isEqualTo:LLDataType]) {				// do nothing if asked to save data - we don't edit
        if (outError != NULL) {
            *outError = nil;
        }
		return YES;
	}
	if (![typeName isEqualTo:LLMatlabText]) {			// we only handle Matlab text (for now)
//		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
		return NO;
	}
	if (![absoluteURL isFileURL]) {						// must be a file URL
//		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
		return NO;
	}
	if (![dataReader dataDefinitions]) {
		NSLog(@"File %@ does not have data definitions; it cannot be automatically converted to Matlab text",
						dataFileName);
		return(NO);
	}
	eventData = [dataReader eventsAsMatlabStrings]; 
    matlabFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:eventData];
    result = [matlabFileWrapper writeToURL:absoluteURL
            options:NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
            originalContentsURL:nil error:outError];
//  if ([matlabFileWrapper writeToFile:[absoluteURL path] atomically:YES updateFilenames:YES]) {
//        if (outError != NULL) {
//            *outError = nil;
//        }
//	}
//	else {
//	}
	[matlabFileWrapper release];
	return result;
}

@end