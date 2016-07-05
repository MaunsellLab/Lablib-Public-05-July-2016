//
//  LLScrollZoomWindow.m
//  Lablib
//
//  Created by John Maunsell on 1/28/06.
//  Copyright 2006. All rights reserved.
//

#import "LLScrollZoomWindow.h"

NSString *windowVisibleKey = @"WindowVisible";
NSString *windowZoomKey = @"WindowZoom";

@implementation LLScrollZoomWindow

- (IBAction)changeZoom:(id)sender;
{
    long zoomValue;
    
    zoomValue = [[sender selectedCell] tag];
    [self setScaleFactor:zoomValue / 100.0];
    [defaults setObject:[NSNumber numberWithInt:zoomValue] 
                forKey:[NSString stringWithFormat:@"%@%@", viewName, windowZoomKey]];
}

- (void)dealloc;
{
	[viewName release];
	[defaults release];
	[super dealloc];
}

- (id)initWithWindowNibName:(NSString *)nibName defaults:(NSUserDefaults *)taskDefaults;
{
   if ((self = [super initWithWindowNibName:nibName]) != nil) {
		viewName = nibName;
		[viewName retain];
		defaults = taskDefaults;
		[defaults retain];
 		[self setShouldCascadeWindows:NO];
        [self window];							// Force the window to load now
	}
	return self;
}

- (void) positionZoomButton;
{
    NSRect scrollerRect, buttonRect;
    
    scrollerRect = [[scrollView horizontalScroller] frame];
    scrollerRect.size.width = [scrollView frame].size.width - scrollerRect.size.height - 8;
    NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, 60.0, NSMaxXEdge);
    [[scrollView horizontalScroller] setFrame:scrollerRect];
    [[scrollView horizontalScroller] setNeedsDisplay:YES];
    buttonRect.origin.y += buttonRect.size.height;				// Offset because the clipRect is flipped
    buttonRect.origin = [[[self window] contentView] convertPoint:buttonRect.origin fromView:scrollView];
    [zoomButton setFrame:NSInsetRect(buttonRect, 1.0, 1.0)];
    [zoomButton setNeedsDisplay:YES];
}

- (void)setBaseMaxContentSize:(NSSize)newSize;
{
	baseMaxContentSize = newSize;
	[self setWindowMaxSize];
}

- (void)setScaleFactor:(float)newFactor;
{
    float delta, scaleFactor;
  
	scaleFactor = (baseMaxContentSize.width / [[scrollView contentView] bounds].size.width) /
			(baseMaxContentSize.width / [[scrollView contentView] frame].size.width);
    if (scaleFactor != newFactor) {
        delta = newFactor / scaleFactor;
		[[scrollView contentView] scaleUnitSquareToSize:NSMakeSize(delta, delta)];
        [self positionZoomButton];
        [scrollView display];
		[self setWindowMaxSize];
	}
}

// Limit the maximum size of the window.  
  
- (void)setWindowMaxSize;
{
	float scaleFactor;
    NSSize maxContentSize, maxSize;
	NSWindow *window;
    NSScroller *hScroller, *vScroller;
    NSRect scrollFrameRect, windowFrameRect, frame;

	scaleFactor = (baseMaxContentSize.width / [[scrollView contentView] bounds].size.width) /
			(baseMaxContentSize.width / [[scrollView contentView] frame].size.width);
	maxContentSize.width = baseMaxContentSize.width * scaleFactor;
	maxContentSize.height = baseMaxContentSize.height * scaleFactor;
	scrollFrameRect.origin = NSMakePoint(0, 0);
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    hScroller = [scrollView horizontalScroller];
    vScroller = [scrollView verticalScroller];
    scrollFrameRect.size = [NSScrollView frameSizeForContentSize:maxContentSize
                    horizontalScrollerClass:[hScroller class] verticalScrollerClass:[vScroller class] 
                    borderType:[scrollView borderType]
                    controlSize:[hScroller controlSize] scrollerStyle:[hScroller scrollerStyle]];
#else
    scrollFrameRect.size = [NSScrollView frameSizeForContentSize:maxContentSize 
                    hasHorizontalScroller:YES hasVerticalScroller:YES borderType:[scrollView borderType]];
#endif	
	window = [self window];
	windowFrameRect = [NSWindow frameRectForContentRect:scrollFrameRect styleMask:[window styleMask]];
	[window setMaxSize:windowFrameRect.size];
	frame = [window frame];
	maxSize = [window maxSize];
//	if (maxSize.width < frame.size.width || maxSize.height < frame.size.height) {
		[window setFrame:NSMakeRect(frame.origin.x, frame.origin.y, maxSize.width, maxSize.height) 
					display:YES];
//	}
}

// Subclassed must call this from within their -windowDidLoad method ([super windowDidLoad])

- (void)windowDidLoad;
{
	long index, defaultZoom;
	NSRect maxScrollRect;
    NSScroller *hScroller, *vScroller;
	
	[self setWindowFrameAutosaveName:viewName];
	[[self window] setDelegate:self];
	maxScrollRect = [NSWindow contentRectForFrameRect:
		NSMakeRect(0, 0, [[self window] maxSize].width, [[self window] maxSize].height)
		styleMask:[[self window] styleMask]];
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    hScroller = [scrollView horizontalScroller];
    vScroller = [scrollView verticalScroller];
    baseMaxContentSize = [NSScrollView contentSizeForFrameSize:maxScrollRect.size
                                horizontalScrollerClass:[hScroller class] verticalScrollerClass:[vScroller class]
                                borderType:[scrollView borderType]
                                controlSize:[hScroller controlSize] scrollerStyle:[hScroller scrollerStyle]];
#else
    baseMaxContentSize = [NSScrollView contentSizeForFrameSize:maxScrollRect.size
                                         hasHorizontalScroller:YES hasVerticalScroller:YES
                                                    borderType:[scrollView borderType]];
#endif
    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
    defaultZoom = [defaults integerForKey:[NSString stringWithFormat:@"%@%@", viewName, windowZoomKey]];
	if (defaultZoom <= 0) {
		defaultZoom = 100;
	}
    for (index = 0; index < [[zoomButton itemArray] count]; index++) {
        if ([[zoomButton itemAtIndex:index] tag] == defaultZoom) {
            [zoomButton selectItemAtIndex:index];
            break;
        }
    }
	if (defaultZoom != 100.0) {
	    [self setScaleFactor:defaultZoom / 100.0];
	}
    [self positionZoomButton];								// position zoom must be after visible
	[[self window] setFrameUsingName:viewName];				// needed when opened a second time
    if ([defaults boolForKey:[NSString stringWithFormat:@"%@%@", viewName, windowVisibleKey]]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }
}

// Delegate methods for the window

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[defaults setObject:[NSNumber numberWithBool:YES] 
		forKey:[NSString stringWithFormat:@"%@%@", viewName, windowVisibleKey]];
}

// We use a delegate method to detect when the window has resized, and 
// adjust the postion of the zoom button when it does.

- (void) windowDidResize:(NSNotification *)aNotification;
{
	[self positionZoomButton];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [defaults setObject:[NSNumber numberWithBool:NO] 
                forKey:[NSString stringWithFormat:@"%@%@", viewName, windowVisibleKey]];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

@end
