//
//  LLPluginController.m
//  Lablib
//
//  Created by John Maunsell on 12/31/05.
//  Copyright 2005. All rights reserved.
//

#import "LLPluginController.h"
#import "LLTaskPlugin.h"
#import "LLSystemUtil.h"

typedef struct {
	Class	class;
	LLTaskPlugIn *plugin;
} PluginDesc;

NSInteger sortPluginsByName(id task1, id task2, void *context);

NSString *pluginDisableKey = @"LLPluginDisable";

@implementation LLPluginController

- (void)dealloc;
{
	[defaults release];
	[loadedPlugins release];
	[validTaskPlugins release];
	[enabled release];
	[super dealloc];
}

- (IBAction)dialogDone:(id)sender;
{
	[NSApp stopModal];
}

- (id)initWithDefaults:(NSUserDefaults *)theDefaults;
{
    if ((self =  [super initWithWindowNibName:@"LLPluginController"]) != nil) {
		defaults = theDefaults;
		[defaults retain];
		validTaskPlugins = [[NSMutableArray alloc] init];
		loadedPlugins = [[NSMutableArray alloc] init];
		enabled = [[NSMutableArray alloc] init];
	}
	return self;
}
	
// Read all plugins from the Application Support folder

- (void)loadPlugins;
{
	[self loadPluginsForApplication:[[[NSBundle mainBundle] infoDictionary] 
				objectForKey:@"CFBundleExecutable"]];
}

- (void)loadPluginsForApplication:(NSString *)appName;
{
//	int value;
	BOOL success;
    NSMutableArray *bundlePaths;
    NSEnumerator *enumerator;
    NSString *currPath;
    NSBundle *currBundle;
	PluginDesc pluginDesc;
	NSMutableArray *tArray;
    NSAlert *theAlert;
    NSModalResponse theResponse;

    bundlePaths = [NSMutableArray array];
	tArray = [NSMutableArray array];			// LLTaskPlugins
    [bundlePaths addObjectsFromArray:[LLSystemUtil allBundlesWithExtension:@"plugin" 
			appSubPath:[NSString stringWithFormat:@"Application Support/%@/Plugins",
			appName]]];
    enumerator = [bundlePaths objectEnumerator];
    while ((currPath = [enumerator nextObject])) {
        if ((currBundle = [NSBundle bundleWithPath:currPath]) != nil) {
            pluginDesc.class = [currBundle principalClass];

// If this is an LLTaskPlugin, we don't load it now.  Loading depends on whether it is enabled.
// For now we just make a list of all LLTaskPlugins available.

			if ([pluginDesc.class isSubclassOfClass:[LLTaskPlugIn class]]) {
				if ([pluginDesc.class version] != kLLPluginVersion) {
                    theAlert = [[NSAlert alloc] init];
                    [theAlert setMessageText:@"LLPluginController: error loading plugin"];
                    [theAlert setInformativeText:[NSString stringWithFormat:
                                @"%@ has version %ld, but current version is %d.  It will be not be used.",
                                currPath, (long)[pluginDesc.class version], kLLPluginVersion]];
                    [theAlert setAlertStyle:NSCriticalAlertStyle];
                    [theAlert addButtonWithTitle:@"OK"];
                    [theAlert addButtonWithTitle:@"Delete"];
                    theResponse = [theAlert runModal];
                    [theAlert release];
//					value = NSRunCriticalAlertPanel(@"LLPluginController: error loading plugin",
//						@"%@ has version %ld, but current version is %d.  It will be not be used.", 
//						@"OK", @"Delete", nil, currPath, (long)[pluginDesc.class version], 
//						kLLPluginVersion);
                    if (theResponse == NSAlertSecondButtonReturn) {     // user wants to delete it
                        theAlert = [[NSAlert alloc] init];
                       [theAlert setMessageText:@"LLPluginController"];
                        [theAlert setInformativeText:[NSString stringWithFormat:
                                                      @"Delete %@.  Are you sure?", currPath]];
                        [theAlert setAlertStyle:NSWarningAlertStyle];
                        [theAlert addButtonWithTitle:@"Delete"];
                        [theAlert addButtonWithTitle:@"Cancel"];
                        theResponse = [theAlert runModal];
                        [theAlert release];
//						value = NSRunAlertPanel(@"LLPluginController", @"Delete %@.  Are you sure?", @"Delete",
//													@"Cancel", nil, currPath);
                        if (theResponse == NSAlertFirstButtonReturn) {   // user confirmed delete
							NSLog(@"Deleting");
							success = [[NSFileManager defaultManager] removeItemAtPath:currPath error:NULL];
							if (!success) {
                                [LLSystemUtil runAlertPanelWithMessageText:[self className]
                                        informativeText:[NSString stringWithFormat:@"Failed to delete %@.", currPath]];
//								NSRunAlertPanel(@"LLPluginController", @"Failed to delete %@.", @"OK", @"nil",
//                                                nil, currPath);
							}
						}
					}
				}
				else {
					pluginDesc.plugin = nil;
					[tArray addObject:[NSValue valueWithBytes:&pluginDesc 
											objCType:@encode(PluginDesc)]];
				}
            }
		}
    }
	[validTaskPlugins release];
	validTaskPlugins = [[NSMutableArray alloc] initWithArray:
				[tArray sortedArrayUsingFunction:sortPluginsByName context:nil]];
	[self loadOrUnloadPlugins];
}

