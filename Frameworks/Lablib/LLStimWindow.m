//
//  LLStimWindow.m
//  Lablib
//
//  Created by John Maunsell on Sun December 26, 2004.
//  Copyright (c) 2003-2006. All rights reserved.
//

#import "LLStimWindow.h"
#import "LLSystemUtil.h"
#import <OpenGL/gl.h>

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define kStimWindowFactor       5       // How much to reduce the size of stim window relative to display
#define	stimWindowSizePix		500		// Height and width of stim window on main display

#define kLLMidGray				0.5
#define kPI						(atan(1) * 4)
#define kDegPerRadian			(180.0 / kPI)

#define kAdjusted(color, contrast)  (kLLMidGray + (color - kLLMidGray) / 100.0 * contrast)

@implementation LLStimWindow

// We needed to add the following method when we went to 10.7 and changed from capturing the screen device to making
// a window that filled the screen.  When the dispay resolution is changed, the frame of the window needs to be changed.
// This is done, but the OS ends up posting an _adjustWindowToScreen event to the NSWindow, which makes it offset 
// its origin in some strange way.  Switching between tasks that didn't change the mode seemed to fix the offset 
// (through repeated changes to the window frame, but that was unacceptale. The following method intercepts the 
// event that is causing the problem.

- (void)_adjustWindowToScreen;
{
}

- (NSPoint)centerPointPix;
{
	NSRect r;
	
	r = [displays displayBounds:displayIndex];
	return NSMakePoint(NSMidX(r), NSMidY(r));
}

- (NSPoint)centerPointPixLLOrigin;
{
	NSRect r;
	
	r = [displays displayBoundsLLOrigin:displayIndex];
	return NSMakePoint(NSMidX(r), NSMidY(r));
}

- (void) dealloc;
{
    [monitor release];
    [displays release];
	[openGLLock release];
    [super dealloc];
}

- (NSPoint)degPointFromPixPoint:(NSPoint)pointPix;
{
	NSPoint pointDeg;
	NSSize displayDeg;
	long heightPix, widthPix;
//	NSRect bounds;
	
//	if (fullscreen) {
//		bounds = [displays displayBoundsLLOrigin:displayIndex];
//		heightPix = [displays heightPix:displayIndex];
//		widthPix = [displays widthPix:displayIndex];
//	}
//	else {
    heightPix = [[self contentView] bounds].size.height;
    widthPix = [[self contentView] bounds].size.width;
//	}
	displayDeg = [displays displaySizeDeg:displayIndex];
	pointDeg.x = -displayDeg.width / 2.0 - scaleOffsetDeg.x + pointPix.x / widthPix * displayDeg.width;
	pointDeg.y = -displayDeg.height / 2.0 - scaleOffsetDeg.y + pointPix.y / heightPix * displayDeg.height;
	return pointDeg;
}

- (NSSize)degSizeFromPixSize:(NSSize)sizePix;
{
	NSSize sizeDeg;
	NSSize displayDeg;
	long heightPix, widthPix;
//	NSRect bounds;
	
//	if (fullscreen) {
////		bounds = [displays displayBoundsLLOrigin:displayIndex];
//		heightPix = [displays heightPix:displayIndex];
//		widthPix = [displays widthPix:displayIndex];
//	}
//	else {
    heightPix = [[self contentView] bounds].size.height;
    widthPix = [[self contentView] bounds].size.width;
//	}
	displayDeg = [displays displaySizeDeg:displayIndex];
	sizeDeg.width = sizePix.width / widthPix * displayDeg.width;
	sizeDeg.height = sizePix.height / heightPix * displayDeg.height;
	return sizeDeg;
}

- (DisplayParam)display;
{
	return display;
}

- (long)displayIndex;
{
	return displayIndex;
}

- (DisplayParam *)displayParameters {

	return &display;
}

// Return a rectangle with the scale of the display in degrees

