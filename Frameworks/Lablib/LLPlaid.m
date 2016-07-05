//
// LLPlaid.m
// Experiment
//
// Created by John Maunsell on Sat Feb 15 2009.
// Copyright (c) 2009. All rights reserved.
//
// Based on LLGabor.  See basic principles there.

#import "LLPlaid.h"
#import "LLTextUtil.h"
#import "LLMultiplierTransformer.h"
#import "LLSystemUtil.h"

#define glMultiTexCoord2f	glMultiTexCoord2fARB
#define glMultiTexCoord2fv	glMultiTexCoord2fvARB
//#define glActiveTexture		glActiveTextureARB
#define kCyclePix			256						// must be a power of 2
#define kGaussianImagePix   256						// must be a power of 2
#define kRadiusLimitSigma   3.0						// maximum radius relative to sigma

// The following are declared as class variables, because the same textures can be used to 
// draw all the instances of LLPlaid.  lastPlaid keeps track of the texture variables
// of the last Plaid that was drawn.  displayListPlaid keeps track of the variables
// that were used to make the display lists.

static GLuint	circleList;
GLuint			cycleTexture0 = 0;
GLuint			cycleTexture1 = 0;
GLuint			plaidGaussianTexture = 0;
Plaid			lastPlaid = {};
//static GLfloat	lastProjectionMatrix[16];
GLint			plaidNumTextureUnits = 0;
static GLubyte	sinImage[kCyclePix][4];
static GLubyte	triImage[kCyclePix][4];
static GLubyte	squareImage[kCyclePix][4];

NSString *LLPlaidAzimuthDegKey;
NSString *LLPlaidBackColorKey;
NSString *LLPlaidElevationDegKey;
NSString *LLPlaidForeColorKey;
NSString *LLPlaidRadiusDegKey;
NSString *LLPlaidSigmaDegKey;

NSString *LLPlaidAchromaticKey = @"achromatic";
NSString *LLPlaidSigmaDegKey = @"sigmaDeg";

NSString *LLPlaid0ContrastKey = @"contrast0";
NSString *LLPlaid0DirectionDegKey = @"directionDeg0";
NSString *LLPlaid0KdlThetaDegKey = @"kdlThetaDeg0";
NSString *LLPlaid0KdlPhiDegKey = @"kdlPhiDeg0";
NSString *LLPlaid0SpatialFreqCPDKey = @"spatialFreqCPD0";
NSString *LLPlaid0SpatialModulationKey = @"spatialModulation0";
NSString *LLPlaid0SpatialPhaseDegKey = @"spatialPhaseDeg0";
NSString *LLPlaid0TemporalFreqHzKey = @"temporalFreqHz0";
NSString *LLPlaid0TemporalModulationParamKey = @"temporalModulationParam0";
NSString *LLPlaid0TemporalModulationKey = @"temporalModulation0";
NSString *LLPlaid0TemporalPhaseDegKey = @"temporalPhaseDeg0";

NSString *LLPlaid1ContrastKey = @"contrast1"; 
NSString *LLPlaid1DirectionDegKey = @"directionDeg1";
NSString *LLPlaid1KdlThetaDegKey = @"kdlThetaDeg1";
NSString *LLPlaid1KdlPhiDegKey = @"kdlPhiDeg1";
NSString *LLPlaid1SpatialFreqCPDKey = @"spatialFreqCPD1";
NSString *LLPlaid1SpatialModulationKey = @"spatialModulation1";
NSString *LLPlaid1SpatialPhaseDegKey = @"spatialPhaseDeg1";
NSString *LLPlaid1TemporalFreqHzKey = @"temporalFreqHz1";
NSString *LLPlaid1TemporalModulationParamKey = @"temporalModulationParam1";
NSString *LLPlaid1TemporalModulationKey = @"temporalModulation1";
NSString *LLPlaid1TemporalPhaseDegKey = @"temporalPhaseDeg1";

@implementation LLPlaid

- (float)contrast0;
{
	return contrast0;
}

- (float)contrast1;
{
	return contrast1;
}

- (void)dealloc;
{
	[self removeObserver:self forKeyPath:@"temporalModulation0"];
	[self removeObserver:self forKeyPath:@"temporalModulation1"];
    [self restore:0];
    [self restore:1];
	if (displayListNum > 0) {
        glDeleteLists(displayListNum, kLLPlaidDrawCircle + 1);
	}
	[super dealloc];					// super will take care of unbinding keys, if needed
}

- (float)directionDeg0;
{
	return directionDeg0;
}

- (float)directionDeg1;
{
	return directionDeg1;
}

- (void)directSetContrast0:(float)newContrast;
{
	contrast0 = MIN(newContrast, achromatic ? 1.0 : 1.0 / sqrt(2.0));
}

- (void)directSetContrast1:(float)newContrast;
{
	contrast1 = MIN(newContrast, achromatic ? 1.0 : 1.0 / sqrt(2.0));
}

// Do setFrame without being key-value compliant.  Changes will not be reflected by observers (defaults, dialog, etc).
// This runs faster than setFrame because no observers are notified of changes to the plaid values.

- (void)directSetFrame:(NSNumber *)frameNumber;
{
    long  cycles, frame;
	float frameRateHz, framesPerHalfCycle;
    float *currentPhase;
		
	frame = [frameNumber longValue];
	frameRateHz = (displays == nil) ? 60.0 : [displays frameRateHz:displayIndex];

	currentPhase = &spatialPhaseDeg0;
	if (temporalFreqHz0 > 0.0 && frameRateHz > 0.0) {
		framesPerHalfCycle = frameRateHz / temporalFreqHz0 / 2.0;
		switch (temporalModulationParam0) {
			case kLLPlaidDirection:
				currentPhase = &directionDeg0;
				break;
			case kLLPlaidKdlTheta:
				currentPhase = &kdlThetaDeg0;
				break;
			case kLLPlaidKdlPhi:
				currentPhase = &kdlPhiDeg0;
				break;
			case kLLPlaidSPhase:
			default:
				currentPhase = &spatialPhaseDeg0;
				break;
		}
		switch (temporalModulation0) {
			case kLLPlaidDrifting:
				*currentPhase = temporalPhaseDeg0 + frame / framesPerHalfCycle * 180.0;
				break;
			case kLLPlaidRandom:
				if ((frame % (long)ceil(framesPerHalfCycle)) == 0) {
					*currentPhase = (rand() % 360);
				}
				break;
// 
// NB: You must set the basePlaid values (using -store) before starting a counterphasing grating, and
// you must restore the original contrast (using -restore) when you have finished the counterphasing.
//				
			case kLLPlaidCounterPhase:
			default:
				contrast0 = basePlaid.contrast0 * sin(frame / framesPerHalfCycle * kPI + temporalPhaseDeg0 * kRadiansPerDeg);
				break;
		}
	}
	cycles = floor(*currentPhase / 360.0);
	*currentPhase -= cycles * 360.0;
	
	currentPhase = &spatialPhaseDeg1;
	if (temporalFreqHz1 > 0.0 && frameRateHz > 0.0) {
		framesPerHalfCycle = frameRateHz / temporalFreqHz1 / 2.0;
		switch (temporalModulationParam1) {
			case kLLPlaidDirection:
				currentPhase = &directionDeg1;
				break;
			case kLLPlaidKdlTheta:
				currentPhase = &kdlThetaDeg1;
				break;
			case kLLPlaidKdlPhi:
				currentPhase = &kdlPhiDeg1;
				break;
			case kLLPlaidSPhase:
			default:
				currentPhase = &spatialPhaseDeg1;
				break;
		}
		switch (temporalModulation1) {
			case kLLPlaidDrifting:
				*currentPhase = temporalPhaseDeg1 + frame / framesPerHalfCycle * 180.0;
				break;
			case kLLPlaidRandom:
				if ((frame % (long)ceil(framesPerHalfCycle)) == 0) {
					*currentPhase = (rand() % 360);
				}
				break;
				// 
				// NB: You must set the basePlaid values (using -store) before starting a counterphasing grating, and
				// you must restore the original contrast (using -restore) when you have finished the counterphasing.
				//				
			case kLLPlaidCounterPhase:
			default:
				contrast1 = basePlaid.contrast1 * sin(frame / framesPerHalfCycle * kPI + temporalPhaseDeg1 * kRadiansPerDeg);
				break;
		}
	}
	cycles = floor(*currentPhase / 360.0);
	*currentPhase -= cycles * 360.0;
	
}

