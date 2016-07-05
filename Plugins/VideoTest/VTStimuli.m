/*
StimWindow.m
Stimulus generation
March 29, 2003 JHRM
*/

#import "VT.h"
#import "VTStimuli.h"
#import "UtilityFunctions.h"

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define	stimWindowSizePix		250		// Height and width of stim window on main display

#define kTargetBlue				0.0
#define kTargetGreen			1.0
#define kMidGray				0.5
#define kPI						(atan(1) * 4)
//#define k2PI					(atan(1) * 8)
//#define kRadiansPerDeg			(atan(1) / 45.0)
#define kTargetRed				1.0
#define kDegPerRad				57.295779513

#define kAdjusted(color, contrast)  (kMidGray + (color - kMidGray) / 100.0 * contrast)

NSString *stimulusMonitorID = @"VideoTest Stimulus";

@implementation VTStimuli

- (void) dealloc;
{
	NSEnumerator *enumerator;
	NSString *key;
	NSArray *gaborKeys;
	
	gaborKeys = [NSArray arrayWithObjects:VTAzimuthDegKey, VTElevationDegKey, VTKdlPhiDegKey, VTKdlThetaDegKey, 
						VTDirectionDegKey, VTRadiusDegKey, VTSigmaDegKey, VTSpatialFreqCPDKey, VTSpatialPhaseDegKey,
						VTTemporalFreqHzKey, nil];
	enumerator = [gaborKeys objectEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self 
			forKeyPath:[NSString stringWithFormat:@"values.%@", key]];
	}
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[fixTargets release];
	[fixSpot release];
	[targetSpot0 release];
	[targetSpot1 release];
    [gabor release];
    [super dealloc];
}

// Turn on the fixation targets.  This is the only OpenGL drawing we do other than running the stimulus
// sequence.  We must make sure that we don't ever clobber the stimulus sequence. 

- (void)displayFixTargets {

	if (stimulusOn) {
		return;
	}
	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];
    glClear(GL_COLOR_BUFFER_BIT);
	[fixTargets makeObjectsPerformSelector:@selector(draw)];
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (DisplayParam *)displayParameters {

	return &display;
}

#define kFrames 100

- (void) doStimulusPresentation {

    NSAutoreleasePool *threadPool;
    long frame, stimFrames;
	long frameTimesMS[kFrames];
	double lastTimeS, frameSumMS;
	long azimuthDeg, elevationDeg;

    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	[monitor reset]; 
	
// Set up the calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];
	[gabor setContrast:contrast / 100.0];					// set new contrast
    [gabor setSpatialPhaseDeg:[[task defaults] floatForKey:VTSpatialPhaseDegKey]];
	[gabor makeDisplayLists];								// use OpenGL display lists to speed things up

	stimFrames = durationMS / 1000.0 * ((display.frameRateHz > 0) ? display.frameRateHz : 60.0);

	[gabor store];
	
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
	lastTimeS = [LLSystemUtil getTimeS];
	frameSumMS = 0;
	
    for (frame = 0; frame < stimFrames; frame++) {
		[gabor setFrame:[NSNumber numberWithLong:frame]];	// advance for temporal modulation
		for (azimuthDeg = -10; azimuthDeg <= 10; azimuthDeg += 2) {
			for (elevationDeg = -10; elevationDeg <= 10; elevationDeg += 2) {
				[gabor setDirectionDeg:(azimuthDeg + elevationDeg + frame * 2)];
				[gabor setAzimuthDeg:(azimuthDeg) elevationDeg:(elevationDeg)];
				[gabor draw];
			}
		}
		[fixTargets makeObjectsPerformSelector:@selector(draw)];
        [[NSOpenGLContext currentContext] flushBuffer];
        glFinish();
        [monitor recordEvent];
		if (frame == 0) {
			[[task dataDoc] putEvent:@"stimulusOn" withData:&frame];
		}
		if (frame < kFrames) {
			frameTimesMS[frame] = ([LLSystemUtil getTimeS] - lastTimeS) * 1000.0;
			frameSumMS += frameTimesMS[frame];
			lastTimeS = [LLSystemUtil getTimeS];
		}
    }
	[gabor restore];

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
	[fixTargets makeObjectsPerformSelector:@selector(draw)];
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
	[[task dataDoc] putEvent:@"stimulusOff" withData:&frame];

	[[task stimWindow] unlock];
	
	for (frame = 0; frame < kFrames; frame += 10) {
		NSLog(@"%d %d %d %d %d %d %d %d %d %d",
			frameTimesMS[frame + 0], frameTimesMS[frame + 1], frameTimesMS[frame + 2], 
			frameTimesMS[frame + 3], frameTimesMS[frame + 4], frameTimesMS[frame + 5], 
			frameTimesMS[frame + 6], frameTimesMS[frame + 7], frameTimesMS[frame + 8], 
			frameTimesMS[frame + 9]);
	}
	NSLog(@"Average frame %.3f", frameSumMS / kFrames);
	for (frame = 0; frame < kFrames; frame++) {
		frameTimesMS[frame] = -1;
	}
	
// The temporal counterphase might have changed some settings.  We restore these here.

	stimulusOn = NO;
    [threadPool release];
}

