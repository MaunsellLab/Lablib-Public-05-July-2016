//
//  LLStimView.h
//  Lablib
//
//  Created by John Maunsell on 1/9/05.
//  Copyright 2005. All rights reserved.
//

#import "LLDisplays.h"
#import <OpenGL/gl.h>

@interface LLStimView : NSOpenGLView {

	DisplayParam			display;
	long					displayIndex;
	DisplayParam			displayParameters;
	LLDisplays				*displays;
	BOOL					fullscreen;
	BOOL					mouseButtonDown;
	BOOL					mouseInView;
	NSLock					*openGLLock;
	NSPoint					scaleOffsetDeg;
	NSOpenGLContext 		*stimOpenGLContext;
}

- (NSPoint)centerPointPix;
- (long)displayIndex;
- (DisplayParam *)displayParameters;
- (LLDisplays *)displays;
- (BOOL)fullscreen;
- (id)initWithFrame:(NSRect)frameRect displayIndex:(long)dIndex;
- (void)lock;
- (void)makeFullscreenWindow;
- (void)makeWindow:(NSRect)contentRect;
- (BOOL)mouseButtonDown;
- (BOOL)mouseInView;
- (NSPoint)mouseLocationDeg;
- (void)scaleDisplay;
- (void)setScaleOffsetDeg:(NSPoint)offsetDeg;
- (void)showDisplayParametersPanel;
- (void)unlock;

@end