- (void)directSetSigmaDeg:(float)newSigma;
{
    sigmaDeg = newSigma;
}

- (void)directSetSpatialFreqCPD0:(float)newSF;
{
    spatialFreqCPD0 = newSF;
}

- (void)directSetSpatialFreqCPD1:(float)newSF;
{
    spatialFreqCPD1 = newSF;
}


- (void)directSetSpatialPhaseDeg0:(float)newSPhase;
{
    spatialPhaseDeg0 = newSPhase;
}

- (void)directSetSpatialPhaseDeg1:(float)newSPhase;
{
    spatialPhaseDeg1 = newSPhase;
}

- (void)directSetTemporalFreqHz0:(float)newTF;
{
    temporalFreqHz0 = newTF;
}

- (void)directSetTemporalFreqHz1:(float)newTF;
{
    temporalFreqHz1 = newTF;
}

- (void)directSetTemporalPhaseDeg0:(float)newTPhase;
{
    temporalPhaseDeg0 = newTPhase;
}

- (void)directSetTemporalPhaseDeg1:(float)newTPhase;
{
    temporalPhaseDeg1 = newTPhase;
}

- (NSString *)description;
{
    return[NSString stringWithFormat:@"\n\tLLPlaid (0x%x): Az = %.1f, El = %.1f Rad = %.1f, Sig = %.1f, \n\
		   \tDir = %.1f Cont = %.2f\tSF = %.1f\n\
		   \tDir = %.1f Cont = %.2f\tSF = %.1f\n",
        (unsigned int)self, azimuthDeg, elevationDeg, radiusDeg, sigmaDeg, directionDeg0, contrast0, spatialFreqCPD0,
		   directionDeg1, contrast1, spatialFreqCPD1];
}

- (void)draw;
{
    [self updateCycleTextures];	
	[self drawCircularStencil];	
	[self drawTextures];
	[self loadPlaid:&lastPlaid];
}

// Redraw the stencil every time, because it might have been changed by other stim (e.g. LLGabor).

- (void)drawCircularStencil;
{
	if (displayListNum > 0 && radiusDeg == displayListPlaid.radiusDeg && azimuthDeg == displayListPlaid.azimuthDeg 
									&& elevationDeg == displayListPlaid.elevationDeg) {
			glCallList(displayListNum + kLLPlaidDrawCircle);	// use display list if valid one exists
		}
	else {
		[self drawCircularStencilGL];						// else draw in immediate mode
	}
}

/*
- (void)drawCircularStencil;
{
	long index;
	GLfloat projectionMatrix[16];
	BOOL projectionChanged = NO;
	
	glGetFloatv(GL_PROJECTION_MATRIX, projectionMatrix);
	for (index = 0; index < 16; index++) {						// has the projection changed?
		if (projectionMatrix[index] != lastProjectionMatrix[index]) {
			lastProjectionMatrix[index] = projectionMatrix[index];
			projectionChanged = YES;
		}
	}
	if (radiusDeg != lastPlaid.radiusDeg || elevationDeg != lastPlaid.elevationDeg
		|| azimuthDeg != lastPlaid.azimuthDeg || projectionChanged) {
		if (displayListNum > 0 && 
			radiusDeg == displayListPlaid.radiusDeg &&
			azimuthDeg == displayListPlaid.azimuthDeg &&
			elevationDeg == displayListPlaid.elevationDeg) {
			glCallList(displayListNum + kLLPlaidDrawCircle);	// use display list if valid one exists
		}
		else {
			[self drawCircularStencilGL];						// else draw in immediate mode
		}
	}
}
*/
- (void)drawCircularStencilGL;
{
	float limitedRadiusDeg = MIN(radiusDeg, radiusLimitSigma * sigmaDeg);

	glEnable(GL_STENCIL_TEST);
	glClearStencil(0x0);									// what value to clear the stencil to
	glClear(GL_STENCIL_BUFFER_BIT);							// clear the old stencil
	glStencilFunc(GL_ALWAYS, 0x1, 0x1);
	glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
	glPushMatrix();
	glTranslatef(azimuthDeg, elevationDeg, 0.0);
	glScalef(limitedRadiusDeg, limitedRadiusDeg, 0.0);
	glCallList(circleList);
	glPopMatrix();
	glDisable(GL_STENCIL_TEST);
}

- (void) drawTextures;
{
	BOOL noChanges;
	Plaid d;
	
	noChanges = radiusDeg == displayListPlaid.radiusDeg && sigmaDeg == displayListPlaid.sigmaDeg &&
						azimuthDeg == displayListPlaid.azimuthDeg && elevationDeg == displayListPlaid.elevationDeg;
	d = displayListPlaid;
	if (noChanges) {
			noChanges = noChanges && spatialFreqCPD0 == d.spatialFreqCPD0 && spatialFreqCPD1 == d.spatialFreqCPD1 &&
					spatialPhaseDeg0 == d.spatialPhaseDeg0 && spatialPhaseDeg1 == d.spatialPhaseDeg1 &&
					directionDeg0 == d.directionDeg0 && directionDeg1 == d.directionDeg1;
	}
	if (displayListNum > 0 && noChanges) {
		glCallList(displayListNum + kLLPlaidDrawTextures);			// use display list if valid one exists
	}
    else {
        [self drawTexturesGL];									// else draw in immediate mode
	}
}

