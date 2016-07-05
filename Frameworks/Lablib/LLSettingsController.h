//
//  LLSettingsController.h
//  Lablib
//
//  Created by John Maunsell on Sat Jun 14 2003.
//  Copyright (c) 2003. All rights reserved.
//

extern NSString *LLSettingsChanged;

@interface LLSettingsController : NSWindowController {

	BOOL					disallowNextSelectionChange;
	NSMutableArray			*settingsNameArray;

    IBOutlet NSButton	 	*deleteButton;
    IBOutlet NSButton	 	*duplicateButton;
    IBOutlet NSButton	 	*newButton;
    IBOutlet NSButton	 	*okButton;
    IBOutlet NSTableView	*settingsTable;
}

- (void)createSettingsWithName:(NSString *)name dictionary:(NSDictionary *)dict;
- (NSUserDefaults *)defaultSettings;
- (NSString *)domainNameWithName:(NSString *)name;
- (void)loadDefaultsFromFileWithSuffix:(NSString *)suffix;
- (NSString *)pathToFile:(NSString *)fileName;
- (void)saveCurrentDefaultsToFileWithSuffix:(NSString *)suffix;
- (void)selectSettings;
- (void)synchronize;
- (NSString *)uniqueSettingsName;

- (IBAction)deleteSettings:(id)sender;
- (IBAction)duplicateSettings:(id)sender;
- (IBAction)newSettings:(id)sender;
- (IBAction)ok:(id)sender;

@end