- (NSRect)displayRectDeg;
{
	NSSize displayDeg = [displays displaySizeDeg:displayIndex];	// get current display size
	
	return NSMakeRect(-displayDeg.width / 2.0 - scaleOffsetDeg.x, -displayDeg.height / 2.0 - scaleOffsetDeg.y, 
			displayDeg.width, displayDeg.height);
}

- (NSSize)displaySizeDeg;
{
	return [displays displaySizeDeg:displayIndex];
}

- (LLDisplays *)displays;
{
	return displays;
}

- (void)erase;
{
	[self lock];
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[self unlock];
}

- (void)flushBuffer;
{
    [[NSOpenGLContext currentContext] flushBuffer];
}

- (float)frameRateHz;
{
	return [displays frameRateHz:displayIndex];
}

- (BOOL)fullscreen;
{
	return fullscreen;
}

- (void)grayScreen;
{
	[self lock];
    glClearColor(kLLMidGray, kLLMidGray, kLLMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
	[self unlock];
}

// Set up the stimulus window.  The window will be on the main screen if there is a single display. If there are 
// multiple displays, the last display in the display will be taken over for the stimulus display.  There is a bug
// causing a crash if there are multiple displays and the stimulus window is forced to be a window on the main display
// by forcing displayIndex to 0 and dragging the window onto a different display. But this should not be possible
// the way things are currently coded.

- (id)init;
{	
	NSRect dRect;
    NSRect stimRect;
    NSSize stimWindowSize;
    const GLint swapParam = 1;
    NSOpenGLPixelFormatAttribute windowedAttrib[] = {
        NSOpenGLPFANoRecovery, NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute) 24,
        NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute) 8,
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute) 0,
        NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute) 8,
        NSOpenGLPFAAccumSize, (NSOpenGLPixelFormatAttribute) 0,
        0                       // must be null terminated
//        NSOpenGLPFAWindow, (NSOpenGLPixelFormatAttribute) 0
        };
    NSOpenGLPixelFormat *fmt;
	
	openGLLock = [[NSLock alloc] init];
	displays = [[LLDisplays alloc] init];
	displayIndex = [displays numDisplays] - 1;      // use main if only one display, otherwise use the last
    if (displayIndex < 0) {                         // no display
		return nil;
	}
	display = [displays displayParameters:displayIndex];    // get the stimulus display parameters
	[openGLLock lock];
	switch (displayIndex) {
	case 0:										// only one display, create stimulus window on it
		dRect = [displays displayBoundsLLOrigin:displayIndex];
            stimWindowSize.width = dRect.size.width / kStimWindowFactor;
            stimWindowSize.height = dRect.size.height / kStimWindowFactor;
		stimRect = NSMakeRect(dRect.origin.x + dRect.size.width - stimWindowSize.width - 10,
			dRect.origin.y + dRect.size.height - stimWindowSize.height - 55, 
            stimWindowSize.width, stimWindowSize.height);
		self = [super initWithContentRect:stimRect 
					styleMask: NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
					backing:NSBackingStoreBuffered defer:NO];
        [self setContentAspectRatio:stimWindowSize];
		[self setTitle:@"Stimulus"];
//		fmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttrib] autorelease];
//		if (!fmt) {
//			NSLog(@"Cannot create NSOpenGLPixelFormat");
//			[openGLLock unlock];
//			return nil;
//		}
//		[self setContentView:[[[NSOpenGLView alloc] 
//					initWithFrame:NSMakeRect(0, 0, stimRect.size.width, stimRect.size.height) 
//					pixelFormat:fmt] autorelease]];
//		stimOpenGLContext = [[self contentView] openGLContext];
//		[stimOpenGLContext makeCurrentContext];
//		[stimOpenGLContext setValues:&swapParam forParameter:NSOpenGLCPSwapInterval];
//		[self setDelegate:self];				// set up to receive delegate messages (for resize)
//		[self makeKeyAndOrderFront:nil];
		break;
	case 1:                                                 // more than one screen, use the second one
	default:                                                //   regardless of the number of screens
		fullscreen = YES;                                   // flag fullscreen mode
		if ([displays setDisplayMode:displayIndex size:CGSizeMake(display.widthPix, display.heightPix) 
					bitDepth:display.pixelBits frameRate:display.frameRateHz]) {
			[displays dumpCurrentDisplayMode:displayIndex];
		}
		self = [super initWithContentRect:[displays displayBoundsLLOrigin:displayIndex] styleMask:NSBorderlessWindowMask 
                        backing:NSBackingStoreBuffered defer:NO];
        [self setLevel:NSMainMenuWindowLevel + 1];          // move window to front of all windows
		break;
	}
    [self setDelegate:self];				// set up to receive delegate messages (for resize)
    fmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttrib] autorelease];
    if (fmt == nil) {
        NSLog(@"Cannot create NSOpenGLPixelFormat");
        [self autorelease];
        return nil;
    }
    [self setContentView:[[[NSOpenGLView alloc] initWithFrame:NSMakeRect(0, 0, display.widthPix, display.heightPix)
                           pixelFormat:fmt] autorelease]];
    stimOpenGLContext = [[self contentView] openGLContext];
    [stimOpenGLContext makeCurrentContext];
    [stimOpenGLContext setValues:&swapParam forParameter:NSOpenGLCPSwapInterval];
    [self makeKeyAndOrderFront:nil];
	[openGLLock unlock]; 
	[self grayScreen];
    
    monitor = [[LLIntervalMonitor alloc] initWithID:@"Stimulus" description:@"Stimulus frame intervals"];
	[monitor setTargetIntervalMS:1000.0 / display.frameRateHz];

	return self;
}