- (void)drawTexturesGL;
{
    short i;
    float corner, texCorners[5], phases0[4], phases1[4], x, y;
	double sinRadius0, cosRadius0, phaseOffset0, sinRadius1, cosRadius1, phaseOffset1; 
    double radiusPeriods, directionRad, limitedRadiusDeg;
   
	limitedRadiusDeg = MIN(radiusDeg, radiusLimitSigma * sigmaDeg);

    radiusPeriods = limitedRadiusDeg * spatialFreqCPD0;
	directionRad = directionDeg0 * kRadiansPerDeg;
	sinRadius0 = radiusPeriods * sin(directionRad);
    cosRadius0 = radiusPeriods * cos(directionRad);
    phaseOffset0 = spatialPhaseDeg0 / 360.0;
 
    radiusPeriods = limitedRadiusDeg * spatialFreqCPD1;
	directionRad = directionDeg1 * kRadiansPerDeg;
	sinRadius1 = radiusPeriods * sin(directionRad);
    cosRadius1 = radiusPeriods * cos(directionRad);
    phaseOffset1 = spatialPhaseDeg1 / 360.0;

	// Map the 1D periodic cycle (sine, square, triangle) onto the corners of a square, creating a 2D grating
	
	corner = limitedRadiusDeg / sigmaDeg / (radiusLimitSigma * 2.0);
	for (i = 0; i < 4; i++) {					// vertices of the complete plaid
		x = (float)((i / 2) * 2 - 1);
		y = (float)((((i + 1) / 2) % 2) * 2 - 1);
		phases0[i] = phaseOffset0 + x * cosRadius0 + y * sinRadius0;    
		phases1[i] = phaseOffset1 + x * cosRadius1 + y * sinRadius1;    
		vertices[i * 2] = azimuthDeg + x * limitedRadiusDeg;
		vertices[i * 2 + 1] = elevationDeg + y * limitedRadiusDeg;
		vertices1[i * 2] = azimuthDeg + 4 + x * limitedRadiusDeg;
		vertices1[i * 2 + 1] = elevationDeg + 4+ y * limitedRadiusDeg;
        texCorners[i] = 0.5 + (((i % 4) / 2) * 2 - 1) * corner;
	}
	texCorners[4] = texCorners[0];

// Bind each texture to a texture unit

	glActiveTextureARB(GL_TEXTURE0_ARB);				// activate texture unit 0 and cycle texture 0
    glEnable(GL_TEXTURE_1D);						
    glBindTexture(GL_TEXTURE_1D, cycleTexture0);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE); // replace mode
	
    glActiveTextureARB(GL_TEXTURE1_ARB);				// activate texture unit 1 and cycle texture 1
    glEnable(GL_TEXTURE_1D);						
    glBindTexture(GL_TEXTURE_1D, cycleTexture1);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);	// decal mode
	
    glActiveTextureARB(GL_TEXTURE2_ARB);				// activate texture unit 2 and gaussian texture
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, plaidGaussianTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);   // decal mode
		
// Assign the vertex coordinate to each of the textures

 	glEnable(GL_STENCIL_TEST);
	glStencilFunc(GL_EQUAL, 0x1, 0x1);
	glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
  
	glBegin(GL_QUADS);
	for(i = 0; i < 4; i++) {
		glMultiTexCoord1f(GL_TEXTURE0_ARB, phases0[i]); 
		glMultiTexCoord1f(GL_TEXTURE1_ARB, phases1[i]); 
		glMultiTexCoord2fv(GL_TEXTURE2_ARB, &texCorners[i]);
		glVertex2fv(&vertices[i*2]);
	}
    glEnd();

// Clean up
	
	glActiveTextureARB(GL_TEXTURE2_ARB);
    glDisable(GL_TEXTURE_2D);
    glActiveTextureARB(GL_TEXTURE1_ARB);
    glDisable(GL_TEXTURE_1D);
    glActiveTextureARB(GL_TEXTURE0_ARB);		// Do texture unit 0 last, so we leave it active (for other tasks)
    glDisable(GL_TEXTURE_1D);
	glDisable(GL_STENCIL_TEST);
}

- (Plaid *)plaidData;
{
	[self loadPlaid:&plaid];
	return &plaid;
}

- (id)init;
{
	LLMultiplierTransformer *transformPC;
	GLuint	allTextures[3] = {};
	
    if ((self = [super init]) != nil) {

// Set the default values.  Do not use -set*, because that will overwrite the defaults settings.
// If we do this directly here, the value will be updated if there are default values.

		achromatic = YES;
		sigmaDeg = 2.0;
		radiusDeg = 6.0;
		contrast0 = contrast1 = 0.5;									// default plaid parameters
		directionDeg0 = 0;
		directionDeg1 = directionDeg0 + 0.0;
		spatialPhaseDeg0 = spatialPhaseDeg1 = 0.0;
		spatialFreqCPD0 = spatialFreqCPD1 = 0.5;
		temporalFreqHz0 = temporalFreqHz1 = 0.0;
		spatialModulation0 = spatialModulation1 = kLLPlaidSineModulation;
		temporalModulation0 = temporalModulation1 = kLLPlaidDrifting;
		temporalModulationParam0 = temporalModulationParam1 = kLLPlaidSPhase;
		kdlThetaDeg0 = kdlThetaDeg1 = 90.0;
		kdlPhiDeg0 = kdlPhiDeg1 = 0.0;

		radiusLimitSigma = kRadiusLimitSigma;
		
		displayListNum = 0;										// no display lists yet
		glClearColor(0.5, 0.5, 0.5, 1.0);						// set the background color
		glShadeModel(GL_FLAT);									// flat shading
		if (plaidNumTextureUnits == 0) {
			glGetIntegerv(GL_MAX_TEXTURE_UNITS, &plaidNumTextureUnits);
		}
		if (plaidNumTextureUnits < 3) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                   @"Need 3 texture units, only %d on this machine.  LLPlaid will not draw", plaidNumTextureUnits]];
//			NSRunAlertPanel(@"LLPlaid",  @"Need 3 texture units, only %d on this machine.  LLPlaid will not draw", @"OK",
//							nil, nil, plaidNumTextureUnits);
			[self release];
			return nil;
		}
		
// only need to generate textures once for all plaids

		if (!cycleTexture0) {
			glGenTextures(3, allTextures);
			cycleTexture0 = allTextures[0];
			cycleTexture1 = allTextures[1];
			plaidGaussianTexture = allTextures[2];
			[self makeCycleTextures];							// sine wave texture
			[self makeGaussianTexture];							// gaussian contrast profile
			[self makeCircle];									// circular limit (clipping region)
		}
	