- (void)erase;
{
	[[task stimWindow] lock];
    glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (id)init {

	NSArray *gaborKeys;
	NSEnumerator *enumerator;
	NSString *key;
	
	display = [[[task stimWindow] displays] displayParameters:[[task stimWindow] displayIndex]];
	monitor = [[[LLIntervalMonitor alloc] initWithID:stimulusMonitorID 
					description:@"Stimulus frame intervals"] autorelease];
	[[task monitorController] addMonitor:monitor];
	[monitor setTargetIntervalMS:1000.0 / display.frameRateHz];

// Create and initialize a gabor stimulus

	gaborKeys = [NSArray arrayWithObjects:VTAzimuthDegKey, VTElevationDegKey, VTKdlPhiDegKey, VTKdlThetaDegKey, 
						VTDirectionDegKey, VTRadiusDegKey, VTSigmaDegKey, VTSpatialFreqCPDKey, VTSpatialPhaseDegKey,
						VTTemporalFreqHzKey, nil];
						
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
	enumerator = [gaborKeys objectEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		[gabor setValue:[[task defaults] valueForKey:key] 
			forKey:[LLTextUtil stripPrefixAndDecapitalize:key prefix:@"VT"]];
	}
		
	fixSpot = [[LLFixTarget alloc] init];
	targetSpot0 = [[LLFixTarget alloc] init];
	[targetSpot0 setAzimuthDeg:-2.0];				// move off center of screen;
	targetSpot1 = [[LLFixTarget alloc] init];
	[targetSpot1 setAzimuthDeg:2.0];				// move off center of screen;
	fixTargets = [[NSArray alloc] initWithObjects:fixSpot, targetSpot0, targetSpot1, nil];

// Register for notifications about changes to the gabor settings

	enumerator = [gaborKeys objectEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
			forKeyPath:[NSString stringWithFormat:@"values.%@", key]
			options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

- (LLIntervalMonitor *)monitor {

	return monitor;
}

// Respond to changes in the gabor parameters

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	NSString *key, *gaborKey;
	id value;

	key = [keyPath pathExtension];
	gaborKey = [LLTextUtil stripPrefixAndDecapitalize:key prefix:@"VT"];
	value = [[task defaults] valueForKey:key];				// all gabor values are floats
	if ([value floatValue] != [[gabor valueForKey:gaborKey] floatValue]) {
		[gabor setValue:value forKey:gaborKey]; 
		[[task dataDoc] putEvent:@"gabor" withData:(char *)[gabor gaborData]];
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
				withObject:nil];
}

- (void)setFixSpot:(BOOL)state {

	[fixSpot setState:state];
	if (state) {
		[fixSpot setOuterRadiusDeg:[[task defaults] floatForKey:VTFixSpotSizeDegKey]];
		[self displayFixTargets];
	}
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
		radiusDeg = [[task defaults] floatForKey:VTRespSpotSizeDegKey];
		[targetSpot0 setOuterRadiusDeg:radiusDeg];
		[targetSpot0 setInnerRadiusDeg:radiusDeg / 2.0];
		[targetSpot0 setAzimuthDeg:[[task defaults] floatForKey:VTRespWindow0AziKey]];
		[targetSpot0 setElevationDeg:[[task defaults] floatForKey:VTRespWindow0EleKey]];
		[targetSpot1 setOuterRadiusDeg:radiusDeg];
		[targetSpot1 setInnerRadiusDeg:radiusDeg / 2.0];
		[targetSpot1 setAzimuthDeg:[[task defaults] floatForKey:VTRespWindow1AziKey]];
		[targetSpot1 setElevationDeg:[[task defaults] floatForKey:VTRespWindow1EleKey]];
		[self displayFixTargets];
	}
}

- (BOOL)stimulusOn;
{
	return stimulusOn;
}

@end
