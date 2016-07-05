//
//  KNAppController.m
//  Knot
//
// This controller is set to be a delegate for the application.
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2005-2012. All rights reserved.
//

#import "Knot.h" 
#import "KNAppController.h"
#import "KNSummaryController.h"
#import <LablibITC18/LLITC18DataDevice.h>
#import <Foundation/NSDebug.h>
#import <ExceptionHandling/NSExceptionHandler.h>

char *idString = "Knot Version 2.2";

// Preferences dialog

NSString *KNActiveTaskNameKey = @"KNActiveTaskName";
NSString *KNDoDataDirectoryKey = @"KNDoDataDirectory";
NSString *KNPreviousTaskNameKey = @"KNPreviousTaskName";
NSString *KNWritingDataFileKey = @"KNWritingDataFile";

@implementation KNAppController

// See notes for information about the following class method

//+ (void)_forceLinkerToKeepClassesInApplication;
//{
//    [LLITC18DataDevice0 class];
//    [LLITC18DataDevice1 class];
//}

//+ (void)initialize;
//{
//	NSString *ITCFrameworkPath, *myBundlePath;
//	NSBundle *ITCFramework;
//    
//	myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
//	if ([[myBundlePath pathExtension] isEqualToString:@"plugin"]) {
//		return;
//	}
//	ITCFrameworkPath = [myBundlePath stringByAppendingPathComponent:@"Contents/Frameworks/LablibITC18.framework"];
//	ITCFramework = [NSBundle bundleWithPath:ITCFrameworkPath];
//	if ([ITCFramework load]) {
//		NSLog(@"LablibITC18 framework loaded");
//	}
//	else
//	{
//		NSLog(@"Error, LablibITC18 framework failed to load\nAborting.");
//		exit(1);
//	}
//}

- (void)activateCurrentTask;
{
	if (currentTask != nil) {
		[[taskMenu itemWithTitle:[currentTask name]] setState:NSOnState];
		NSLog(@"Activating task %@", [currentTask name]);
		[stimWindow setDisplayMode:[currentTask requestedDisplayMode]];
		[currentTask activate];
		[self postDataParamEvents];
		[defaults setObject:[currentTask name] forKey:KNActiveTaskNameKey];
	}
}

// The data are handled within a Cocoa NSDocument, which is created here.
// After it is created, we can load the task plugins

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
{
	dataDoc = [[LLDataDoc alloc] init];
    
    summaryController = [[KNSummaryController alloc] initWithDefaults:defaults];
    [dataDoc addObserver:summaryController];	
    
	[pluginController loadPlugins];
	[self configurePlugins];
	[self activateCurrentTask];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
	long choice;
	BOOL writingDataFile = [defaults boolForKey:KNWritingDataFileKey];
    NSAlert *theAlert;
    NSString *message;
		
// Nothing to worry about before quitting
	
	if (([currentTask mode] == kTaskIdle) && !writingDataFile) {
		[currentTask deactivate:self];
		return NSTerminateNow;
	}

// Task running and/or data file open.  Ask for permission to terminate

    if (!([currentTask mode] == kTaskIdle) && writingDataFile) {
        message = @"Task is running and data file is open.  Stop, close and quit?";
	}
	else if (writingDataFile) {
        message = @"Data file is open.  Close and quit?";
	}
    //	else if (!([currentTask mode] == kTaskIdle)) {
    else {
        message = @"Task is running.  Stop and quit?";
	}
    theAlert = [[NSAlert alloc] init];
    [theAlert setMessageText:@"Knot"];
    [theAlert addButtonWithTitle:@"OK"];
    [theAlert addButtonWithTitle:@"Cancel"];
    [theAlert setInformativeText:message];
	choice = [theAlert runModal];
    [theAlert release];
	if (choice == NSAlertFirstButtonReturn) {
		[currentTask setMode:kTaskEnding];
		return NSTerminateNow;
	}
	else {
		return NSTerminateCancel;
	}
}

// This is the place to put the clean up code for the application. As a delegate for the NSApplication, we are
// automatically registered for this notification.

