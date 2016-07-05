//
//  LLStimView.m
//  Lablib
//
//  Created by John Maunsell on 1/9/05.
//  Copyright 2005. All rights reserved.
//

#import "LLStimView.h"
#define kPixelDepthBits			32		// Depth of pixels in stimulus window

@implementation LLStimView

- (NSPoint)centerPointPix;
{
	NSRect r = [self bounds];
	return NSMakePoint(NSMidX(r), NSMidY(r));
}

- (void) dealloc;
{
//    [displays releaseDisplay:displayIndex];
	[displays release];
	[openGLLock release];
    [super dealloc];
}

- (long)displayIndex;
{
	return displayIndex;
}

- (DisplayParam *)displayParameters;
{
	displayParameters = [displays displayParameters:displayIndex];
	return &displayParameters;
}

- (LLDisplays *)displays;
{
	return displays;
}

- (BOOL)fullscreen;
{
	return fullscreen;
}

- (id)initWithFrame:(NSRect)frameRect displayIndex:(long)dIndex;
{
	NSTrackingRectTag tag;
    NSOpenGLPixelFormat *format;
	long swapParam = 1;
	NSOpenGLPixelFormatAttribute attr[] = {
		NSOpenGLPFANoRecovery, 
		NSOpenGLPFAAccelerated, 
		NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute) 24,
        NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute) 8,
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute) 0,
		NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute) 0,
		NSOpenGLPFAAccumSize, (NSOpenGLPixelFormatAttribute) 0,
        NSOpenGLPFAWindow, (NSOpenGLPixelFormatAttribute) 0,
        0 };

    [self setPostsFrameChangedNotifications:YES];
    format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attr] autorelease];
    if (!format) { 
		NSLog(@"LLStimView: Invalid pixel format"); 
		return nil; 
	}
	if ((self = [super initWithFrame:frameRect pixelFormat:format]) != nil) {
		openGLLock = [[NSLock alloc] init];
		displays = [[LLDisplays alloc] init];
		displayIndex = (dIndex > [displays numDisplays] - 1) ? 0 : dIndex;
		if (displayIndex > 0) {
			fullscreen = YES;
			[self makeFullscreenWindow];
		}
		else {
			fullscreen = NO;
			[self makeWindow:frameRect];
			stimOpenGLContext = [self openGLContext];
		}
		stimOpenGLContext = [self openGLContext];
		[stimOpenGLContext makeCurrentContext];
		[stimOpenGLContext setValues:&swapParam forParameter:NSOpenGLCPSwapInterval];
		tag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
	}
    return self;
}

- (void)lock;
{
	[openGLLock lock];
    [stimOpenGLContext makeCurrentContext];
	[self lockFocus];
}

// Create a fullscreen window and make us the contentView. 

- (void)makeFullscreenWindow;
{
	NSWindow *theWindow;
	
	theWindow = [[NSWindow alloc] initWithContentRect:[displays displayBoundsLLOrigin:displayIndex]
					styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[theWindow setReleasedWhenClosed:YES];
	[theWindow setContentView:self];
	[theWindow makeKeyAndOrderFront:self];
	[theWindow setLevel:NSScreenSaverWindowLevel - 1];
}

// Create a window that is not fullscreen and make us the contentView. 

- (void)makeWindow:(NSRect)contentRect;
{
	NSWindow *theWindow;

	theWindow = [[NSWindow alloc] initWithContentRect:contentRect 
				styleMask: NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
				backing:NSBackingStoreBuffered defer:NO];
	[theWindow setTitle:@"Stimulus"];
	[theWindow setFrameAutosaveName:LLStimViewFrame];
	[theWindow setContentView:self];
	[theWindow setDelegate:self];				// set up to receive delegate messages
	[theWindow orderFront:self];
}

- (BOOL)mouseButtonDown;
{
	return mouseButtonDown;
}

- (void)mouseDown:(NSEvent *)event;
{
	mouseButtonDown = YES;
}

- (void)mouseEntered:(NSEvent *)event;
{
	[NSCursor hide];
	mouseInView = YES;
}

- (void)mouseExited:(NSEvent *)event;
{
	[NSCursor unhide];
	mouseInView = NO;
}

- (BOOL)mouseInView;
{
	return mouseInView;
}

- (NSPoint)mouseLocationDeg;
{
	NSPoint mousePix, mouseDeg;
	NSSize displayDeg;
	
	mousePix = [[self window] mouseLocationOutsideOfEventStream];
	displayDeg = [displays displaySizeDeg:displayIndex];
	mouseDeg.x = -displayDeg.width / 2.0 - scaleOffsetDeg.x + 
			mousePix.x / [self bounds].size.width * displayDeg.width;
	mouseDeg.y = -displayDeg.height / 2.0 - scaleOffsetDeg.y + 
			mousePix.y / [self bounds].size.height * displayDeg.height;
	return mouseDeg;
}

- (void)mouseUp:(NSEvent *)event;
{
	mouseButtonDown = NO;
}

- (void)scaleDisplay;
{
	NSSize displayDeg;
	
// Set up the calibration, including the offset
// We do not need to lock, because this is called from within functions that lock.

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	displayDeg = [displays displaySizeDeg:displayIndex];	// get current display size
    glOrtho(-displayDeg.width / 2.0 - scaleOffsetDeg.x, displayDeg.width / 2.0 - scaleOffsetDeg.x, 
			-displayDeg.height / 2.0 - scaleOffsetDeg.y, displayDeg.height / 2.0 - scaleOffsetDeg.y, -1.0, 1.0);
}

// Set the OpenGL scaling.  Assumes that the currentContext has been correctly set up.

- (void)setScaleOffsetDeg:(NSPoint)offsetDeg;
{
	scaleOffsetDeg = offsetDeg;
}

- (void)showDisplayParametersPanel;
{
	[displays showDisplayParametersPanel:displayIndex];
}

- (void)unlock;
{
	[self unlockFocus];
	[openGLLock unlock];
}

@end