- (LLIntervalMonitor *)monitor;
{
	return monitor;
}

- (void)lock;
{
	[openGLLock lock];
    [stimOpenGLContext makeCurrentContext];
    if ([self contentView]) {
        [[self contentView] lockFocus];
    }
}

// Returns whether the mouse is current in the window

- (BOOL)mouseInside;
{
    return NSPointInRect([self mouseLocationOutsideOfEventStream], [[self contentView] bounds]);
}

// Return the current moust location, scaled to degree

- (NSPoint)mouseLocationDeg;
{
	NSPoint mousePix, mouseDeg;
	NSSize displayDeg;
	long heightPix, widthPix;
//	NSRect bounds;
	
	mousePix = [self mouseLocationOutsideOfEventStream];
	displayDeg = [displays displaySizeDeg:displayIndex];
//	if (fullscreen) {
////		bounds = [displays displayBoundsLLOrigin:displayIndex];
////		mousePix.x -= bounds.origin.x;
////		mousePix.y -= bounds.origin.y;
//		heightPix = [displays heightPix:displayIndex];
//		widthPix = [displays widthPix:displayIndex];
//	}
//	else {
    heightPix = [[self contentView] bounds].size.height;
    widthPix = [[self contentView] bounds].size.width;
//	}
	mouseDeg.x = -displayDeg.width / 2.0 - scaleOffsetDeg.x + mousePix.x / widthPix * displayDeg.width;
	mouseDeg.y = -displayDeg.height / 2.0 - scaleOffsetDeg.y + mousePix.y / heightPix * displayDeg.height;
	return mouseDeg;
}

- (NSPoint)pixPointFromDegPoint:(NSPoint)pointDeg;
{
	NSPoint pointPix;
	NSSize displayDeg;
	long heightPix, widthPix;

//	if (fullscreen) {
//		bounds = [displays displayBoundsLLOrigin:displayIndex];
//		heightPix = [displays heightPix:displayIndex];
//		widthPix = [displays widthPix:displayIndex];
//	}
//	else {
    heightPix = [[self contentView] bounds].size.height;
    widthPix = [[self contentView] bounds].size.width;
//	}
	displayDeg = [displays displaySizeDeg:displayIndex];
	pointPix.x = widthPix / 2 + widthPix * (pointDeg.x + scaleOffsetDeg.x) / displayDeg.width;
	pointPix.y = heightPix / 2 + heightPix * (pointDeg.y + scaleOffsetDeg.y) / displayDeg.height;
	return pointPix;
}