// Provide convenient access to keys declared in LLVisualStimulus

		LLPlaidAzimuthDegKey = LLAzimuthDegKey;
		LLPlaidBackColorKey = LLBackColorKey;
		LLPlaidElevationDegKey = LLElevationDegKey;
		LLPlaidForeColorKey = LLForeColorKey;
		LLPlaidRadiusDegKey = LLRadiusDegKey;

		stimPrefix = @"Plaid";					// make our keys different from other LLVisualStimuli
		[keys addObjectsFromArray:[NSArray arrayWithObjects:LLPlaidAchromaticKey, LLPlaidSigmaDegKey, 
								   LLPlaid0ContrastKey, LLPlaid0DirectionDegKey, LLPlaid0SpatialFreqCPDKey, LLPlaid0SpatialModulationKey, 
								   LLPlaid0SpatialPhaseDegKey, LLPlaid0TemporalFreqHzKey, LLPlaid0TemporalModulationKey, 
								   LLPlaid0TemporalModulationParamKey, LLPlaid0TemporalPhaseDegKey, LLPlaid0KdlPhiDegKey, LLPlaid0KdlThetaDegKey,
								   LLPlaid1ContrastKey, LLPlaid1DirectionDegKey, LLPlaid1SpatialFreqCPDKey, LLPlaid1SpatialModulationKey, 
								   LLPlaid1SpatialPhaseDegKey, LLPlaid1TemporalFreqHzKey, LLPlaid1TemporalModulationKey, 
								   LLPlaid1TemporalModulationParamKey, LLPlaid1TemporalPhaseDegKey, LLPlaid1KdlPhiDegKey, LLPlaid1KdlThetaDegKey,
								   nil]];
		if (![NSValueTransformer valueTransformerForName:@"MultiplierTransformer"]) {
			transformPC = [[[LLMultiplierTransformer alloc] init] autorelease];;
			[transformPC setMultiplier:100.0];
			[NSValueTransformer setValueTransformer:transformPC forName:@"MultiplierTransformer"];
		}
		
// Observe whether our temporalModulation type changes
		
        [self addObserver:self forKeyPath:@"temporalModulation0"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:@"temporalModulation1"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
//		[self addObserver:self forKeyPath:@"temporalModulation1" options:0 context:nil];
	}
    return self; 
}

// Load a plaid structure with the current settings

- (void)loadPlaid:(Plaid *)pPlaid;
{
	pPlaid->azimuthDeg = azimuthDeg;								// Center of plaid 
	pPlaid->elevationDeg = elevationDeg;							// Center of plaid 
	pPlaid->radiusDeg = radiusDeg;									// Radius of drawing
	pPlaid->sigmaDeg = sigmaDeg;									// Plaid standard deviation
	pPlaid->contrast0 = contrast0;									// Contrast [0:1]
	pPlaid->contrast1 = contrast1;									// Contrast [0:1]
	pPlaid->directionDeg0 = directionDeg0;							// Direction
	pPlaid->directionDeg1 = directionDeg1;							// Direction
	pPlaid->kdlThetaDeg0 = kdlThetaDeg0;							// kdl space (deg)
	pPlaid->kdlThetaDeg1 = kdlThetaDeg1;							// kdl space (deg)
	pPlaid->kdlPhiDeg0 = kdlPhiDeg0;								// kdl space (deg)
	pPlaid->kdlPhiDeg1 = kdlPhiDeg1;								// kdl space (deg)
	pPlaid->spatialFreqCPD0 = spatialFreqCPD0;						// Spatial frequency
	pPlaid->spatialFreqCPD1 = spatialFreqCPD1;						// Spatial frequency
	pPlaid->spatialModulation0 = spatialModulation0;				// Spatial Modulation:component. SINE, SQUARE, TRIANGLE
	pPlaid->spatialModulation1 = spatialModulation1;				// Spatial Modulation:component. SINE, SQUARE, TRIANGLE
	pPlaid->spatialPhaseDeg0 = spatialPhaseDeg0;					// Spatial Phase
	pPlaid->spatialPhaseDeg1 = spatialPhaseDeg1;					// Spatial Phase
	pPlaid->temporalFreqHz0 = temporalFreqHz0;						// Temporal frequency
	pPlaid->temporalFreqHz1 = temporalFreqHz1;						// Temporal frequency
	pPlaid->temporalModulationParam0 = temporalModulationParam0;	// Parameter modulated in time
	pPlaid->temporalModulationParam1 = temporalModulationParam1;	// Parameter modulated in time
	pPlaid->temporalModulation0 = temporalModulation0;				// Temporal Modulation:basePlaid. COUNTERPHASE, DRIFTING
	pPlaid->temporalModulation1 = temporalModulation1;				// Temporal Modulation:basePlaid. COUNTERPHASE, DRIFTING
	pPlaid->temporalPhaseDeg0 = temporalPhaseDeg0;					// Temporal Phase		
	pPlaid->temporalPhaseDeg1 = temporalPhaseDeg1;					// Temporal Phase		
}

// Make a circular polygon that is used for stenciling.  It is this circular stencil that limits the radius of the
// plaid.

- (void)makeCircle;
{
	long index;
	long sections = 40;											//number of triangles to use to estimate a circle
	
	circleList = glGenLists(1);
	glNewList(circleList, GL_COMPILE);
	glBegin(GL_TRIANGLE_FAN);
	glVertex2f(0.0, 0.0);											// origin
	for (index = 0; index <= sections; index++) { 
		glVertex2f(cos(index * 2 * M_PI / sections), sin(index * 2 * M_PI / sections));
	}
	glEnd();
	glEndList();
}	

- (void)makeCycleTextures;
{
    short x, c;
    
    for (x = 0; x < kCyclePix; x++) {
        c = (GLubyte)(sin(k2PI / kCyclePix * x) * 127.0 + 127.0);
		sinImage[x][0] =sinImage[x][1] =sinImage[x][2] = (GLubyte)c;
		sinImage[x][3] = 127;								// alpha value
	}
    for (x = 0; x < kCyclePix; x++) {
		squareImage[x][0] = squareImage[x][1] = squareImage[x][2] = (x < kCyclePix / 2) ? 0 : 255;
		squareImage[x][3] = 127;								// alpha value
    }
    for (x = 0; x <= kCyclePix / 4; x++) {
        triImage[x][0] = triImage[kCyclePix / 2 - x][0] = (float)x / (kCyclePix / 4) * 127.0 + 127.0;
        triImage[x][1] = triImage[kCyclePix / 2 - x][1] = (float)x / (kCyclePix / 4) * 127.0 + 127.0;
        triImage[x][2] = triImage[kCyclePix / 2 - x][2] = (float)x / (kCyclePix / 4) * 127.0 + 127.0;
		triImage[x][3] = triImage[kCyclePix / 2 - x][3] = 127;								// alpha value
		triImage[kCyclePix / 2 + x][0] = triImage[kCyclePix / 2 + x][1] = triImage[kCyclePix / 2 + x][2] = 255 - triImage[x][0];
		triImage[kCyclePix / 2 + x][3] = 127;				// alpha value
        if (x > 0) {
			triImage[kCyclePix - x][0] = triImage[kCyclePix - x][1] = triImage[kCyclePix - x][2] = triImage[kCyclePix / 2 + x][0];
			triImage[kCyclePix - x][3] = 127;				// alpha value
		}
    }         
    glEnable(GL_TEXTURE_1D);
 
	glBindTexture(GL_TEXTURE_1D, cycleTexture0);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, kCyclePix, 0, GL_RGBA, GL_UNSIGNED_BYTE, sinImage);

    glBindTexture(GL_TEXTURE_1D, cycleTexture1);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, kCyclePix, 0, GL_RGBA, GL_UNSIGNED_BYTE, sinImage);

    glDisable(GL_TEXTURE_1D);     
}

