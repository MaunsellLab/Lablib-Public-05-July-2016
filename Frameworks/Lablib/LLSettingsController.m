//
//  LLSettingsController.m
//  Lablib
//
//  Created by John Maunsell on Sat Jun 14 2003.
//  Copyright (c) 2003. All rights reserved.
//

/* 

Different sets of settings are stored as NSDictionaries, which are bundled in an NSArray
that is stored in NSUserDefaults.  Old settings are stored by taking the NSUserDefaults
(which is an NSDictionary), stripping out the NSArray that contains all the settings
dictionaries, and then putting the dictionary into the array of settings.  New settings
are similarly extracted, have the array of settings inserted into them, then made a
replacement for NSUserDefaults.  Thus, the user is always using NSUserDefaults, and
we replace its contents. 

Support is provided for a dialog that allows the creation, deletion, selection and
renaming of different settings.  Because settings affect all operations, this dialog
is task-modal, and should only be accessed when the task is not running.  SImilarly,
any dialog containing entries from the NSUserDefaults should be closed before calling
this dialog, because their contents will be stale after any changes.  Because these
routines can change the contents of NSUserDefaults, anything that displays values from
NSUserDefaults (e.g., dialogs) should be loaded fresh each time they appear

*/

#import "LLSettingsController.h"
#import "LLSystemUtil.h"

NSString *LLSettingsChanged = @"LLSettings Changed";

NSString *kDefaultSettingsName = @"Settings 0";
NSString *LLSettingsArrayKey = @"LL Settings Array";
NSString *LLSettingsIndexKey = @"LL Settings Index";
NSString *LLSettingsNameKey = @"LLSettingsName";

@implementation LLSettingsController

- (void)createSettingsWithName:(NSString *)name dictionary:(NSDictionary *)dict {

	long index;

// Install the new name and update the settings table

	[settingsNameArray addObject:name];
	index = [settingsNameArray indexOfObject:name];
	[settingsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[settingsTable scrollRowToVisible:index];
	
// Create the new persistent domain, making sure it has the correct name entered

	[[NSUserDefaults standardUserDefaults] setPersistentDomain:dict 
				forName:[self domainNameWithName:name]];
}

- (void)dealloc {

	[settingsNameArray release];
	[super dealloc];
}

- (NSUserDefaults *)defaultSettings;
{
	return [NSUserDefaults standardUserDefaults];
}

- (IBAction)deleteSettings:(id)sender;
{
    NSAlert *theAlert = [[NSAlert alloc] init];
    
    [theAlert setMessageText:[self className]];
	if ([settingsNameArray count] == 1) {
        [theAlert setInformativeText:@"There must always be least one configuration"];
        [theAlert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK) {
            }
        }];
//        NSBeginAlertSheet(@"LLSettingsController",
//			@"OK", nil, nil, [self window], self, nil,
//			@selector(deleteSheetDidEnd:returnCode:contextInfo:), nil,
//			@"There must always be least one configuration"); 
	}
	else {
        [theAlert setInformativeText:@"Really delete configuration? This operation cannot be undone."];
        [theAlert addButtonWithTitle:@"Delete"];
        [theAlert addButtonWithTitle:@"Cancel"];
        [theAlert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            long row;
            switch (result) {
                case NSAlertFirstButtonReturn:					// DELETE the settings
                    row = [settingsTable selectedRow];			// row to delete
                    [[NSFileManager defaultManager] removeItemAtPath:
                            [self pathToFile:[settingsNameArray objectAtIndex:row]] error:NULL];
                    [settingsNameArray removeObjectAtIndex:row];//  and their name
                    [settingsTable reloadData];					// update table display
                    break;
                case NSAlertSecondButtonReturn:                 // CANCEL the deletion
                default:
                    break;
            }
        }];
//        NSBeginAlertSheet(@"LLSettingsController",
//            @"Delete", @"Cancel", nil, [self window], self, nil,
//			@selector(deleteSheetDidEnd:returnCode:contextInfo:), nil,
//                          @"Really delete configuration? This operation cannot be undone.");
	}
    [theAlert release];
}

//- (void)deleteSheetDidEnd:(id)sheet returnCode:(long)code contextInfo:(id)contextInfo;
//{
//	long row;
//	
//	if ([settingsNameArray count] > 1) {				// never delete when there is only one
//		switch (code) {
//		case NSAlertDefaultReturn:						// OK to delete the settings
//			row = [settingsTable selectedRow];			// row to delete
//			[[NSFileManager defaultManager] removeItemAtPath:[self pathToFile:[settingsNameArray objectAtIndex:row]]
//							error:NULL];
//			[settingsNameArray removeObjectAtIndex:row];//  and their name
//			[settingsTable reloadData];					// update table display
//			break;
//		case NSAlertAlternateReturn:
//		default:
//			break;
//		}
//	}
//}