- (NSSize)pixSizeFromDegSize:(NSSize)sizeDeg;
{
	NSSize sizePix;
	NSSize displayDeg;
	long heightPix, widthPix;
//	NSRect bounds;
	
//	if (fullscreen) {
//		bounds = [displays displayBoundsLLOrigin:displayIndex];
//		heightPix = [displays heightPix:displayIndex];
//		widthPix = [displays widthPix:displayIndex];
//	}
//	else {
    heightPix = [[self contentView] bounds].size.height;
    widthPix = [[self contentView] bounds].size.width;
//	}
	displayDeg = [displays displaySizeDeg:displayIndex];
	sizePix.width = sizeDeg.width / displayDeg.width * widthPix;
	sizePix.height = sizeDeg.height / displayDeg.height * heightPix;
	return sizePix;
}

// Set the OpenGL scaling.  Assumes that the currentContext has been correctly set up.

- (void)setScaleOffsetDeg:(NSPoint)offsetDeg;
{
	scaleOffsetDeg = offsetDeg;
}

- (BOOL)setDisplayMode:(DisplayModeParam)newMode;
{
    
// First check whether we already have an acceptable display set up

	newMode.frameRateHz = (newMode.frameRateHz == 0) ? display.frameRateHz : newMode.frameRateHz;
	newMode.pixelBits = (newMode.pixelBits == 0) ? display.pixelBits : newMode.pixelBits;
	newMode.widthPix = (newMode.widthPix == 0) ? display.widthPix : newMode.widthPix;
	newMode.heightPix = (newMode.heightPix == 0) ? display.heightPix : newMode.heightPix;
	if (newMode.frameRateHz == display.frameRateHz &&  newMode.pixelBits == display.pixelBits &&
					newMode.widthPix == display.widthPix && newMode.heightPix == display.heightPix) {
		return YES;                                             // already using this mode, do nothing
	}
	if (displayIndex != 0) {                                    // fullscreen display?
		[openGLLock lock];
		[displays setDisplayMode:displayIndex size:CGSizeMake(newMode.widthPix, newMode.heightPix) 
				   bitDepth:newMode.pixelBits frameRate:newMode.frameRateHz];
		[displays dumpCurrentDisplayMode:displayIndex];
		display = [displays displayParameters:displayIndex];		// get new display parameters
		[monitor setTargetIntervalMS:1000.0 / display.frameRateHz];	// assign monitor new framerate
        [self setFrame:[displays displayBoundsLLOrigin:displayIndex] display:NO];
        [stimOpenGLContext makeCurrentContext];
        glViewport(0, 0, (long)display.widthPix, (long)display.heightPix);
		[openGLLock unlock];
	}
	[self grayScreen];
    return YES;
}

- (void)scaleDisplay;
{
	NSSize displayDeg = [displays displaySizeDeg:displayIndex];	// get current display size;

// Set up the calibration, including the offset
// We do not need to lock, because this is called from within functions that lock.

	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-displayDeg.width / 2.0 - scaleOffsetDeg.x, displayDeg.width / 2.0 - scaleOffsetDeg.x, 
			-displayDeg.height / 2.0 - scaleOffsetDeg.y, displayDeg.height / 2.0 - scaleOffsetDeg.y, -1.0, 1.0);
}

- (NSPoint)scaleOffsetDeg;
{
	return scaleOffsetDeg;
}

- (void)showDisplayParametersPanel {

	[displays showDisplayParametersPanel:displayIndex];
}

- (void)unlock;
{
	glFlush();														// flush any pending commands
    if ([self contentView]) {
        [[self contentView] unlockFocus];
    }
	[openGLLock unlock];
}

-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
{
    display.widthPix = frameSize.width;
    display.heightPix = frameSize.height;
    [stimOpenGLContext makeCurrentContext];
    glViewport(0, 0, (long)display.widthPix, (long)display.heightPix);
    return frameSize;
}

@end
