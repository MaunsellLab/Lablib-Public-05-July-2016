//
//  LLRandomDots.h
//
//  Created by John Maunsell on Sat Feb 15 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLVisualStimulus.h"

#define kRDImagePix				256						// must be a power of 2

typedef struct {
	BOOL		antialias;			// antialias the dots
	long		lifeFrames;			// Life of each dot
	long		randomSeed;			// seed for generating movie
	long		version;			// version of this structure
	float		azimuthDeg;			// Center of gabor 
	float		coherence;			// Percent coherence [0:1]
	float		density;			// Dot Density (per degree squared)
	float		directionDeg;		// Direction of motion
	float		dotContrast;		// Contrast [0:1]
	float		dotDiameterDeg;		// Dot diameter in degrees
	float		elevationDeg;		// Center of gabor 
	float		kdlPhiDeg;			// kdl space (deg)
	float		kdlThetaDeg;		// kdl space (deg)
	float		radiusDeg;			// Radius of drawing
	float		speedDPS;			// Dot speed degrees/s
	RGBFloat	backgroundColor;	// color of background
	RGBFloat	dotColor;			// color of dots
} RandomDots;

#define kLLRandomDotsEventDesc\
	{{@"boolean", @"antialias", 1, offsetof(RandomDots, antialias)},\
	{@"long", @"lifeFrames", 1, offsetof(RandomDots, lifeFrames)},\
	{@"long", @"randomSeed", 1, offsetof(RandomDots, randomSeed)},\
	{@"long", @"version", 1, offsetof(RandomDots, version)},\
	{@"float", @"azimuthDeg", 1, offsetof(RandomDots, azimuthDeg)},\
	{@"float", @"coherence", 1, offsetof(RandomDots, coherence)},\
	{@"float", @"density", 1, offsetof(RandomDots, density)},\
	{@"float", @"directionDeg", 1, offsetof(RandomDots, directionDeg)},\
	{@"float", @"dotContrast", 1, offsetof(RandomDots, dotContrast)},\
	{@"float", @"dotDiameterDeg", 1, offsetof(RandomDots, dotDiameterDeg)},\
	{@"float", @"elevationDeg", 1, offsetof(RandomDots, elevationDeg)},\
	{@"float", @"kdlPhiDeg", 1, offsetof(RandomDots, kdlPhiDeg)},\
	{@"float", @"kdlThetaDeg", 1, offsetof(RandomDots, kdlThetaDeg)},\
	{@"float", @"radiusDeg", 1, offsetof(RandomDots, radiusDeg)},\
	{@"float", @"speedDPS", 1, offsetof(RandomDots, speedDPS)},\
	{@"float", @"backgroundColor.red", 1, offsetof(RandomDots, backgroundColor.red)},\
	{@"float", @"backgroundColor.green", 1, offsetof(RandomDots, backgroundColor.green)},\
	{@"float", @"backgroundColor.blue", 1, offsetof(RandomDots, backgroundColor.blue)},\
	{@"float", @"dotColor.red", 1, offsetof(RandomDots, dotColor.red)},\
	{@"float", @"dotColor.green", 1, offsetof(RandomDots, dotColor.green)},\
	{@"float", @"dotColor.blue", 1, offsetof(RandomDots, dotColor.blue)},\
	{nil}}


extern NSString *LLRandomDotsAzimuthDegKey;
extern NSString *LLRandomDotsBackColorKey;
extern NSString *LLRandomDotsDirectionDegKey;
extern NSString *LLRandomDotsElevationDegKey;
extern NSString *LLRandomDotsForeColorKey;
extern NSString *LLRandomDotsKdlThetaDegKey;
extern NSString *LLRandomDotsKdlPhiDegKey;
extern NSString *LLRandomDotsRadiusDegKey;

extern NSString *LLRandomDotsAntialiasKey;
extern NSString *LLRandomDotsCoherenceKey;
extern NSString *LLRandomDotsDensityKey;
extern NSString *LLRandomDotsDotContrastKey;
extern NSString *LLRandomDotsDotDiameterDegKey;
extern NSString *LLRandomDotsLifeFramesKey;
extern NSString *LLRandomDotsRandomSeedKey;
extern NSString *LLRandomDotsSpeedDPSKey;

@interface LLRandomDots : LLVisualStimulus {

	BOOL			antialias;
	RandomDots		baseDots;						// dot values saved
	GLfloat			circularImage[kRDImagePix][kRDImagePix];
	GLuint			circleList;
	NSArray			*coherenceFunction;				// array of NSPoints giving coherence (x = timeMS y = cohPC)
	float			coherence;
	long			currentFrame;
	float			density;
	float			dotContrast;
	float			dotDiameterDeg;
	RandomDots		dots;							// dot values to draw
	float			fieldWidthDeg;					// width of square movie dot field (larger than patch)
	NSMutableArray  *frameList;
	long			lifeFrames;
	RGBFloat		oldBackgroundColor;
	float			oldDotDiameterDeg;
	float			oldPatchRadiusDeg;
	GLfloat			oldProjectionMatrix[16];
	float			oldSpeedDPS;
	long			randomSeed;
	float			speedDPS;
	long			version;
	
	IBOutlet		NSTextField *versionTextField;
}

- (float)density;
- (void)directSetCoherence:(float)newCoherence;
- (void)directSetDensity:(float)newDensity;
- (void)directSetDotContrast:(float)newDotContrast;
- (void)directSetSpeedDPS:(float)newSpeed;
- (float)dotContrast;
- (RandomDots *)dotsData;
- (float)dotDiameterDeg;
- (void)drawCircularStencil;
- (void)drawFrame:(long)frame;
- (void)dumpFrame:(long)frame;
- (long)lifeFrames;
- (void)loadDots:(RandomDots *)pDots;
- (void)makeMovie:(long)durationMS;
- (void)makeMovieFrames:(long)frames;
- (long)movieFrames;
- (long)randomSeed;
- (void)restore;
- (void)setAntialias:(BOOL)antialias;
- (void)setBackgroundColorRed:(float)red green:(float)green blue:(float)blue; 
- (void)setCoherenceFunction:(NSArray *)function;
- (void)setCoherence:(float)newCoherence;
- (void)setDensity:(float)newDensity;
- (void)setDotContrast:(float)newDotContrast;
- (void)setDotData:(RandomDots)d;
- (void)setDotColorRed:(float)red green:(float)green blue:(float)blue;
- (void)setDotContrast:(float)newContrast; 
- (void)setDotDiameterDeg:(float)newDotDiameter;
- (void)setLifeFrames:(long)newLife;
- (void)setRandomSeed:(long)newSeed;
- (void)setSpeedDPS:(float)newSpeed;
- (void)store;
- (long)version;

@end

