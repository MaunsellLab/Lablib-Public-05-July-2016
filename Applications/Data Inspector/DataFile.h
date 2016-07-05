//
//  DataFile.h
//  Data Inspector
//
//  Created by John Maunsell on Sun Jul 28 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface DataFile : NSDocument {

    IBOutlet id 			defView;
    IBOutlet NSButton 		*disableButton;
    IBOutlet NSButton 		*enableButton;
    IBOutlet id 			eventView;
    IBOutlet id 			hexView;
    IBOutlet NSDrawer		*infoDrawer;
    IBOutlet id				infoView;
    IBOutlet NSView			*printSelectPanel;
    
	BOOL					dataDefinitions;
    long					dataIndex;
    DataEventID 			eventID[kMaxEvents];
    NSData					*fileData;
    NSFileWrapper 			*fileWrap;
	long					numEvents;				// Number of data events defined in a data file
    short					sampleIntervalMS;
}

- (void)adjustParamBuffer:(long)lengthNeeded;
- (long)bytesInDataEvent:(DataEvent *)pEvent;
- (BOOL)countEvents;
- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes;
- (NSString *)dataFileName;
- (NSAttributedString *)definitionString:(long)line;
- (void)enabledEvents:(EnabledArray)array;
- (BOOL)enoughRoomInBuffer:(long)filled format:(short)valueFormat length:(short)bufferLength margin:(short)margin;
- (unsigned char)eventCode:(char *)eventName;
- (void)eventSelectionChanged:(long )newSelectionLine clickCount:(short)clicks;
- (NSAttributedString *)eventString:(long)line;
- (long)eventTextLines;
- (DataEvent *)findEventByIndex:(long)index line:(long *)pLine;
- (DataEvent *)findEventByLine:(long)line index:(long *)pIndex;
- (void)hexSelectionChanged:(long )newSelectionLine xPix:(short)x clickCount:(short)clicks;
- (NSAttributedString *)hexString:(long)line;
- (long)hexTextLines;
- (NSMutableAttributedString *)infoString;
- (float)lineDescenderPix;
- (float)lineHeightPix;
- (short)numEvents;
- (BOOL)openFile:(NSString *)fileName;
- (IBAction)printSelectType:(id)sender;
- (NSString *)printString:(long)line;
- (DataEvent *)readEvent;
- (DataEvent *)readEventType;
- (void)readPreferences;

@end
