//
//  RFXTController.h
//  Experiment
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2004. All rights reserved.
//

extern NSString	*trialWindowVisibleKey;
extern NSString	*trialWindowZoomKey;

@interface RFXTController : NSWindowController {

@private
    NSSize			staticWindowFrame;

    IBOutlet		NSScrollView *scrollView;
    IBOutlet		LLXTView *xtView;
    IBOutlet		NSPopUpButton *zoomButton;
}

- (IBAction) changeFreeze:(id)sender;
- (IBAction) changeZoom:(id)sender;
- (void) positionZoomButton;
- (void) setScaleFactor:(double)factor;
- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end
