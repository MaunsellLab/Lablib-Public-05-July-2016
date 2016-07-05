//
//  LLFixTarget.m
//  Lablib
//
//  Created by John Maunsell on Thu Feb 12 2004.
//  Copyright (c) 2006. All rights reserved.
//

#import "LLFixTarget.h"

#define kSlices		16
#define kRings		16

NSString *LLFixAzimuthDegKey;
NSString *LLFixBackColorKey;
NSString *LLFixDirectionDegKey;
NSString *LLFixElevationDegKey;
NSString *LLFixForeColorKey;
NSString *LLFixKdlThetaDegKey;
NSString *LLFixKdlPhiDegKey;
NSString *LLFixRadiusDegKey;

NSString *LLFixInnerRadiusDegKey = @"innerRadiusDeg"; 
NSString *LLFixShapeKey = @"shape"; 

@implementation LLFixTarget

- (void)dealloc;
{
    [super dealloc];
}
// The draw function assumes than an OpenGL context has already been properly set up.

- (void)draw;
{	
	BOOL transparent;
    NSColor *tempColor;
	
	if (!state) {
		return;
	}
    if (![[foreColor colorSpaceName]isEqualToString:NSCalibratedRGBColorSpace]) {
        tempColor = [[foreColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
        [foreColor release];
        foreColor = tempColor;
    }
    if (![[backColor colorSpaceName]isEqualToString:NSCalibratedRGBColorSpace]) {
        tempColor = [[backColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
        [backColor release];
        backColor = tempColor;
    }
	glPushMatrix();
	transparent = ([foreColor alphaComponent] != 1.0);
	if (transparent) {
		glPushAttrib(GL_COLOR_BUFFER_BIT);						// save current blend mode
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	}
	glColor4f([foreColor redComponent], [foreColor greenComponent], 
						[foreColor blueComponent], [foreColor alphaComponent]);
	glTranslatef(azimuthDeg, elevationDeg, 0);
	switch (shape) {
	case kLLDiamond:
		glRotatef(45.0, 0.0, 0.0, 1.0);							// rotate for diamond
		// fall through
	case kLLSquare:
		glRectf(-radiusDeg, radiusDeg, radiusDeg, -radiusDeg);
		glColor4f([backColor redComponent], [backColor greenComponent], 
						[backColor blueComponent], [backColor alphaComponent]);
		glRectf(-innerRadiusDeg, innerRadiusDeg, innerRadiusDeg, -innerRadiusDeg);
		break;
	case kLLCross:
		glBegin(GL_QUADS);
		[self drawRectWithWidthDeg:(radiusDeg / 3.0) lengthDeg:radiusDeg];
		[self drawRectWithWidthDeg:radiusDeg lengthDeg:(radiusDeg / 3.0)];
		glColor4f([backColor redComponent], [backColor greenComponent], 
						[backColor blueComponent], [backColor alphaComponent]);
		[self drawRectWithWidthDeg:(innerRadiusDeg / 3.0) lengthDeg:innerRadiusDeg];
		[self drawRectWithWidthDeg:innerRadiusDeg lengthDeg:(innerRadiusDeg / 3.0)];
		glEnd();
		break;
	case kLLCircle:
	default:
        [self drawCircleWithRadius:radiusDeg];
        glColor4f([backColor redComponent], [backColor greenComponent], [backColor blueComponent],
                                            [backColor alphaComponent]);
        [self drawCircleWithRadius:innerRadiusDeg];
		break;
	}
	if (transparent) {
		glPopAttrib();										// restore blend mode
	}
	glPopMatrix();
}

- (void)drawCircleWithRadius:(float)radDeg;
{
    long index;
    float angle;
 
    glBegin(GL_TRIANGLE_FAN);
    glVertex2f(0.0, 0.0);
    for (index = 0; index < kSlices; index++) {
        angle = index * (2.0 * kPI / kSlices);
        glVertex2f(cosf(angle) * radDeg, sinf(angle) * radDeg);
    }
    glVertex2f(radDeg, 0);
    glEnd();
}

- (void)drawRectWithWidthDeg:(float)widthDeg lengthDeg:(float)lengthDeg;
{
	glVertex2f(-widthDeg, lengthDeg);
	glVertex2f(widthDeg, lengthDeg);
	glVertex2f(widthDeg, -lengthDeg);
	glVertex2f(-widthDeg, -lengthDeg);
}	

- (NSColor *)fixTargetColor;
{
	return foreColor;
}

- (id)init;
{	
	if ((self = [super init]) != nil) {
		shape = kLLSquare;
		radiusDeg = 0.1;
		innerRadiusDeg = 0.0;
		stimPrefix = @"Fix";								// make our keys different from other LLVisualStimuli
		[keys addObjectsFromArray:[NSArray arrayWithObjects:LLFixInnerRadiusDegKey, LLFixShapeKey, nil]];

// Provide convenient access to keys declared in LLVisualStimulus

		LLFixAzimuthDegKey = LLAzimuthDegKey;
		LLFixBackColorKey = LLBackColorKey;
		LLFixDirectionDegKey = LLDirectionDegKey;
		LLFixElevationDegKey = LLElevationDegKey;
		LLFixForeColorKey = LLForeColorKey;
		LLFixKdlThetaDegKey = LLKdlThetaDegKey;
		LLFixKdlPhiDegKey = LLKdlPhiDegKey;
		LLFixRadiusDegKey = LLRadiusDegKey;
	}
	return self;
}

- (float)innerRadiusDeg;
{
	return innerRadiusDeg;
}

- (float)outerRadiusDeg;
{
	return [self radiusDeg];
}

- (void)runSettingsDialog;
{
	if (dialogWindow == nil) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"LLFixTarget" owner:self topLevelObjects:&topLevelObjects];
        [topLevelObjects retain];
		if (taskPrefix != nil) {
			[dialogWindow setTitle:[NSString stringWithFormat:@"%@ Fix Target", taskPrefix]];
		}
	}
	[dialogWindow makeKeyAndOrderFront:self];
}

- (void)setFixTargetColor:(NSColor *)newColor;
{
	[self setForeColor:newColor];
}

- (void)setInnerRadiusDeg:(float)newRadius;
{
	innerRadiusDeg = newRadius;
	[self updateFloatDefault:innerRadiusDeg key:LLFixInnerRadiusDegKey	];
}

- (void)setOnRed:(float)red green:(float)green blue:(float)blue;
{
	[self setForeOnRed:red green:green blue:blue];
}

- (void)setOuterRadiusDeg:(float)newRadius;
{
	[self setRadiusDeg:newRadius];
}

- (void)setShape:(long)newShape;
{
	shape = newShape;
	[self updateIntegerDefault:shape key:LLFixShapeKey	];
}

- (long)shape;
{
	return shape;
}

@end