- (NSArray *)loadedPlugins;
{
	return loadedPlugins;
}

// The NSArray loadedPlugins is the only thing retaining our plugins.  We want to
// discard it and rebuild it because this rebuilding is an easy way to keep the
// array of loaded plugins in alphabetical order.  But we can't throw it out before
// we re-retain only those plugins we want.  To do this, we load a temporary NSArray.

- (void)loadOrUnloadPlugins;
{
	long index;
	BOOL disabled;
	NSString *name;
	PluginDesc pluginDesc;
	NSValue *theValue;
	NSMutableArray *temp;
	
	temp = [NSMutableArray array];
	for (index = 0; index < [validTaskPlugins count]; index++) {
		theValue = [validTaskPlugins objectAtIndex:index];
		[theValue getValue:&pluginDesc];
		name = [pluginDesc.class className];
		disabled = [defaults boolForKey:[NSString stringWithFormat:@"%@%@", pluginDisableKey, name]];
		if (!disabled) {
			if (pluginDesc.plugin == nil) {					// need to load
				pluginDesc.plugin = [[[pluginDesc.class alloc] init] autorelease];
				[validTaskPlugins replaceObjectAtIndex:index
						withObject:[NSValue valueWithBytes:&pluginDesc 
						objCType:@encode(PluginDesc)]];
			}
			[temp addObject:pluginDesc.plugin];				// record as loaded
		}
		else if (disabled && pluginDesc.plugin != nil) {	// need to unload
			pluginDesc.plugin = nil;	// don't need to release because only loadedPlugins retains
			[validTaskPlugins replaceObjectAtIndex:index
						withObject:[NSValue valueWithBytes:&pluginDesc 
						objCType:@encode(PluginDesc)]];
		}
	}
	[loadedPlugins removeAllObjects];
	[loadedPlugins addObjectsFromArray:temp];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
	return [validTaskPlugins count];
}

- (void)runDialog;
{
	long index;
	NSNumber *theNumber;
	NSValue *theValue;
	PluginDesc pluginDesc;
	NSEnumerator *enumerator = [validTaskPlugins objectEnumerator];

// Create an array "enabled" the marks whether each plugin is enabled.  This
// array is updated by the user.  Only when the dialog is done do we check 
// the contents of this array to load or unload plugins
	
	[enabled removeAllObjects];
	while ((theValue = [enumerator nextObject])) {
		[theValue getValue:&pluginDesc];
		[enabled addObject:[NSNumber numberWithBool:(pluginDesc.plugin != nil)]];
	}
	
	[pluginTable reloadData];
	[NSApp runModalForWindow:[self window]];
	[[self window] orderOut:self];

// When the dialog is done we update the entries in deafults.  These will then
// be used by loadOrUnloadPlugin to update which plugins are loaded

	for (index = 0; index < [validTaskPlugins count]; index++) {
		theValue = [validTaskPlugins objectAtIndex:index];
		[theValue getValue:&pluginDesc];
		theNumber = [enabled objectAtIndex:index];
		[defaults setBool:![theNumber boolValue] 
					forKey:[NSString stringWithFormat:@"%@%@",
					pluginDisableKey, [pluginDesc.class className]]];
	}
	[self loadOrUnloadPlugins];
}

- (long)numberOfValidPlugins;
{
	return [validTaskPlugins count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
	NSValue *theValue;
	PluginDesc pluginDesc;
	
	NSParameterAssert(row >= 0 && row < [validTaskPlugins count]);
	theValue = [validTaskPlugins objectAtIndex:row];
	[theValue getValue:&pluginDesc];
	if ([[tableColumn identifier] isEqual:@"name"]) {
		return ([pluginDesc.class className]);
	}
	else if ([[tableColumn identifier] isEqual:@"enable"]) {
		return [enabled objectAtIndex:row];
	}
	return @"";
}

// This method is called when the user has put a new entry in the table.  We need to 
// validate all changes and update the LLDataAssignment and associated NSData objects.

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
					forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
{
	NSParameterAssert(rowIndex >= 0 && rowIndex < [validTaskPlugins count]);
	if ([[aTableColumn identifier] isEqual:@"enable"]) {
		[enabled replaceObjectAtIndex:rowIndex withObject:anObject];
	}
}

// 
// Functions
//

NSInteger sortPluginsByName(id desc1, id desc2, void *context)
{
    PluginDesc p1, p2;
	
	[desc1 getValue:&p1];
	[desc2 getValue:&p2];
	return [[p1.plugin className] compare:[p2.plugin className] options:NSCaseInsensitiveSearch];
    //	return [[p1.class className] compare:[p2.class className] options:NSCaseInsensitiveSearch];
}

@end