- (NSString *)domainNameWithName:(NSString *)name;
{
	return [NSString stringWithFormat:@"%@-%@", [[NSBundle mainBundle] bundleIdentifier], name];
}

// Respond to the duplicate button.  In this case, we make a new file with the contents of the current
// settings, and we save the current settings with their current name.

- (IBAction)duplicateSettings:(id)sender;
{
	long index;
	NSString *newName;

	index = [settingsTable selectedRow];				// get the settings to duplicate
	newName = [NSString stringWithFormat:@"%@ copy", [settingsNameArray objectAtIndex:index]];
	while ([settingsNameArray containsObject:newName]) {
		newName = [NSString stringWithFormat:@"%@a", newName];
	}
	
// We're going to automatically activate the newly created duplicate, so we need to save the current
// settings to a file.  We have to write to the newly created file, because selectSettings will notice
// the selection has changed and will load it.

//	[self saveCurrentDefaultsToFileWithSuffix:[settingsNameArray objectAtIndex:index]];
	[[NSUserDefaults standardUserDefaults] setObject:newName forKey:LLSettingsNameKey];
	[self saveCurrentDefaultsToFileWithSuffix:newName];

// Update the table to show the new name and select it

	[settingsNameArray addObject:newName];				// add the new name to the name array
	index = [settingsNameArray indexOfObject:newName];
	[settingsTable reloadData];							// Make sure number of rows is up to date
	[settingsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[settingsTable scrollRowToVisible:index];
}

- (id)init;
{
	NSString *settingsName;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    if ((self =  [super initWithWindowNibName:@"LLSettingsController"]) != nil) {
        [self setWindowFrameAutosaveName:@"LLSettingsController"];
		[self window];

// We should be able to set the initialFirstResponder in IB, but that does not seem
// to work.  We need the table to come up as the first responder so that it will 
// respond to keys (e.g., arrows).

		[[self window] makeFirstResponder:settingsTable];
		settingsNameArray = [[NSMutableArray alloc] init];

// If we don't have a named default configuration, name the current (only) one.  If we do have a named default, 
// we don't need to worry about loading it, because it was left in the default configuration, which is the one
// we have reloaded by default.  We also create the file, so it's there to be found when the list is made for
// the table, and there's a file available to rename if the user does that

		settingsName = [defaults objectForKey:LLSettingsNameKey];
		if (settingsName == nil) {
			[defaults setObject:kDefaultSettingsName forKey:LLSettingsNameKey];
			[self saveCurrentDefaultsToFileWithSuffix:kDefaultSettingsName];
		}
		else if (![[NSFileManager defaultManager] isReadableFileAtPath:[self pathToFile:settingsName]]) {
			[self saveCurrentDefaultsToFileWithSuffix:settingsName];
		}
	} 
	return self;
}

// Load defaults from an NSDictionary in a file in ~/Library/Preferences using the bundle ID name
// and a suffix.

- (void)loadDefaultsFromFileWithSuffix:(NSString *)suffix;
{
	NSDictionary *dict;
	NSEnumerator *keyEnumerator;
	NSString *key;
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	dict = [NSDictionary dictionaryWithContentsOfFile:[self pathToFile:suffix]];
	[defaults removePersistentDomainForName:bundleID];
	[defaults setPersistentDomain:dict forName:bundleID];
	[defaults synchronize];

// Setting the domain is not good enough when we are using key-value binding.  We need to set each value
// explicitly so they are registered

	keyEnumerator = [dict keyEnumerator];
	while ((key = [keyEnumerator nextObject])) {
		[defaults setObject:[dict objectForKey:key] forKey:key];
	}
}
	
// Create new, empty settings (which will assume the registered default values).

- (IBAction)newSettings:(id)sender;
{
	long index;
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *newName = [self uniqueSettingsName];
	
	[settingsNameArray addObject:newName];				// add the new name to the list of settings names
	[defaults removePersistentDomainForName:bundleID];	// clear out any current settings
	[defaults setObject:newName forKey:LLSettingsNameKey];
	[self saveCurrentDefaultsToFileWithSuffix:newName];

	index = [settingsNameArray indexOfObject:newName];  // update the settings table in the dialog
	[settingsTable reloadData];							// make sure number of rows is up to date
	[settingsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[settingsTable scrollRowToVisible:index];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {

    return [settingsNameArray count];
}

- (IBAction)ok:(id)sender;
{
	[NSApp stopModal];
}

- (NSString *)pathToFile:(NSString *)fileName;
{
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

	return [NSString stringWithFormat:@"%@/Library/Preferences/%@.%@.plist", NSHomeDirectory(), bundleID, fileName];
}

// Save the current defaults as an NSDictionary in a file in ~/Library/Preferences using the bundle ID name
// and a suffix.

- (void)saveCurrentDefaultsToFileWithSuffix:(NSString *)suffix;
{
	NSDictionary *dict;
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults synchronize];
	dict = [NSDictionary dictionaryWithDictionary:[defaults persistentDomainForName:bundleID]];
	[dict writeToFile:[NSString stringWithFormat:@"%@/Library/Preferences/%@.%@.plist", NSHomeDirectory(), 
					bundleID, suffix] atomically:YES];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
{
	if (disallowNextSelectionChange) {
		disallowNextSelectionChange = NO;
		return NO;
	}
	return YES;
}

// Present the dialog and let the user change settings.  Unused settings are kept in plist files named by 
// appending a name to the default plist file.

- (void)selectSettings;
{
	long settingsIndex;
	NSString *pname;
	NSArray *pathComponents;
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDirectoryEnumerator *direnum;

	[defaults synchronize];						// make sure persistent domain is up to date

// Load the array of names with all candidate files, plus the name of the settings currently loaded (in case
// they are not yet in a file.

	[settingsNameArray removeAllObjects];
	direnum = [[NSFileManager defaultManager] enumeratorAtPath:
					[NSString stringWithFormat:@"%@/Library/Preferences", NSHomeDirectory()]];
	while ((pname = [direnum nextObject])) {
		if ([pname hasPrefix:bundleID]) {
			pathComponents = [pname componentsSeparatedByString:@"."];
			if ([pathComponents count] == 4) {
				[settingsNameArray addObject:[pathComponents objectAtIndex:2]];
			}
		}
		[direnum skipDescendents];				// we don't want to go into any directories
	}
	
// Add the name of the current settings if they are not in there

	[settingsNameArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
	pname = [defaults objectForKey:LLSettingsNameKey];

// Configure the table for display

	settingsIndex = [settingsNameArray indexOfObject:pname];
	[settingsTable reloadData];							// make sure number of rows is up to date
	[settingsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:settingsIndex] byExtendingSelection:NO];
	[settingsTable scrollRowToVisible:settingsIndex];

// We are now ready to run the dialog. Save settings before, and reload setting afterward.  We do this because
// settings may get overwritten if some settings are renamed, even if the index doesn't change

	[self saveCurrentDefaultsToFileWithSuffix:pname];
	[NSApp runModalForWindow:[self window]];
	[self loadDefaultsFromFileWithSuffix:[settingsNameArray objectAtIndex:[settingsTable selectedRow]]];

// If the index has changed, notify observers that the defaults are different

	if (settingsIndex != [settingsTable selectedRow]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:LLSettingsChanged object:nil];
	}
    [[self window] orderOut:self];
}

- (BOOL) shouldCascadeWindows {

    return NO;
}

// Write the current settings into the appropriate domain so it is up to date

- (void)synchronize {

	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
												row:(int)row {
	
	return [settingsNameArray objectAtIndex:row];
}

// tableView is called when the user tries to rename one of the settings

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)column
						row:(int)rowIndex;
{
	NSString *newName = object;
	NSString *oldName = [settingsNameArray objectAtIndex:rowIndex];
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	
	if ([oldName isEqual:newName]) {		// no change, do nothing
		return;
	}
	if ([newName length] == 0) {												// blank name, not allowed
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                    informativeText:@"Please use a name that is not blank."];
//		NSRunAlertPanel(@"LLSettingsController", @"Please use a name that is not blank.",
//					@"OK", nil, nil, nil);
		disallowNextSelectionChange = YES;
		return;
	}
	if ([settingsNameArray containsObject:newName]) {						// Name already taken
        [LLSystemUtil runAlertPanelWithMessageText:[self className]
                informativeText:[NSString stringWithFormat:@"The name \"%@\" is already in use, please select another.",
                newName]];
//		NSRunAlertPanel(@"LLSettingsController", @"The name \"%@\" is already in use, please select another.",
//					@"OK", nil, nil, newName);
		disallowNextSelectionChange = YES;
		return;
	}
	[settingsNameArray replaceObjectAtIndex:rowIndex withObject:object];
	[self loadDefaultsFromFileWithSuffix:oldName];
	[[NSUserDefaults standardUserDefaults] setObject:newName forKey:LLSettingsNameKey];
	[self saveCurrentDefaultsToFileWithSuffix:newName];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Preferences/%@.%@.plist", 
                                                      NSHomeDirectory(), bundleID, oldName] error:NULL];
}

- (NSString *)uniqueSettingsName;
{
	long count;
	NSString *newName;
	
	count = [settingsNameArray count];
	do {
		newName = [NSString stringWithFormat:@"Settings %ld", count++];
	} while ([settingsNameArray containsObject:newName]);
	return newName;
}

@end
