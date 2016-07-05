/*
StimWindow.m
Stimulus generation
March 29, 2003 JHRM
*/

#import "Knot.h"
#import "StimWindow.h"
#import "UtilityFunctions.h"

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define	stimWindowSizePix		250		// Height and width of stim window on main display

#define kTargetBlue				0.0
#define kTargetGreen			1.0
#define kMidGray				0.5
#define kPI						(atan(1) * 4)
#define k2PI					(atan(1) * 8)
#define kRadiansPerDeg			(atan(1) / 45.0)
#define kTargetRed				1.0
#define kDegPerRad				57.295779513

#define kAdjusted(color, contrast)  (kMidGray + (color - kMidGray) / 100.0 * contrast)

@implementation StimWindow

- (NSPoint)centerPointPix {

	NSRect r;
	
	r = [displays displayBounds:displayIndex];
	return NSMakePoint(r.origin.x + r.size.width / 2, r.origin.y + r.size.height / 2);
}

- (void) dealloc  {

	[fixTargets release];
	[fixSpot release];
	[targetSpot0 release];
	[targetSpot1 release];
    [gabor release];
    [monitor release];
	if (fullscreen) {
		[stimOpenGLContext release];
	}
    [displays release];
	[openGLLock release];
    [super dealloc];
}

// Turn on the fixation targets.  This is the only OpenGL drawing we do other than running the stimulus
// sequence.  We must make sure that we don't ever clobber the stimulus sequence. 

- (void)displayFixTargets {

	if (stimulusOn) {
		return;
	}
	[openGLLock lock];
	[stimOpenGLContext makeCurrentContext];
	if ([self contentView]) {
		[[self contentView] lockFocus];
	}
	[self setScaling];
    glClear(GL_COLOR_BUFFER_BIT);
	[fixTargets makeObjectsPerformSelector:@selector(draw)];
	[[NSOpenGLContext currentContext] flushBuffer];
	if ([self contentView]) {
		[[self contentView] unlockFocus];
	}
	[openGLLock unlock];
}

- (DisplayParam *)displayParameters {

	return &display;
}

- (void) doStimulusPresentation {

    NSAutoreleasePool *threadPool;
    long frame, stimFrames;

    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	[monitor reset]; 
	
	[gabor description];
	
	[openGLLock lock];
    [stimOpenGLContext makeCurrentContext];
    if ([self contentView]) {
        [[self contentView] lockFocus];
    }
	
// Set up the calibration, including the offset then present the stimulus sequence

	[self setScaling];										// update the scaling
	[gabor setContrast:contrast / 100.0];					// set new contrast
    [gabor setSPhaseDeg:[[NSUserDefaults standardUserDefaults] floatForKey:sPhaseDegKey]];
	[gabor makeDisplayLists];								// use OpenGL display lists to speed things up

	stimFrames = durationMS / 1000.0 * ((display.frameRateHz > 0) ? display.frameRateHz : 60.0);

	[gabor store];
    for (frame = 0; frame < stimFrames; frame++) {
		[gabor setFrame:[NSNumber numberWithLong:frame]];	// advance for temporal modulation
        [gabor draw];
		[fixTargets makeObjectsPerformSelector:@selector(draw)];
        [[NSOpenGLContext currentContext] flushBuffer];
        glFinish();
        [monitor recordEvent];
		if (frame == 0) {
			[dataDoc putEvent:@"stimulusOn" withData:&frame];
		}
    }
	[gabor restore];

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
	[fixTargets makeObjectsPerformSelector:@selector(draw)];
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
	[dataDoc putEvent:@"stimulusOff" withData:&frame];
    if ([self contentView]) {
        [[self contentView] unlockFocus];
    }
	[openGLLock unlock];

// The temporal counterphase might have changed some settings.  We restore these here.

	stimulusOn = NO;
    [threadPool release];
}

- (void)erase {

	[openGLLock lock];
	[stimOpenGLContext makeCurrentContext];
	if ([self contentView]) {
		[[self contentView] lockFocus];
	}
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	if ([self contentView]) {
		[[self contentView] unlockFocus];
	}
	[openGLLock unlock];
}