- (void)makeDisplayLists;
{
	[self loadPlaid:&displayListPlaid];
    [self store];
    
// if no display lists then generate, otherwise overwrite

    if (displayListNum == 0) {
		displayListNum = glGenLists(kLLPlaidDrawTypes);
	}
    glNewList(displayListNum + kLLPlaidDrawColor, GL_COMPILE);				// compile drawlist for color
    [self updateCycleTexturesGL];
    glEndList();
    glNewList(displayListNum + kLLPlaidDrawTextures, GL_COMPILE);			// compile drawlist for textures
    [self drawTexturesGL];
    glEndList();
    glNewList(displayListNum + kLLPlaidDrawCircle, GL_COMPILE);			// compile drawlist for circle
    [self drawCircularStencilGL];
    glEndList();
}

// Make a Gaussian texture that will give the Gaussian contrast profile to the Plaid

- (void)makeGaussianTexture;
{
    GLfloat gaussianImage[kGaussianImagePix][kGaussianImagePix];
    long x, xc, y, halfWidth, squared, sigma, term1;
    short xside, yside;
    double g;
	
    halfWidth = kGaussianImagePix / 2;
	sigma = halfWidth / radiusLimitSigma;
	term1 = -2 * sigma * sigma;
	for (x = 0; x < halfWidth; x++) {
        for (xside = -1; xside < 2; xside += 2) {
            xc = halfWidth + x * xside;
            for (y = 0; y < halfWidth; y++) {
                squared = x * x + y * y;
                g = exp((double)squared / (double)term1);    
                for (yside = -1; yside < 2; yside += 2) {
                    gaussianImage[xc][halfWidth + y * yside] = 1 - g;
				}
            }
        }
        squared = halfWidth * halfWidth + x * x;		// clean up the edges
        g = exp((double)squared/(double)term1);
        for (xside = -1; xside < 2; xside += 2) {
            gaussianImage[0][halfWidth + x * xside] = 1 - g;
            gaussianImage[halfWidth + x * xside][0] = 1 - g;   
        }
    }
	glBindTexture(GL_TEXTURE_2D, plaidGaussianTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
	glPixelTransferf(GL_RED_BIAS, 0.5);
	glPixelTransferf(GL_GREEN_BIAS, 0.5);
	glPixelTransferf(GL_BLUE_BIAS, 0.5);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, kGaussianImagePix, kGaussianImagePix, 
	                 0, GL_ALPHA, GL_FLOAT, gaussianImage);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
//	long tempModulation;
//	
	if ([keyPath isEqualTo:@"temporalModulation0"]) {
		switch ([[change valueForKey:@"old"] intValue]) {
			case kLLPlaidCounterPhase:
				if ([[change valueForKey:@"new"] intValue] != kLLPlaidCounterPhase) {
					[self removeObserver:self forKeyPath:@"temporalModulation0"];	// don't observe during restore
//					tempModulation = temporalModulation1;							// don't restore other modulation
                    [self restore:0];
//					temporalModulation1 = tempModulation;							// don't restore other modulation
					temporalModulation0 = [[change valueForKey:@"new"] intValue];	// don't restore over new value
					[self addObserver:self forKeyPath:@"temporalModulation0"
							  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
				}
				break;
			case kLLPlaidDrifting:
			case kLLPlaidRandom:
			default:
				if ([[change valueForKey:@"new"] intValue] == kLLPlaidCounterPhase) {
                    [self store:0];
				}
				break;
		}
	}
	if ([keyPath isEqualTo:@"temporalModulation1"]) {
		switch ([[change valueForKey:@"old"] intValue]) {
			case kLLPlaidCounterPhase:
				if ([[change valueForKey:@"new"] intValue] != kLLPlaidCounterPhase) {
					[self removeObserver:self forKeyPath:@"temporalModulation1"];	// don't observe during restore
//					tempModulation = temporalModulation0;							// don't restore other modulation
                    [self restore:1];
//					temporalModulation0 = tempModulation;							// don't restore other modulation
					temporalModulation1 = [[change valueForKey:@"new"] intValue];	// don't restore over new value
					[self addObserver:self forKeyPath:@"temporalModulation1" 
							  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
				}
				break;
			case kLLPlaidDrifting:
			case kLLPlaidRandom:
			default:
				if ([[change valueForKey:@"new"] intValue] == kLLPlaidCounterPhase) {
                    [self store:1];
				}
				break;
		}
	}
}

- (void)restore;
{
	[self setPlaidData:basePlaid];
}

- (void)restore:(long)gratingNum;
{
    Plaid *pPlaid = &basePlaid;

    [self setAzimuthDeg:pPlaid->azimuthDeg];								// Center of plaid
    [self setElevationDeg:pPlaid->elevationDeg];							// Center of plaid
    [self setRadiusDeg:pPlaid->radiusDeg];                                  // Radius of drawing
    [self setSigmaDeg:pPlaid->sigmaDeg];									// Plaid	standard deviation
    switch (gratingNum) {
        case 0:
            [self setContrast0:pPlaid->contrast0];								// Contrast [0:1]
            [self setDirectionDeg0:pPlaid->directionDeg0];
            kdlThetaDeg0 = pPlaid->kdlThetaDeg0;
            kdlPhiDeg0 = pPlaid->kdlPhiDeg0;
            spatialFreqCPD0 = pPlaid->spatialFreqCPD0;
            [self setSpatialModulation0:pPlaid->spatialModulation0];
            [self setSpatialPhaseDeg0:pPlaid->spatialPhaseDeg0];					// Spatial Phase
            [self setTemporalFreqHz0:pPlaid->temporalFreqHz0];					// Temporal frequency
            [self setTemporalModulationParam0:pPlaid->temporalModulationParam0];	// Parameter modulated in time
            [self setTemporalModulation0:pPlaid->temporalModulation0];			// Temporal Modulation: COUNTERPHASE, DRIFTING
            [self setTemporalPhaseDeg0:pPlaid->temporalPhaseDeg0];				// Temporal Phase
            break;
        case 1:
            [self setContrast1:pPlaid->contrast1];								// Contrast [0:1]
            [self setDirectionDeg1:pPlaid->directionDeg1];
            kdlThetaDeg1 = pPlaid->kdlThetaDeg1;
            kdlPhiDeg1 = pPlaid->kdlPhiDeg1;
            spatialFreqCPD1 = pPlaid->spatialFreqCPD1;
            [self setSpatialModulation1:pPlaid->spatialModulation1];
            [self setSpatialPhaseDeg1:pPlaid->spatialPhaseDeg1];					// Spatial Phase
            [self setTemporalFreqHz1:pPlaid->temporalFreqHz1];					// Temporal frequency
            [self setTemporalModulationParam1:pPlaid->temporalModulationParam1];	// Parameter modulated in time
            [self setTemporalModulation1:pPlaid->temporalModulation1];			// Temporal Modulation: COUNTERPHASE, DRIFTING
            [self setTemporalPhaseDeg1:pPlaid->temporalPhaseDeg1];				// Temporal Phase
            break;
    }
}

- (void)runSettingsDialog;
{
	if (dialogWindow == nil) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"LLPlaid" owner:self topLevelObjects:&topLevelObjects];
        [topLevelObjects retain];
		if (taskPrefix != nil) {
			[dialogWindow setTitle:[NSString stringWithFormat:@"%@ Plaid", taskPrefix]];
		}
	}
	[dialogWindow makeKeyAndOrderFront:self];
}

