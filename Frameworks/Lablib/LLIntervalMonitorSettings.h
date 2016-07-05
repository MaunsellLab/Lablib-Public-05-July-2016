//
//  LLIntervalMonitorSettings.h
//  Lablib
//
//  Created by John Maunsell on Thu Jul 31 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLIntervalMonitorSettings : NSWindowController {

@protected
	NSString *IDString;
 
	IBOutlet NSTextField	*greaterStandardField;
	IBOutlet NSTextField	*lessStandardField;

	IBOutlet NSButton	 	*successGreaterButton;
    IBOutlet NSButton	 	*successLessButton;
	IBOutlet NSTextField	*successGreaterCountField;
	IBOutlet NSTextField	*successGreaterMSField;
	IBOutlet NSTextField	*successLessCountField;
	IBOutlet NSTextField	*successLessMSField;

    IBOutlet NSButton	 	*warnDisarmButton;
    IBOutlet NSButton	 	*warnSequentialButton;
	IBOutlet NSTextField	*warnSequentialCountField;

    IBOutlet NSButton	 	*warnGreaterButton;
	IBOutlet NSTextField	*warnGreaterCountField;

    IBOutlet NSButton	 	*warnLessButton;
	IBOutlet NSTextField	*warnLessCountField;
}

- (id)initWithID:(NSString *)ID;
- (NSString *)uniqueKey:(NSString *)commonKey;

- (IBAction)changeDoSuccessGreater:(id)sender;
- (IBAction)changeDoSuccessLess:(id)sender;
- (IBAction)changeDoWarnDisarm:(id)sender;
- (IBAction)changeDoWarnGreater:(id)sender;
- (IBAction)changeDoWarnLess:(id)sender;
- (IBAction)changeDoWarnSequential:(id)sender;
- (IBAction)changeSuccessGreaterCount:(id)sender;
- (IBAction)changeSuccessGreaterMS:(id)sender;
- (IBAction)changeSuccessLessCount:(id)sender;
- (IBAction)changeSuccessLessMS:(id)sender;
- (IBAction)changeWarnGreaterCount:(id)sender;
- (IBAction)changeWarnLessCount:(id)sender;
- (IBAction)changeWarnSequentialCount:(id)sender;

@end