- (void)applicationWillTerminate:(NSNotification *)aNotification;
{
    while ([currentTask mode] != kTaskIdle) {};				// wait for state system to stop, then release it
    sleep(0.25);
    [self deactivateCurrentTask];
    
    [dataDeviceController setDataEnabled:[NSNumber numberWithBool:NO]];
	[settingsController synchronize];		// Wait until after task deactivates, in case it saves settings

// We've already check it was ok to close open file in -applicationShouldTerminate

	if ([defaults boolForKey:KNWritingDataFileKey]) {	
		[dataDoc closeDataFile];
		[defaults setBool:NO forKey:KNWritingDataFileKey];
	}
    [dataDoc removeObserver:summaryController];

// I had been getting an intermittent crash when the following call was [summaryController close];
    
    [[summaryController window] performClose:self];
    [summaryController release];

// Release the plugins before releasing the objects they might use as they clean up

	[pluginController release];

	[aboutPanel release];
    [stimWindow release];
	
    [dataDeviceController release];
	synthDataDevice = nil;									// nil the pointer to the released data devices
	mouseDataDevice = nil;									// nil the pointer to the released data devices
	[monitorController release];
    [dataDoc release];										// release data document
    [eyeCalibration release];
	[settingsController release];
    [defaults synchronize];									// synchronize defaults with disk
}

// The main nib has been loaded now, so we can initialize with impunity 

- (void)awakeFromNib;
{
	if (initialized) {
		return;
	}
	initialized = YES;

// Creating the settings controller was causing a crash when it was in the -init. JHRM 110623
    
	pluginController = [[LLPluginController alloc] initWithDefaults:defaults];
	settingsController = [[LLSettingsController alloc] init];

// Set up a report controller.  This must be done before things that attach reportables (e.g., stimulus Window)

	monitorController = [[LLMonitorController alloc] init];
	
// Set up the stimulus window.  This needs to be done before setting up the mouseData (below)
 
    stimWindow = [[LLStimWindow alloc] init];

// Set up the eye calibration system and a fixation window

	eyeCalibration = [[LLBinocCalibrator alloc] init]; 
    [eyeCalibration setDefaults:defaults];

// Set up the controller that will handle getting data from input devices, files, etc.
// We create hardware data sources for synthetic data, mouse data, and ITC-18 data (lab I/O).

    dataDeviceController = [[LLDataDeviceController alloc] init];
	[dataDeviceController setDefaults:defaults];
	
// Load any LLDataDevices that are plugins

	[self loadDataDevicePlugins];
}

- (IBAction)changeDataSource:(id)sender;
{	
	[dataDeviceController assignmentDialog];
	[self postDataParamEvents];
}

- (IBAction)changeSettings:(id)sender;
{
    [settingsController selectSettings];
}

// Initialize any plugins that have not been initialized and update the task menu

- (void)configurePlugins;
{
	long index;
    NSString *activeTaskName;
	NSArray *taskPlugIns;
	LLTaskPlugIn *task;
	
// Empty the task menu

	for (index = [taskMenu numberOfItems] - 1; index >= 0; index--) {
		[taskMenu removeItemAtIndex:index];
	}

// Get the list of loaded plugins and initialize any that appear for the first time

	taskPlugIns = [pluginController loadedPlugins];				// Get the list of all loaded plugins
	currentTask = nil;
	if ([taskPlugIns count] == 0) {
		if ([pluginController numberOfValidPlugins] == 0) {
            [LLSystemUtil runAlertPanelWithMessageText:@"Knot: No suitable plugins found." informativeText:
             @"The active \"Library/Application Support/Knot\" folders contain no task plugins. You should install at least one."];
//			NSRunAlertPanel(@"Knot: No suitable plugins found.",
//				@"The active \"Library/Application Support/Knot\" folders contain no task plugins. You should install at least one.", 
//				@"OK", nil, nil);
		}
		else {
            [LLSystemUtil runAlertPanelWithMessageText:@"Knot: No enabled plugins" informativeText:
                        @"You can enable plugins using the Plugin Manager in the File menu."];
//			NSRunAlertPanel(@"Knot: No enabled plugins",
//				@"You can enable plugins using the Plugin Manager in the File menu.", 
//				@"OK", nil, nil);
		}
	}
	else {
		activeTaskName = [defaults stringForKey:KNActiveTaskNameKey];
		for (index = 0; index < [taskPlugIns count]; index++) {
			task = [taskPlugIns objectAtIndex:index];
			if (![task initialized]) {
				[task setHost:self];
				[task setDefaults:defaults];
				[task setDataDeviceController:dataDeviceController];
				[task setSynthDataDevice:synthDataDevice];
				[task setDataDocument:dataDoc];
				[task setEyeCalibrator:eyeCalibration];
				[task setMonitorController:monitorController];
				[task setStimWindow:stimWindow];
				[task initializationDidFinish];
				[task setInitialized:YES];
			}
			[taskMenu addItemWithTitle:[task name] action:@selector(doTaskMenu:)
					keyEquivalent:@""];
			if ([[task name] isEqualToString:activeTaskName]) {
				NSLog(@"%@ is the active task", [task name]);
				currentTask = task;
			}
		}
	}

// If we didn't find the desired plugin, revert to the first

	if (currentTask == nil && [taskPlugIns count] > 0) {
		currentTask = [taskPlugIns objectAtIndex:0];
	}
	[taskMenu addItem:[NSMenuItem separatorItem]];
	[taskMenu addItemWithTitle:@"Previous Task" action:@selector(doPreviousTask:) keyEquivalent:@"0"];
}