- (void)setAchromatic:(BOOL)newState;
{
	static float oldKdlThetaDeg0, oldKdlThetaDeg1, oldKdlPhiDeg0, oldKdlPhiDeg1;
	
	if (newState & !achromatic) {
		achromatic = newState;
		oldKdlThetaDeg0 = kdlThetaDeg0;
		oldKdlThetaDeg1 = kdlThetaDeg1;
		oldKdlPhiDeg0 = kdlPhiDeg0;
		oldKdlPhiDeg1 = kdlPhiDeg1;
		kdlThetaDeg0 = kdlThetaDeg1 = 90.0;
		kdlPhiDeg = kdlPhiDeg1 = 0.0;
		[self updateIntegerDefault:achromatic key:LLPlaidAchromaticKey];
	}
	else if (!newState && achromatic) {
		achromatic = newState;
		kdlThetaDeg0 = oldKdlThetaDeg0;
		kdlThetaDeg1 = oldKdlThetaDeg1;
		kdlPhiDeg0 = oldKdlPhiDeg0;
		kdlPhiDeg1 = oldKdlPhiDeg1;
		[self setContrast0:contrast0];					// make sure we're within the chromatic limit
		[self setContrast1:contrast1];					// make sure we're within the chromatic limit
		[self updateIntegerDefault:achromatic key:LLPlaidAchromaticKey];
	}
}

- (void)setContrast0:(float)newContrast;
{
	contrast0 = MIN(newContrast, achromatic ? 1.0 : 1.0 / sqrt(2.0));
	[self updateFloatDefault:contrast0 key:LLPlaid0ContrastKey];
}

- (void)setContrast1:(float)newContrast;
{
	contrast1 = MIN(newContrast, achromatic ? 1.0 : 1.0 / sqrt(2.0));
	[self updateFloatDefault:contrast1 key:LLPlaid1ContrastKey];
}

- (void)setDirectionDeg0:(float)newDirection;
{
	directionDeg0 = newDirection;
	[self updateFloatDefault:directionDeg0 key:LLPlaid0DirectionDegKey];
}

- (void)setDirectionDeg1:(float)newDirection;
{
	directionDeg1 = newDirection;
	[self updateFloatDefault:directionDeg1 key:LLPlaid1DirectionDegKey];
}

// Advance the plaid one time interval (for counterphase, drifting, etc)

- (void)setFrame:(NSNumber *)frameNumber;
{
    long frame;
	float frameRateHz, framesPerHalfCycle, newPhaseDeg;
	
	frame = [frameNumber longValue];
	frameRateHz = (displays == nil) ? 60.0 : [displays frameRateHz:displayIndex];

	if (temporalFreqHz0 > 0.0 && frameRateHz > 0.0) {
		framesPerHalfCycle = frameRateHz / temporalFreqHz0 / 2.0;
		switch (temporalModulation0) {
			case kLLPlaidDrifting:
			case kLLPlaidRandom:
				if (temporalModulation0 == kLLPlaidRandom) {
					if ((frame % (long)ceil(framesPerHalfCycle)) > 0) {
						break;
					}
					else {
						newPhaseDeg = (rand() % 360);
					}
				}
				else {
					newPhaseDeg = (temporalPhaseDeg0 + frame / framesPerHalfCycle * 180.0);
				}
				newPhaseDeg -= floor(newPhaseDeg / 360.0) * 360.0;					// limit to first cycle
				switch (temporalModulationParam0) {
					case kLLPlaidDirection:
						[self setDirectionDeg0:newPhaseDeg];
						break;
					case kLLPlaidKdlTheta:
						kdlThetaDeg0 = newPhaseDeg;
						break;
					case kLLPlaidKdlPhi:
						kdlPhiDeg0 = newPhaseDeg;
						break;
					case kLLPlaidSPhase:
					default:
						spatialPhaseDeg0 = newPhaseDeg;
						break;
				}
				break;
				// 
				// NB: You must set the basePlaid values (using -store) before starting a counterphasing grating, and
				// you must restore the original contrast (using -restore) when you have finished the counterphasing.
				//				
			case kLLPlaidCounterPhase:
			default:
				contrast0 = (basePlaid.contrast0 *
							  sin(frame / framesPerHalfCycle * kPI + temporalPhaseDeg0 * kRadiansPerDeg));
				break;
		}
	}
	
	if (temporalFreqHz1 > 0.0 && frameRateHz > 0.0) {
		framesPerHalfCycle = frameRateHz / temporalFreqHz1 / 2.0;
		switch (temporalModulation1) {
			case kLLPlaidDrifting:
			case kLLPlaidRandom:
				if (temporalModulation1 == kLLPlaidRandom) {
					if ((frame % (long)ceil(framesPerHalfCycle)) > 0) {
						break;
					}
					else {
						newPhaseDeg = (rand() % 360);
					}
				}
				else {
					newPhaseDeg = (temporalPhaseDeg1 + frame / framesPerHalfCycle * 180.0);
				}
				newPhaseDeg -= floor(newPhaseDeg / 360.0) * 360.0;					// limit to first cycle
				switch (temporalModulationParam1) {
					case kLLPlaidDirection:
						[self setDirectionDeg1:newPhaseDeg];
						break;
					case kLLPlaidKdlTheta:
						kdlThetaDeg1 = newPhaseDeg;
						break;
					case kLLPlaidKdlPhi:
						kdlPhiDeg1 = newPhaseDeg;
						break;
					case kLLPlaidSPhase:
					default:
						spatialPhaseDeg1 = newPhaseDeg;
						break;
				}
				break;
				// 
				// NB: You must set the basePlaid values (using -store) before starting a counterphasing grating, and
				// you must restore the original contrast (using -restore) when you have finished the counterphasing.
				//				
			case kLLPlaidCounterPhase:
			default:
				contrast1 = (basePlaid.contrast1 *
							 sin(frame / framesPerHalfCycle * kPI + temporalPhaseDeg1 * kRadiansPerDeg));
				break;
		}
	}
	
}

