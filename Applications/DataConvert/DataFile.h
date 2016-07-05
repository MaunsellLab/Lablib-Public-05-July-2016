//
//  DataFile.h
//  DataConvert
//
//  Created by John Maunsell on Sun Jul 28 2002.
//  Copyright (c) 2002-2011. All rights reserved.
//


NSString *LLDataType;
NSString *LLMatlabType;
NSString *LLMatlabText;

@interface DataFile : NSDocument {

    IBOutlet id 			defView;
    IBOutlet NSButton 		*disableButton;
    IBOutlet NSButton 		*enableButton;
    IBOutlet id 			eventView;
    IBOutlet id 			hexView;
    IBOutlet NSDrawer		*infoDrawer;
    IBOutlet id				infoView;
    IBOutlet NSView			*printSelectPanel;
    
	NSSize					charSize;
	NSString				*dataFileName;
	long					dataIndex;
	LLDataFileReader		*dataReader;
	int						eventCountTextCols;
	int						eventDataTextCols;
	int						eventIndexTextCols;
    NSData					*fileData;
	unsigned long			fileLength;
    NSFileWrapper 			*fileWrap;
	long					firstDataEventIndex;			// file index for first data event
	NSMutableDictionary		*fontDefaultAttributes;
	int						hexAddressTextCols;
	unsigned long			hexTextLines;
	float					lineDescenderPix;
	int						maxEventDataBytes;
	int						maxEventNameLength;
	BOOL					printMode;
    short					sampleIntervalMS;
	long					selectedEventLine;
	long					selectedEventCode;
	long					selectedBytesStart;
	long					selectedBytesStop;
}

- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes;
- (NSString *)dataFileName;
- (NSAttributedString *)definitionString:(long)line;
- (void)eventSelectionChanged:(long )newSelectionLine clickCount:(short)clicks;
- (NSAttributedString *)eventString:(long)line;
- (void)hexSelectionChanged:(long)newSelectionLine xPix:(short)x clickCount:(short)clicks;
- (NSAttributedString *)hexString:(long)line;
- (NSMutableAttributedString *)infoString;
- (float)lineDescenderPix;
- (float)lineHeightPix;
- (IBAction)printSelectType:(id)sender;
- (NSString *)printString:(long)line;
- (void)setEnabledEvents:(BOOL *)array;

@end