// Deactivate the current LLTaskPlugin, closing any windows that it left open

- (void)deactivateCurrentTask;
{
	long index, numWindows;
	NSWindow *window;
	NSArray *windows;
    NSString *className;

	if (currentTask != nil) {
		[[taskMenu itemWithTitle:[currentTask name]] setState:NSOffState];
		[currentTask deactivate:self];
		[defaults setObject:[currentTask name] forKey:KNPreviousTaskNameKey];
		[dataDeviceController removeAllAssignments];
		[dataDoc clearEventDefinitions];
		[stimWindow lock];
		glActiveTextureARB(GL_TEXTURE0_ARB);				// make texture unit 0 active
		[stimWindow unlock];

		windows = [NSApp windows];							// close any left over windows
        numWindows = [windows count];
		for (index = 0; index < numWindows; index++) {
			window = [windows objectAtIndex:index];
			if ([window isVisible]) {
				if ((window != stimWindow) && (window != [summaryController window]) &&
                                (window != [monitorController window]) && (window != [eyeCalibration window])) {
                    
                    // Seems the system sometimes throws up an _NSOrderOutAnimationProxyWindow during transitions,
                    // and these don't like being told to close
                    
                    className = NSStringFromClass([window class]);
                    if (![className isEqualToString:@"_NSOrderOutAnimationProxyWindow"]) {
						[window performClose:self];
                    }
                }
			}
		}
		currentTask = nil;
	}
}

// There is no guarantee that dealloc will actually be called.  Documentation for NSObject notes the following:
// Note that when an application terminates, objects may not be sent a dealloc message since the process’s 
// memory is automatically cleared on exit—it is more efficient simply to allow the operating system to clean 
// up resources than to invoke all the memory management methods., so we only do the releases here.
//
// For this reason, we do all our releases and clean up in applicationWillTerminate.  We do this so that
// any object that is trying to synchronize, etc. at dealloc will get a chance to. 

- (void) dealloc;
{
    NSLog(@"Knot dealloc");
    [defaults release];
	[super dealloc];
    NSLog(@"Knot dealloc is done");
}

- (IBAction)doPluginController:(id)sender;
{
	[self deactivateCurrentTask];							// no tasks active
	[pluginController runDialog];							// modify active tasks
	[self configurePlugins];
	[self activateCurrentTask];
}

- (IBAction)doPreviousTask:(id)sender;
{
	LLTaskPlugIn *thePlugin = nil;
	NSString *taskName;
	NSArray *taskPlugins;
	NSEnumerator *enumerator;
	
	if ([defaults boolForKey:KNWritingDataFileKey] || ([currentTask mode] != kTaskIdle)) {
		return;
	}
	taskName = [defaults objectForKey:KNPreviousTaskNameKey];
	if (taskName == nil || [[currentTask name] isEqualToString:taskName]) {
		return;
	}
	taskPlugins = [pluginController loadedPlugins];
	enumerator = [taskPlugins objectEnumerator];
	while ((thePlugin = [enumerator nextObject]) != nil) {
		if ([[thePlugin name] isEqualToString:taskName]) {
			break;
		}
	}
	if (thePlugin != nil) {
		[self deactivateCurrentTask];
		currentTask = thePlugin;
		[self activateCurrentTask];
	}
}

- (IBAction)doTaskMenu:(id)sender;
{
	long taskIndex = [taskMenu indexOfItem:sender];
	NSArray *taskPlugIns = [pluginController loadedPlugins];
	
	[self deactivateCurrentTask];
	currentTask = [taskPlugIns objectAtIndex:taskIndex];
	[self activateCurrentTask];
}

