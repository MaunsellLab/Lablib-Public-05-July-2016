/*
FTStimuli.m
Stimulus generation
December 26, 2004 John Maunsell
*/

#import "FTStimuli.h"
#import "FT.h"
#import <OpenGL/gl.h>

@implementation FTStimuli

- (void) dealloc;
{
	[fixSpot release];
    [super dealloc];
}

- (void)drawFixSpot;
{
	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];
    glClear(GL_COLOR_BUFFER_BIT);
	[fixSpot draw];
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (void)erase;
{
	[[task stimWindow] lock];
    glClearColor(0.5, 0.5, 0.5, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (LLFixTarget *)fixSpot;
{
	return fixSpot;
}

- (id)init;
{
	NSEnumerator *enumerator;
	NSString *key, *fixTargetKey;

	if ((self = [super init]) != nil) {
		fixSpot = [[LLFixTarget alloc] init];
		[fixSpot setState:YES];
		[[task defaults] registerDefaults:
					[NSDictionary dictionaryWithObject:
					[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] 
					forKey:FTFixForeColorKey]];
		[[task defaults] registerDefaults:
					[NSDictionary dictionaryWithObject:
					[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0]] 
					forKey:FTFixBackColorKey]];

// For each of the entries in the settings dialog, set the fix spot
// to the current value and set up to receive report when the value changes.
 
		[fixSpot bindValuesToKeysWithPrefix:@"FT"];
		[fixSpot setBackOnRed:0.5 green:0.5 blue:0.5];
	}
	return self;
}
@end