- (id)init {
	
	NSRect dRect;
    NSRect stimRect;
    long swapParam = 1;
    NSOpenGLPixelFormat *fmt;
	NSArray *gaborKeys;
	NSEnumerator *enumerator;
//	NSString *key;

 //   NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults]; 
    NSOpenGLPixelFormatAttribute windowedAttrib[] = {
        NSOpenGLPFANoRecovery, NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute) 24,
        NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute) 8,
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute) 0,
        NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute) 0,
        NSOpenGLPFAAccumSize, (NSOpenGLPixelFormatAttribute) 0,
        NSOpenGLPFAWindow, (NSOpenGLPixelFormatAttribute) 0
    };
	
	openGLLock = [[NSLock alloc] init];
	displays = [[LLDisplays alloc] init];
	displayIndex = [displays numDisplays] - 1;   // use main if only one display, otherwise use second display
	if (displayIndex < 0) {						// no display
		return Nil;
	}
	fullscreen = (displayIndex > 0);
	dRect = [displays displayBounds:displayIndex];
	[openGLLock lock];
	switch (displayIndex) {
	case 0:										// only one display, create stimulus window on it
		display.widthPix = display.heightPix = stimWindowSizePix;
		stimRect = NSMakeRect(dRect.origin.x + dRect.size.width - stimWindowSizePix - 10,
			dRect.origin.y + dRect.size.height - stimWindowSizePix - 55, stimWindowSizePix,
			stimWindowSizePix);
		self = [super initWithContentRect:stimRect 
					styleMask: NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
					backing:NSBackingStoreBuffered defer:NO];
		[self setTitle:@"Stimulus"];
		fmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes: windowedAttrib] autorelease];
		if (!fmt) {
			NSLog(@"Cannot create NSOpenGLPixelFormat");
			[openGLLock unlock];
			return Nil;
		}
		[self setContentView:[[[NSOpenGLView alloc] 
					initWithFrame:NSMakeRect(0, 0, stimRect.size.width, stimRect.size.height) 
					pixelFormat:fmt] autorelease]];
		stimOpenGLContext = [[self contentView] openGLContext];
		[stimOpenGLContext makeCurrentContext];
		[stimOpenGLContext setValues:&swapParam forParameter:NSOpenGLCPSwapInterval];
		[self setDelegate:self];				// set up to receive delegate messages
		[self makeKeyAndOrderFront:Nil];
		break;
	case 1:										// More than one screen, use the second one
	default:
		[displays captureDisplay:displayIndex];
		if ([displays setDisplayMode:displayIndex size:CGSizeMake(dRect.size.width, dRect.size.height) 
				   bitDepth:kPixelDepthBits frameRate:60]) {
			[displays dumpCurrentDisplayMode:displayIndex];
		}
		self = [super initWithContentRect:NSMakeRect(0, 0, display.widthPix, display.heightPix) 
			styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

	// Only now that we have a displays and displaysIndex, we can initialize the attributes

		NSOpenGLPixelFormatAttribute fullscreenAttrib[] = {
			NSOpenGLPFANoRecovery, NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute) 24,
			NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute) 8,
			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute) 0,
			NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute) 0,
			NSOpenGLPFAAccumSize, (NSOpenGLPixelFormatAttribute) 0,
			NSOpenGLPFAFullScreen,						// display to full screen
			NSOpenGLPFAScreenMask, (NSOpenGLPixelFormatAttribute)[displays openGLDisplayID:displayIndex],
			(NSOpenGLPixelFormatAttribute) 0				// nil terminator
		};
	 
		fmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:fullscreenAttrib] autorelease];
		if (fmt == Nil) {
			NSLog(@"Cannot create NSOpenGLPixelFormat");
			[self autorelease];
			return Nil;
		}
		stimOpenGLContext = [[NSOpenGLContext alloc] initWithFormat:fmt shareContext:Nil];
		if (stimOpenGLContext == Nil) {
			NSLog(@"Cannot create OpenGL context");
			[self autorelease];
			return Nil;
		}
		[stimOpenGLContext setFullScreen];
		[stimOpenGLContext makeCurrentContext];
		[stimOpenGLContext setValues:&swapParam forParameter:NSOpenGLCPSwapInterval];
		break;
	}
	display = [displays displayParameters:displayIndex];
	monitor = [[LLIntervalMonitor alloc] initWithID:@"Stimulus" 
					description:@"Stimulus frame intervals"];
	[monitorController addMonitor:monitor];
	[monitor setTargetIntervalMS:1000.0 / display.frameRateHz];

// Clear the screen;

    [stimOpenGLContext makeCurrentContext];
    if ([self contentView]) {
        [[self contentView] lockFocus];
    }
    glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
    if ([self contentView]) {
        [[self contentView] unlockFocus];
    }
	[openGLLock unlock];

// Create and initialize a gabor stimulus

	gaborKeys = [NSArray arrayWithObjects:azimuthDegKey, elevationDegKey, KDLphiKey, KDLthetaKey, 
						orientationDegKey, radiusDegKey, sigmaDegKey, SFKey, sPhaseDegKey,
						TFKey, nil];
						
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:displays displayIndex:displayIndex];
	enumerator = [gaborKeys objectEnumerator];
