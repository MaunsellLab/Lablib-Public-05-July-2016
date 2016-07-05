//
// LLBar.m
//
// Created by John Maunsell on Thu Nov 04 2004.
// Copyright (c) 2006. All rights reserved.
//

#import "LLBar.h"

NSString *LLBarAzimuthDegKey;
NSString *LLBarBackColorKey;
NSString *LLBarDirectionDegKey;
NSString *LLBarElevationDegKey;
NSString *LLBarForeColorKey;
NSString *LLBarKdlThetaDegKey;
NSString *LLBarKdlPhiDegKey;
NSString *LLBarRadiusDegKey;

NSString *LLBarLengthDegKey = @"lengthDeg"; 
NSString *LLBarWidthDegKey = @"widthDeg";

@implementation LLBar

- (void)draw;
{	
	float halfWidthDeg = lengthDeg / 2.0;
	float halfHeightDeg = widthDeg / 2.0;

	glPushMatrix();
	glTranslatef(azimuthDeg, elevationDeg, 0.0);
	glRotatef(directionDeg, 0.0, 0.0, 1.0);
	glBegin(GL_QUADS);
	glColor3f([foreColor redComponent], [foreColor greenComponent], [foreColor blueComponent]);
	glVertex2f(-halfWidthDeg, -halfHeightDeg);
	glVertex2f(halfWidthDeg, -halfHeightDeg);
	glVertex2f(halfWidthDeg, halfHeightDeg);
	glVertex2f(-halfWidthDeg, halfHeightDeg);
	glEnd();
	glPopMatrix();
}

- (id)init;
{
    if ((self = [super init]) != nil) {
		directionDeg = 45.0;
		glClearColor(0.5, 0.5, 0.5, 1.0);					// set the background color
		glShadeModel(GL_FLAT);								// flat shading
		stimPrefix = @"Bar";								// make our keys different from other LLVisualStimuli
		[keys addObjectsFromArray:[NSArray arrayWithObjects:LLBarLengthDegKey, LLBarWidthDegKey, nil]];	
	
// Provide convenient access to keys declared in LLVisualStimulus

		LLBarAzimuthDegKey = LLAzimuthDegKey;
		LLBarBackColorKey = LLBackColorKey;
		LLBarDirectionDegKey = LLDirectionDegKey;
		LLBarElevationDegKey = LLElevationDegKey;
		LLBarForeColorKey = LLForeColorKey;
		LLBarKdlThetaDegKey = LLKdlThetaDegKey;
		LLBarKdlPhiDegKey = LLKdlPhiDegKey;
		LLBarRadiusDegKey = LLRadiusDegKey;
	}
    return self; 
}

- (float)lengthDeg;
{
	return lengthDeg;
}

- (float)orientationDeg;
{
	return directionDeg;
}

- (void)runSettingsDialog;
{
	if (dialogWindow == nil) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"LLBar" owner:self topLevelObjects:&topLevelObjects];
        [topLevelObjects retain];
		if (taskPrefix != nil) {
			[dialogWindow setTitle:[NSString stringWithFormat:@"%@ Bar", taskPrefix]];
		}
	}
	[dialogWindow makeKeyAndOrderFront:self];
}

- (void)setLengthDeg:(float)length;
{
    lengthDeg = length;
	[self updateFloatDefault:lengthDeg key:LLBarLengthDegKey];
}

- (void)setOrientationDeg:(float)newOri;
{
    [self setDirectionDeg:newOri];
}

- (void)setWidthDeg:(float)width;
{
    widthDeg = width;
	[self updateFloatDefault:widthDeg key:LLBarWidthDegKey];
}

- (float)widthDeg;
{
	return widthDeg;
}

@end

