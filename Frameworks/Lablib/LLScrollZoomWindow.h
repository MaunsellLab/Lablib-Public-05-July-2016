//
//  LLScrollZoomWindow.h
//  Lablib
//
//  Created by John Maunsell on 1/28/06.
//  Copyright 2006. All rights reserved.
//

@interface LLScrollZoomWindow : NSWindowController <NSWindowDelegate> {

    NSSize			baseMaxContentSize;
	NSUserDefaults	*defaults;
	NSString		*viewName;
	
	IBOutlet		NSScrollView *scrollView;
	IBOutlet		NSPopUpButton *zoomButton;
}

- (IBAction)changeZoom:(id)sender;
- (id)initWithWindowNibName:(NSString *)nibName defaults:(NSUserDefaults *)taskDefaults;
- (void)setBaseMaxContentSize:(NSSize)newSize;
- (void)setScaleFactor:(float)newFactor;
- (void)setWindowMaxSize;

@end
