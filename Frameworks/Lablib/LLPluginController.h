//
//  LLPluginController.h
//  Lablib
//
//  Created by John Maunsell on 12/31/05.
//  Copyright 2005. All rights reserved.
//

#define	kUseLLDataDevices

#ifdef kUseLLDataDevices
#define kLLPluginVersion	4200
#else
#define kLLPluginVersion	4201
#endif

@interface LLPluginController : NSWindowController {
   
	NSUserDefaults			*defaults;
	NSMutableArray			*enabled;
	NSMutableArray			*loadedPlugins;
	NSMutableArray			*validTaskPlugins;

	IBOutlet NSTableView	*pluginTable;
}

- (id)initWithDefaults:(NSUserDefaults *)theDefaults;
- (void)loadPlugins;
- (void)loadPluginsForApplication:(NSString *)appName;
- (NSArray *)loadedPlugins;
- (void)loadOrUnloadPlugins;
- (long)numberOfValidPlugins;
- (void)runDialog;

- (IBAction)dialogDone:(id)sender;

@end