- (id)init;
{
	NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
	LLTaskStatusTransformer *transformer;
	
	if ((self = [super init]) == nil) {
		return nil;
	}
    [self setDelegate:self];
	[LLSystemUtil preventSleep];							// don't let the computer sleep
	
// Load the defaults for the user defaults.  These are the values that are used the first time
// the program is run.  Subsequent changes to values are preserved and used.  The default values are
// kept in UserDefaults.plist, which is in the application folder.  It is easier to edit this file with the 
// XML Editor rather than the XCode editor (although that is possible for quick changes).

	defaults = [[LLUserDefaults alloc] init];
	userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    [defaults registerDefaults:userDefaultsValuesDict];

// Set up the value transformers that are needed for some of the key bindings used by tasks

	[NSValueTransformer setValueTransformer:
				[[[LLTaskStatusImageTransformer alloc] init] autorelease] 
				forName:@"TaskStatusImageTransformer"];
	[NSValueTransformer setValueTransformer:
				[[[LLTaskStatusTitleTransformer alloc] init] autorelease] 
				forName:@"TaskStatusTitleTransformer"];
	transformer = [[[LLTaskStatusTransformer alloc] init] autorelease];
	[transformer setTransformerType:kLLTaskStatusIdleAndNoFile];
	[NSValueTransformer setValueTransformer:transformer
				forName:@"TaskStatusIdleAndNoFileTransformer"];
	transformer = [[[LLTaskStatusTransformer alloc] init] autorelease];
	[transformer setTransformerType:kLLTaskStatusNoFile];
	[NSValueTransformer setValueTransformer:transformer forName:@"TaskStatusNoFileTransformer"];

	return self;
}

- (void)loadDataDevicePlugins;
{
    NSEnumerator *enumerator;
    NSString *currPath;
    NSBundle *currBundle;
	LLDataDevice *theDevice;
	Class theClass;
    NSMutableArray *bundlePaths = [NSMutableArray array];
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];

    [bundlePaths addObjectsFromArray:[LLSystemUtil allBundlesWithExtension:@"plugin" 
			appSubPath:[NSString stringWithFormat:@"Application Support/%@/Plugins",
			appName]]];
    enumerator = [bundlePaths objectEnumerator];
    while ((currPath = [enumerator nextObject])) {
        if ((currBundle = [NSBundle bundleWithPath:currPath]) != nil) {
            theClass = [currBundle principalClass];
			if ([theClass isSubclassOfClass:[LLDataDevice class]]) {
				if ([theClass version] != kLLPluginVersion) {
                    [LLSystemUtil runAlertPanelWithMessageText:[self className]
                        informativeText:[NSString stringWithFormat:
                        @"%@ has version %ld, but current version is %d.  It will be not be used.",
                        currPath, (long)[theClass version], kLLPluginVersion]];
//					NSRunCriticalAlertPanel(@"Knot: error loading plugin", 
//						@"%@ has version %ld, but current version is %d.  It will be not be used.", 
//						@"OK", nil, nil, currPath, (long)[theClass version], 
//						kLLPluginVersion);
				}
				else {
                    do {
                        theDevice = [[[theClass alloc] init] autorelease];
                        [dataDeviceController addDataDevice:theDevice];
                        NSLog(@"Loaded data device %@", [theDevice name]);
                        if ([theDevice respondsToSelector:@selector(monitor)]) {
                            [monitorController addMonitor:[theDevice performSelector:@selector(monitor)]];
                        }
                    } while ([theDevice shouldCreateAnotherDevice]);

// We need some special handing of particular data devices, if they are present.

					if ([theClass isSubclassOfClass:[LLSynthDataDevice class]]) {
						synthDataDevice = (LLSynthDataDevice *)theDevice;
					}
					else if ([theClass isSubclassOfClass:[LLMouseDataDevice class]]) {
						mouseDataDevice = (LLMouseDataDevice *)theDevice;
						[mouseDataDevice setOrigin:[stimWindow centerPointPixLLOrigin]];
					}
				}
            }
		}
    }
}

- (void)postDataParamEvents;
{
	DataParam dataParam;
	NSArray *assignmentArray;
	NSValue *paramValue;
	NSEnumerator *enumerator;

	if ([dataDoc eventNamed:@"dataParam"]) {
		assignmentArray = [dataDeviceController allDataParam];
		enumerator = [assignmentArray objectEnumerator];
		while ((paramValue = [enumerator nextObject])) {
			[paramValue getValue:&dataParam];
			[dataDoc putEvent:@"dataParam" withData:(Ptr)&dataParam];
		}
	}
}