//	while ((key = [enumerator nextObject]) != nil) {
//		[gabor setValue:[[NSUserDefaults standardUserDefaults] valueForKey:key] forKey:key]; 
//	}
		
	fixSpot = [[LLFixTarget alloc] init];
	targetSpot0 = [[LLFixTarget alloc] init];
	[targetSpot0 setAzimuthDeg:-2.0];				// move off center of screen;
	targetSpot1 = [[LLFixTarget alloc] init];
	[targetSpot1 setAzimuthDeg:2.0];				// move off center of screen;
	fixTargets = [[NSArray alloc] initWithObjects:fixSpot, targetSpot0, targetSpot1, nil];

// Register for notifications about changes to the gabor settings

//	enumerator = [gaborKeys objectEnumerator];
//	while ((key = [enumerator nextObject]) != nil) {
//		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
//			forKeyPath:[NSString stringWithFormat:@"values%@", key]
//			options:NSKeyValueObservingOptionNew context:nil];
//	}
	
	return self;
}

- (LLIntervalMonitor *)monitor {

	return monitor;
}

// Respond to changes in the gabor parameters

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	NSString *key;
	float floatValue;

	key = [keyPath pathExtension];
	floatValue = [[NSUserDefaults standardUserDefaults] floatForKey:key];				// all gabor values are floats
	if (floatValue != [[gabor valueForKey:key] floatValue]) {
		[gabor setValue:[[NSUserDefaults standardUserDefaults] valueForKey:key] forKey:key]; 
		[dataDoc putEvent:@"gabor" withData:(char *)[gabor gaborData]];
		requestReset();
	}
}

- (void)runContrast:(double)stimContrast duration:(long)stimDurationMS {

	contrast = stimContrast;
	durationMS = stimDurationMS;

	if (stimulusOn) {
		return;
	}
	stimulusOn = YES;
   [NSThread detachNewThreadSelector:@selector(doStimulusPresentation) toTarget:self
				withObject:Nil];
}

- (void)setFixSpot:(BOOL)state {

	[fixSpot setState:state];
	if (state) {
		[fixSpot setOuterRadiusDeg:[[NSUserDefaults standardUserDefaults] floatForKey:fixSpotSizeKey]];
		[self displayFixTargets];
	}
}

// Set the OpenGL scaling.  Assumes that the currentContext has been correctly set up.

- (void)setScaling {

	NSSize displayDeg;
	NSPoint offsetDeg;
	
// Set up the calibration, including the offset
// We do not need to lock, because this is called from within functions that lock.

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	displayDeg = [displays displaySizeDeg:displayIndex];	// get current display size
	offsetDeg = [eyeCalibration offsetDeg];					// get current calibration offset
    glOrtho(-displayDeg.width / 2.0 - offsetDeg.x, displayDeg.width / 2.0 - offsetDeg.x, 
			-displayDeg.height / 2.0 - offsetDeg.y, displayDeg.height / 2.0 - offsetDeg.y, -1.0, 1.0);
}

- (void)setTargets:(BOOL)state contrast0:(long)contrast0 contrast1:(long)contrast1 {

	double radiusDeg;
	
	[targetSpot0 setState:state];
	[targetSpot1 setState:state];
	if (state) {
		[targetSpot0 setOnRed:kAdjusted(kTargetRed, contrast0)  green:kAdjusted(kTargetGreen, contrast0)
					blue:kAdjusted(kTargetBlue, contrast0)];
		[targetSpot1 setOnRed:kAdjusted(kTargetRed, contrast1)  green:kAdjusted(kTargetGreen, contrast1)
					blue:kAdjusted(kTargetBlue, contrast1)];
		radiusDeg = [[NSUserDefaults standardUserDefaults] floatForKey:respSpotSizeKey];
		[targetSpot0 setOuterRadiusDeg:radiusDeg];
		[targetSpot0 setInnerRadiusDeg:radiusDeg / 2.0];
		[targetSpot0 setAzimuthDeg:[defaults floatForKey:respWindow0AziKey]];
		[targetSpot0 setElevationDeg:[defaults floatForKey:respWindow0EleKey]];
		[targetSpot1 setOuterRadiusDeg:radiusDeg];
		[targetSpot1 setInnerRadiusDeg:radiusDeg / 2.0];
		[targetSpot1 setAzimuthDeg:[defaults floatForKey:respWindow1AziKey]];
		[targetSpot1 setElevationDeg:[defaults floatForKey:respWindow1EleKey]];
		[self displayFixTargets];
	}
}

- (void)showDisplayParametersPanel {

	[displays showDisplayParametersPanel:displayIndex];
}

-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {

    display.widthPix = frameSize.width;
    display.heightPix = frameSize.height;
    [stimOpenGLContext makeCurrentContext];
    glViewport(0, 0, (long)display.widthPix, (long)display.heightPix);
    return frameSize;
}

@end