- (void)setPlaidData:(Plaid)p;
{
	[self setAzimuthDeg:p.azimuthDeg];								// Center of plaid 
	[self setElevationDeg:p.elevationDeg];							// Center of plaid 
	[self setRadiusDeg:p.radiusDeg];								// Radius of drawing
	[self setSigmaDeg:p.sigmaDeg];									// Plaid	standard deviation
	[self setContrast0:p.contrast0];								// Contrast [0:1]
	[self setContrast1:p.contrast1];								// Contrast [0:1]
	[self setDirectionDeg0:p.directionDeg0];
	[self setDirectionDeg1:p.directionDeg1];
	kdlThetaDeg0 = p.kdlThetaDeg0;
	kdlThetaDeg1 = p.kdlThetaDeg1;
	kdlPhiDeg0 = p.kdlPhiDeg0;
	kdlPhiDeg1 = p.kdlPhiDeg1;
	spatialFreqCPD0 = p.spatialFreqCPD0;
	spatialFreqCPD1 = p.spatialFreqCPD1;
	[self setSpatialModulation0:p.spatialModulation0];
	[self setSpatialModulation1:p.spatialModulation1];
	[self setSpatialPhaseDeg0:p.spatialPhaseDeg0];					// Spatial Phase
	[self setSpatialPhaseDeg1:p.spatialPhaseDeg1];					// Spatial Phase
	[self setTemporalFreqHz0:p.temporalFreqHz0];					// Temporal frequency
	[self setTemporalFreqHz1:p.temporalFreqHz1];					// Temporal frequency
	[self setTemporalModulationParam0:p.temporalModulationParam0];	// Parameter modulated in time
	[self setTemporalModulationParam1:p.temporalModulationParam1];	// Parameter modulated in time
	[self setTemporalModulation0:p.temporalModulation0];			// Temporal Modulation: COUNTERPHASE, DRIFTING
	[self setTemporalModulation1:p.temporalModulation1];			// Temporal Modulation: COUNTERPHASE, DRIFTING
	[self setTemporalPhaseDeg0:p.temporalPhaseDeg0];				// Temporal Phase
	[self setTemporalPhaseDeg1:p.temporalPhaseDeg1];				// Temporal Phase
}

- (void)setRadiusLimitSigma:(float)newLimit;
{
	radiusLimitSigma = newLimit;
	[self makeGaussianTexture];
}

- (void)setSpatialFreqCPD0:(float)newSF;
{
    spatialFreqCPD0 = newSF;
	[self updateFloatDefault:spatialFreqCPD0 key:LLPlaid0SpatialFreqCPDKey];
}

- (void)setSpatialFreqCPD1:(float)newSF;
{
    spatialFreqCPD1 = newSF;
	[self updateFloatDefault:spatialFreqCPD1 key:LLPlaid1SpatialFreqCPDKey];
}

- (void)setSigmaDeg:(float)newSigma;
{
    sigmaDeg = newSigma;
	[self updateFloatDefault:sigmaDeg key:LLPlaidSigmaDegKey];
}

- (void)setSpatialPhaseDeg0:(float)newSPhase;
{
    spatialPhaseDeg0 = newSPhase;
	[self updateFloatDefault:spatialPhaseDeg0 key:LLPlaid0SpatialPhaseDegKey];
}

- (void)setSpatialPhaseDeg1:(float)newSPhase;
{
    spatialPhaseDeg1 = newSPhase;
	[self updateFloatDefault:spatialPhaseDeg1 key:LLPlaid1SpatialPhaseDegKey];
}

- (void)setSpatialModulation0:(long)newSMod;
{
    spatialModulation0 = newSMod;
	[self updateIntegerDefault:spatialModulation0 key:LLPlaid0SpatialModulationKey];
}

- (void)setSpatialModulation1:(long)newSMod;
{
    spatialModulation1 = newSMod;
	[self updateIntegerDefault:spatialModulation1 key:LLPlaid1SpatialModulationKey];
}

- (void)setTemporalFreqHz0:(float)newTF;
{
	temporalFreqHz0 = newTF;
	[self updateFloatDefault:temporalFreqHz0 key:LLPlaid0TemporalFreqHzKey];
}

- (void)setTemporalFreqHz1:(float)newTF;
{
	temporalFreqHz1 = newTF;
	[self updateFloatDefault:temporalFreqHz1 key:LLPlaid1TemporalFreqHzKey];
}

- (void)setTemporalModulation0:(long)newTMod;
{
    temporalModulation0 = newTMod;
	[self updateIntegerDefault:temporalModulation0 key:LLPlaid0TemporalModulationKey];
}

- (void)setTemporalModulation1:(long)newTMod;
{
    temporalModulation1 = newTMod;
	[self updateIntegerDefault:temporalModulation1 key:LLPlaid1TemporalModulationKey];
}

- (void)setTemporalModulationParam0:(long)newTParam;
{
    temporalModulationParam0 = newTParam;
	[self updateIntegerDefault:temporalModulationParam0 key:LLPlaid0TemporalModulationParamKey];
}

- (void)setTemporalModulationParam1:(long)newTParam;
{
    temporalModulationParam1 = newTParam;
	[self updateIntegerDefault:temporalModulationParam1 key:LLPlaid1TemporalModulationParamKey];
}

- (void)setTemporalPhaseDeg0:(float)newTPhase;
{
	temporalPhaseDeg0 = newTPhase;
	[self updateFloatDefault:temporalPhaseDeg0 key:LLPlaid0TemporalPhaseDegKey];
}

- (void)setTemporalPhaseDeg1:(float)newTPhase;
{
	temporalPhaseDeg1 = newTPhase;
	[self updateFloatDefault:temporalPhaseDeg1 key:LLPlaid1TemporalPhaseDegKey];
}

- (float)spatialFreqCPD0;
{
	return spatialFreqCPD0;
}

- (float)spatialFreqCPD1;
{
	return spatialFreqCPD1;
}

- (float)sigmaDeg;
{
	return sigmaDeg;
}

- (void)store;
{
    [self loadPlaid:&basePlaid];
}