- (IBAction)recordDontRecord:(id)sender;
{
	const char *pluginName;

// Start recording

	if (![defaults boolForKey:KNWritingDataFileKey]) {
		[dataDoc setUseDefaultDataDirectory:[defaults boolForKey:KNDoDataDirectoryKey]];
		[dataDeviceController setDataEnabled:[NSNumber numberWithBool:NO]];
		if ([dataDoc createDataFile]) {
			[defaults setBool:YES forKey:KNWritingDataFileKey];
			if ([dataDoc eventNamed:@"text"]) {
				[dataDoc putEvent:@"text" withData:idString lengthBytes:strlen(idString)];
				pluginName = [[currentTask name] UTF8String];
				[dataDoc putEvent:@"text" withData:(Ptr)pluginName lengthBytes:strlen(pluginName)];
			}
			if ([dataDoc eventNamed:@"displayCalibration"]) {
				[dataDoc putEvent:@"displayCalibration" withData:[stimWindow displayParameters]];
			}
			[self postDataParamEvents];
			[currentTask setWritingDataFile:YES];
			[recordDontRecordMenuItem setTitle:@"Stop Recording Data"];
			[recordDontRecordMenuItem setKeyEquivalent:@"W"];   // NB: Implies command-shift-w
		}
		[settingsController synchronize];						// save our current settings
	}
	else {														// stop recording
		[defaults setBool:NO forKey:KNWritingDataFileKey];
		[currentTask setWritingDataFile:NO];
		[dataDoc closeDataFile];
		[recordDontRecordMenuItem setTitle:@"Record Data To File"];
		[recordDontRecordMenuItem setKeyEquivalent:@"s"];		// NB: Implies command-s (no shift)
	}
}

// As the NSApp, we get all OS events via sendEvent.  We pass these along to LLTaskPlugins that want
// them.  We also track the state of the mouse, for those objects that need to know that (e.g., LLMouseDataDevice). 

- (void)sendEvent:(NSEvent *)theEvent;
{

// Monitor the state of the mouse button

	if ([theEvent type] == NSLeftMouseDown) {
		[mouseDataDevice setMouseState:kLLLeftMouseDown];
	}
	else if ([theEvent type] == NSLeftMouseUp) {				 // NB: Button clicks absorb mouseUp events
		[mouseDataDevice setMouseState:FALSE];
	}

// Pass the event to the current task, if it handles such events

	if (![currentTask handlesEvents]) {
		[super sendEvent:theEvent];
	}
	else if (![currentTask handleEvent:theEvent]) {
		[super sendEvent:theEvent];
	}
}

- (IBAction)showAboutPanel:(id)sender {

	if (aboutPanel == nil) {
		aboutPanel = [[LLDefaultAboutBox alloc] init];
	}
	[aboutPanel showWindow:self];
}

- (IBAction)showDisplayCalibratorPanel:(id)sender { 

    [stimWindow showDisplayParametersPanel];
}

- (IBAction)showEyeCalibratorPanel:(id)sender {

    [eyeCalibration showWindow:self];
}

- (IBAction)showReportPanel:(id)sender {

    [monitorController showWindow:self];
}

// Disable certain menu items according to task state

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
	SEL action = [menuItem action];
	BOOL writingDataFile = [defaults boolForKey:KNWritingDataFileKey];
	
	if (action == @selector(changeDataSource:)) {		// Data source
		return (!writingDataFile && ([currentTask mode] == kTaskIdle));
	}
	else if (action == @selector(changeSettings:)) {			// change settings
		return (!writingDataFile && ([currentTask mode] == kTaskIdle));
	}
	else if (action == @selector(recordDontRecord:)) {		// Create or close data file
		return ([currentTask mode] == kTaskIdle);
	}
	else if (action == @selector(doPreviousTask:)) {				// change task
		return (!writingDataFile && currentTask != nil && ([currentTask mode] == kTaskIdle));
	}
	else if (action == @selector(doTaskMenu:)) {				// change task
		return (!writingDataFile && ([currentTask mode] == kTaskIdle));
	}
	else if (action == @selector(doPluginController:)) {		// enable/disable plugins
		return (!writingDataFile && ([currentTask mode] == kTaskIdle));
	}
	return YES;
}

@end