- (void)store:(long)gratingNum;
{
    Plaid *pPlaid = &basePlaid;
    
    pPlaid->azimuthDeg = azimuthDeg;								// Center of plaid
    pPlaid->elevationDeg = elevationDeg;							// Center of plaid
    pPlaid->radiusDeg = radiusDeg;									// Radius of drawing
    pPlaid->sigmaDeg = sigmaDeg;									// Plaid standard deviation
    switch (gratingNum) {
        case 0:
            pPlaid->contrast0 = contrast0;									// Contrast [0:1]
            pPlaid->directionDeg0 = directionDeg0;							// Direction
            pPlaid->kdlThetaDeg0 = kdlThetaDeg0;							// kdl space (deg)
            pPlaid->kdlPhiDeg0 = kdlPhiDeg0;								// kdl space (deg)
            pPlaid->spatialFreqCPD0 = spatialFreqCPD0;						// Spatial frequency
            pPlaid->spatialModulation0 = spatialModulation0;				// Spatial Modulation:component. SINE, SQUARE, TRIANGLE
            pPlaid->spatialPhaseDeg0 = spatialPhaseDeg0;					// Spatial Phase
            pPlaid->temporalFreqHz0 = temporalFreqHz0;						// Temporal frequency
            pPlaid->temporalModulationParam0 = temporalModulationParam0;	// Parameter modulated in time
            pPlaid->temporalModulation0 = temporalModulation0;				// Temporal Modulation:basePlaid. COUNTERPHASE, DRIFTING
            pPlaid->temporalPhaseDeg0 = temporalPhaseDeg0;					// Temporal Phase
            break;
        case 1:
            pPlaid->contrast1 = contrast1;									// Contrast [0:1]
            pPlaid->directionDeg1 = directionDeg1;							// Direction
            pPlaid->kdlThetaDeg1 = kdlThetaDeg1;							// kdl space (deg)
            pPlaid->kdlPhiDeg1 = kdlPhiDeg1;								// kdl space (deg)
            pPlaid->spatialFreqCPD1 = spatialFreqCPD1;						// Spatial frequency
            pPlaid->spatialModulation1 = spatialModulation1;				// Spatial Modulation:component. SINE, SQUARE, TRIANGLE
            pPlaid->spatialPhaseDeg1 = spatialPhaseDeg1;					// Spatial Phase
            pPlaid->temporalFreqHz1 = temporalFreqHz1;						// Temporal frequency
            pPlaid->temporalModulationParam1 = temporalModulationParam1;	// Parameter modulated in time
            pPlaid->temporalModulation1 = temporalModulation1;				// Temporal Modulation:basePlaid. COUNTERPHASE, DRIFTING
            pPlaid->temporalPhaseDeg1 = temporalPhaseDeg1;					// Temporal Phase
           break;
    }
}

// Prepare the cycle textures for drawing.  If there has been no significant change from the last time we drew,
// then no change is needed.  If there has been a change, update the textures using a display list, if nothing 
// significant has changed from when the display list was made.  Otherwise, execute all the steps to update the
// cycle textures, using updateCycleTextureGL;
	
- (void)updateCycleTextures;
{	
	if (contrast0 == lastPlaid.contrast0 && kdlThetaDeg0 == lastPlaid.kdlThetaDeg0 && 
				kdlPhiDeg0 == lastPlaid.kdlPhiDeg0 && spatialModulation0 == lastPlaid.spatialModulation0 &&
				contrast1 == lastPlaid.contrast1 && kdlThetaDeg1 == lastPlaid.kdlThetaDeg1 && 
				kdlPhiDeg1 == lastPlaid.kdlPhiDeg1 && spatialModulation1 == lastPlaid.spatialModulation1) {
		return;
	}
		
	if (displayListNum && contrast0 == displayListPlaid.contrast0 && kdlThetaDeg0 == displayListPlaid.kdlThetaDeg0 &&
			kdlPhiDeg0 == displayListPlaid.kdlPhiDeg0 && spatialModulation0 == displayListPlaid.spatialModulation0 &&
			contrast1 == displayListPlaid.contrast1 && kdlThetaDeg1 == displayListPlaid.kdlThetaDeg1 &&
			kdlPhiDeg1 == displayListPlaid.kdlPhiDeg1 && spatialModulation1 == displayListPlaid.spatialModulation1) {
		glCallList(displayListNum + kLLPlaidDrawColor);					// use display list if valid one exists
	}
	else {
		[self updateCycleTexturesGL];								// else draw in immediate mode
	}
}

- (void)updateCycleTexturesGL;
{
	long index;
    RGBDouble rgb;
	long spatialModulation[kComponents] = {spatialModulation0, spatialModulation1};
	GLuint cycleTexture[kComponents] = {cycleTexture0, cycleTexture1};
	float contrast[kComponents] = {contrast0, contrast1};
	float kdlTheta[kComponents] = {kdlThetaDeg0, kdlThetaDeg1};
	float kdlPhi[kComponents] = {kdlPhiDeg0, kdlPhiDeg1};
	
	if (displays == nil) {
		return;
	}	
	glEnable(GL_TEXTURE_1D);
	for (index = 0; index < kComponents; index++) {
		if (achromatic) {
			rgb.red = rgb.green = rgb.blue = contrast[index];
		}
		else {
			rgb = [displays RGB:displayIndex kdlTheta:kdlTheta[index] kdlPhi:kdlPhi[index]];
			rgb.red *= contrast[index];
			rgb.green *= contrast[index];
			rgb.blue *= contrast[index];
		}
		
// convert RGBColor [-1 1] to OpenGL RGB [0 1].  Because we are going to use the GL_BLEND mode to combine the two
// grating patterns, we give each an offset of 0.25, so that the summed offset is mid-level gray (0.5).  Note that
// we do nothing about clipping when the grating add -- users need to keep the contrast sum below 1.0 (e.g., 50% each).
		
		glBindTexture(GL_TEXTURE_1D, cycleTexture[index]);	
		glPixelTransferf(GL_RED_BIAS, 0.5 - rgb.red / 2.0);
		glPixelTransferf(GL_GREEN_BIAS, 0.5 - rgb.green / 2.0);
		glPixelTransferf(GL_BLUE_BIAS, 0.5 - rgb.blue / 2.0);
		glPixelTransferf(GL_RED_SCALE, rgb.red);
		glPixelTransferf(GL_GREEN_SCALE, rgb.green);
		glPixelTransferf(GL_BLUE_SCALE, rgb.blue);
		switch (spatialModulation[index]) { 
			case kLLPlaidSquareModulation:
				glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_RGBA, GL_UNSIGNED_BYTE, squareImage);
				break;
			case kLLPlaidTriangleModulation:
				glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_RGBA, GL_UNSIGNED_BYTE, triImage);
				break;
			case kLLPlaidSineModulation:
			default:
				glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_RGBA, GL_UNSIGNED_BYTE, sinImage);
				break;
		}   
	}
	glDisable(GL_TEXTURE_1D);   
}

@end

