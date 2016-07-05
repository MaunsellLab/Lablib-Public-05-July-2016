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

#define glMultiTexCoord2f	glMultiTexCoord2fARB
#define glMultiTexCoord2fv	glMultiTexCoord2fvARB
#define glActiveTexture		glActiveTextureARB
#define kCyclePix			256						// must be a power of 2
#define kGaussianImagePix   256						// must be a power of 2

// The following are declared as class variables, because the same textures can be used to 
// draw all the instances of LLPlaid.  lastPlaid keeps track of the texture variables
// of the last Plaid that was drawn.  displayListPlaid keeps track of the variables
// that were used to make the display lists.

static GLuint	circleList;
GLuint			cycleTexture = nil;
GLuint			gaussianTexture = nil;
Plaid			lastPlaid = {};
static GLfloat	lastProjectionMatrix[16];
GLint			numTextureUnits = 0;
static GLubyte	sinImage[kCyclePix];
static GLubyte	triImage[kCyclePix];
static GLubyte	squareImage[kCyclePix];

NSString *LLPlaidAzimuthDegKey;
NSString *LLPlaidBackColorKey;
NSString *LLPlaidDirectionDegKey;
NSString *LLPlaidElevationDegKey;
NSString *LLPlaidForeColorKey;
NSString *LLPlaidKdlThetaDegKey;
NSString *LLPlaidKdlPhiDegKey;
NSString *LLPlaidRadiusDegKey;

NSString *LLPlaid0ContrastKey = @"contrast0";
NSString *LLPlaid0SpatialFreqCPDKey = @"spatialFreqCPD0";
NSString *LLPlaid0SpatialModulationKey = @"spatialModulation0";
NSString *LLPlaid0SpatialPhaseDegKey = @"spatialPhaseDeg0";
NSString *LLPlaid0TemporalFreqHzKey = @"temporalFreqHz0";
NSString *LLPlaid0TemporalModulationParamKey = @"temporalModulationParam0";
NSString *LLPlaid0TemporalModulationKey = @"temporalModulation0";
NSString *LLPlaid0TemporalPhaseDegKey = @"temporalPhaseDeg0";

NSString *LLPlaid1ContrastKey = @"contrast1";
NSString *LLPlaid1SpatialFreqCPDKey = @"spatialFreqCPD1";
NSString *LLPlaid1SpatialModulationKey = @"spatialModulation1";
NSString *LLPlaid1SpatialPhaseDegKey = @"spatialPhaseDeg1";
NSString *LLPlaid1TemporalFreqHzKey = @"temporalFreqHz1";
NSString *LLPlaid1TemporalModulationParamKey = @"temporalModulationParam1";
NSString *LLPlaid1TemporalModulationKey = @"temporalModulation1";
NSString *LLPlaid1TemporalPhaseDegKey = @"temporalPhaseDeg1";

NSString *LLPlaidAchromaticKey = @"achromatic";
NSString *LLPlaidSigmaDegKey = @"sigmaDeg";
NSString *LLPlaidSpatialPhaseDegKey = @"spatialPhaseDeg";

LLDataDef LLPlaidComponentEventDesc[] = {
	{@"float", @"contrast", 1, offsetof(PlaidComponent, contrast)},
	{@"float", @"directionDeg", 1, offsetof(PlaidComponent, directionDeg)},
	{@"float", @"kdlThetaDeg", 1, offsetof(PlaidComponent, kdlThetaDeg)},
	{@"float", @"kdlPhiDeg", 1, offsetof(PlaidComponent, kdlPhiDeg)},
	{@"float", @"spatialFreqCPD", 1, offsetof(PlaidComponent, spatialFreqCPD)},
	{@"long", @"spatialModulation", 1, offsetof(PlaidComponent, spatialModulation)},
	{@"float", @"spatialPhaseDeg", 1, offsetof(PlaidComponent, spatialPhaseDeg)},
	{@"float", @"temporalFreqHz", 1, offsetof(PlaidComponent, temporalFreqHz)},
	{@"long", @"temporalModulation", 1, offsetof(PlaidComponent, temporalModulation)},
	{@"long", @"temporalModulationParam", 1, offsetof(PlaidComponent, temporalModulationParam)},
	{@"float", @"temporalPhaseDeg", 1, offsetof(PlaidComponent, temporalPhaseDeg)},
	{nil}
};

LLDataDef kLLPlaidEventDesc[] = {
	{@"float", @"azimuthDeg", 1, offsetof(Plaid, azimuthDeg)},
	{@"float", @"elevationDeg", 1, offsetof(Plaid, elevationDeg)},
	{@"float", @"radiusDeg", 1, offsetof(Plaid, radiusDeg)},
	{@"float", @"sigmaDeg", 1, offsetof(Plaid, sigmaDeg)},
	{@"struct", @"components", 2, offsetof(Plaid, components), sizeof(PlaidComponent), LLPlaidComponentEventDesc},
	{nil}
};

@implementation LLPlaid

+ (LLDataDef *)LLPlaidEventDesc;
{
	return LLPlaidComponentEventDesc;
}

- (float *)contrasts;
{
	static float contrasts[kComponents];
	
	contrasts[0] = components[0].contrast;
	contrasts[1] = components[1].contrast;
	return contrasts;
}
- (float)contrast1;
{
	return components[1].contrast;
}

- (void)dealloc;
{
    if (displayListNum > 0) {
        glDeleteLists(displayListNum, kLLPlaidDrawCircle + 1);
	}
	[super dealloc];					// super will take care of unbinding keys, if needed
}

- (void)directSetContrasts:(float *)newContrasts;
{
	components[0].contrast = MIN(newContrasts[0], achromatic ? 1.0 : 1.0 / sqrt(2.0));
	components[1].contrast = MIN(newContrasts[1], achromatic ? 1.0 : 1.0 / sqrt(2.0));
}

// Do setFrame without being key-value compliant.  Changes will not be reflected by observers (defaults, dialog, etc).
// This runs faster than setFrame because no observers are notified of changes to the plaid values.

- (void)directSetFrame:(NSNumber *)frameNumber;
{
    long  c, cycles, frame;
	float frameRateHz, framesPerHalfCycle;
    float *currentPhase;
	PlaidComponent comp;
		
	frame = [frameNumber longValue];
	frameRateHz = (displays == nil) ? 60.0 : [displays frameRateHz:displayIndex];
	for (c = 0; c < kComponents; c++) {
		comp = components[c];
		currentPhase = &comp.spatialPhaseDeg;
		if (comp.temporalFreqHz > 0.0 && frameRateHz > 0.0) {
			framesPerHalfCycle = frameRateHz / comp.temporalFreqHz / 2.0;
			switch (comp.temporalModulationParam) {
				case kLLPlaidDirection:
					currentPhase = &comp.directionDeg;
					break;
				case kLLPlaidKdlTheta:
					currentPhase = &comp.kdlThetaDeg;
					break;
				case kLLPlaidKdlPhi:
					currentPhase = &comp.kdlPhiDeg;
					break;
				case kLLPlaidSPhase:
				default:
					currentPhase = &comp.spatialPhaseDeg;
					break;
			}
			switch (comp.temporalModulation) {
				case kLLPlaidDrifting:
					*currentPhase = comp.temporalPhaseDeg + frame / framesPerHalfCycle * 180.0;
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
					comp.contrast = basePlaid.components[c].contrast *
								sin(frame / framesPerHalfCycle * kPI + comp.temporalPhaseDeg * kRadiansPerDeg);
					break;
			}
		}
		cycles = floor(*currentPhase / 360.0);
		*currentPhase -= cycles * 360.0;
	}
}

- (void)directSetSigmaDeg:(float)newSigma;
{
    sigmaDeg = newSigma;
}

- (void)directSetSpatialFreqsCPD:(float *)newSFs;
{
    components[0].spatialFreqCPD = newSFs[0];
    components[1].spatialFreqCPD = newSFs[1];
}


- (void)directSetSpatialPhasesDeg:(float *)newSPhases;
{
    components[0].spatialPhaseDeg = newSPhases[0];
    components[1].spatialPhaseDeg = newSPhases[1];
}

- (void)directSetTemporalFreqsHz:(float *)newTFs;
{
    components[0].temporalFreqHz = newTFs[0];
    components[1].temporalFreqHz = newTFs[1];
}

- (void)directSetTemporalPhasesDeg:(float *)newTPhases;
{
    components[0].temporalPhaseDeg = newTPhases[0];
    components[1].temporalPhaseDeg = newTPhases[1];
}

- (NSString *)description;
{
    return[NSString stringWithFormat:@"\n\tLLPlaid (0x%x): Az = %.1f, El = %.1 fRad = %.1f, Sig = %.1f, \n\
		   \tDir = %.1f Cont = %.2f\tSF = %.1f\n\
		   \tDir = %.1f Cont = %.2f\tSF = %.1f\n",
        self, azimuthDeg, elevationDeg, radiusDeg, sigmaDeg, 
		   components[0].directionDeg, components[0].contrast, components[0].spatialFreqCPD, 
		   components[1].directionDeg, components[1].contrast, components[1].spatialFreqCPD];
}

- (void)draw;
{
    [self updateCycleTexture];
	[self drawCircularStencil];
	[self drawTextures];
	[self loadPlaid:&lastPlaid];
}

// if the stencil has changed, redraw it

- (void)drawCircularStencil;
{
	long index;
	GLfloat projectionMatrix[16];
	BOOL projectionChanged = NO;
	
	glGetFloatv(GL_PROJECTION_MATRIX, projectionMatrix);
	for (index = 0; index < 16; index++) {
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
			glCallList(displayListNum + kLLPlaidDrawCircle);		// use display list if valid one exists
		}
		else {
			[self drawCircularStencilGL];					// else draw in immediate mode
		}
	}
}

- (void)drawCircularStencilGL;
{
	float limitedRadiusDeg = MIN(radiusDeg, kRadiusLimitSigma * sigmaDeg);

	glEnable(GL_STENCIL_TEST);
	glClearStencil(0x0);									// what value to clear to
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
	long index;
	BOOL noChanges;
	PlaidComponent c, d;
	
	noChanges = radiusDeg == displayListPlaid.radiusDeg && sigmaDeg == displayListPlaid.sigmaDeg &&
						azimuthDeg == displayListPlaid.azimuthDeg && elevationDeg == displayListPlaid.elevationDeg;
	if (noChanges) {
		for (index = 0; index < kComponents; index++) {
			c = components[index];
			d = displayListPlaid.components[index];
			noChanges = noChanges && c.spatialFreqCPD == d.spatialFreqCPD &&
					c.spatialPhaseDeg == d.spatialPhaseDeg &&
					c.directionDeg == d.directionDeg;
		}
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
    float corner, texCorners[5], phases[4], x, y;
    double radiusPeriods, sinRadius, cosRadius, phaseOffset, directionRad, limitedRadiusDeg;
     
	limitedRadiusDeg = MIN(radiusDeg, kRadiusLimitSigma * sigmaDeg);
    radiusPeriods = limitedRadiusDeg * components[0].spatialFreqCPD;
	directionRad = directionDeg * kRadiansPerDeg;
	sinRadius = radiusPeriods * sin(directionRad);
    cosRadius = radiusPeriods * cos(directionRad);
    phaseOffset = components[0].spatialPhaseDeg / 360.0;
 
// Map the 1D periodic cycle (sine, square, triangle) onto the corners of a square, creating a 2D grating
	
	corner = limitedRadiusDeg / sigmaDeg / (kRadiusLimitSigma * 2.00);
	for (i = 0; i < 4; i++) {					// vertices of the complete plaid
		x = (float)((i / 2) * 2 - 1);
		y = (float)((((i + 1) / 2) % 2) * 2 - 1);
		vertices[i * 2] = azimuthDeg + x * limitedRadiusDeg;
		vertices[i * 2 + 1] = elevationDeg + y * limitedRadiusDeg;
		phases[i] = phaseOffset + x * cosRadius + y * sinRadius;    
        texCorners[i] = 0.5 + (((i % 4) / 2) * 2 - 1) * corner;
	}
	texCorners[4] = texCorners[0];

// Bind each texture to a texture unit

    glActiveTexture(GL_TEXTURE0_ARB);				// activate texture unit 0 and cycle texture 
    glEnable(GL_TEXTURE_1D);						
    glBindTexture(GL_TEXTURE_1D, cycleTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE); // replace mode

    glActiveTexture(GL_TEXTURE1_ARB);				// activate texture unit 1 and gaussian texture
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, gaussianTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);   // decal mode
		
// Assign the vertex coordinate to each of the textures

 	glEnable(GL_STENCIL_TEST);
	glStencilFunc(GL_EQUAL, 0x1, 0x1);
	glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
  
    glBegin(GL_QUADS);
	for(i = 0; i < 4; i++) {
		glMultiTexCoord1f(GL_TEXTURE0_ARB, phases[i]); 
		glMultiTexCoord2fv(GL_TEXTURE1_ARB, &texCorners[i]);
		glVertex2fv(&vertices[i*2]);
	}
    glEnd();

// Clean up
	
	glActiveTexture(GL_TEXTURE1_ARB);
    glDisable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE0_ARB);		// Do texture unit 0 last, so we leave it active (for other tasks)
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
	long index;
	LLMultiplierTransformer *transformPC;
	GLuint	allTextures[3] = {};
	PlaidComponent c;
	
    if ((self = [super init]) != nil) {

// Set the default values.  Do not use -set*, because that will overwrite the defaults settings.
// If we do this directly here, the value will be updated if there are default values.

		achromatic = YES;
		sigmaDeg = 0.5;
		radiusDeg = 1.5;
		for (index = 0; index < kComponents; index++) {
			c = components[index];
			c.contrast = 1.0;									// default plaid parameters
			c.directionDeg = 45.0;
			c.spatialPhaseDeg = 0.0;
			c.spatialFreqCPD = 1.0;
			c.temporalFreqHz = 0.0;
			c.spatialModulation = kLLPlaidSineModulation;
			c.temporalModulation = kLLPlaidDrifting;
			c.temporalModulationParam = kLLPlaidSPhase;
			c.kdlThetaDeg = 90.0;
			c.kdlPhiDeg = 0.0;
		}
		displayListNum = 0;										// no display lists yet
		glClearColor(0.5, 0.5, 0.5, 1.0);						// set the background color
		glShadeModel(GL_FLAT);									// flat shading
		if (numTextureUnits == 0) {
			glGetIntegerv(GL_MAX_TEXTURE_UNITS, &numTextureUnits);
		}
		
// only need to generate textures once for all plaids

		if (!cycleTexture) {
			glGenTextures(2, allTextures);
			cycleTexture = allTextures[0];
			gaussianTexture = allTextures[1];
			[self makeCycleTexture];							// sine wave texture
			[self makeGaussianTexture];							// gaussian contrast profile
			[self makeCircle];									// circular limit (clipping region)
		}
	
// Provide convenient access to keys declared in LLVisualStimulus

		LLPlaidAzimuthDegKey = LLAzimuthDegKey;
		LLPlaidBackColorKey = LLBackColorKey;
		LLPlaidDirectionDegKey = LLDirectionDegKey;
		LLPlaidElevationDegKey = LLElevationDegKey;
		LLPlaidForeColorKey = LLForeColorKey;
		LLPlaidKdlThetaDegKey = LLKdlThetaDegKey;
		LLPlaidKdlPhiDegKey = LLKdlPhiDegKey;
		LLPlaidRadiusDegKey = LLRadiusDegKey;

		stimPrefix = @"Plaid";					// make our keys different from other LLVisualStimuli
		[keys addObjectsFromArray:[NSArray arrayWithObjects:LLPlaidAchromaticKey, LLPlaidSigmaDegKey, 
								   LLPlaid0ContrastKey, LLPlaid0SpatialFreqCPDKey, LLPlaid0SpatialModulationKey, 
								   LLPlaid0SpatialPhaseDegKey, LLPlaid0TemporalFreqHzKey, LLPlaid0TemporalModulationKey, 
								   LLPlaid0TemporalModulationParamKey, LLPlaid0TemporalPhaseDegKey, 
								   LLPlaid1ContrastKey, LLPlaid1SpatialFreqCPDKey, LLPlaid1SpatialModulationKey, 
								   LLPlaid1SpatialPhaseDegKey, LLPlaid1TemporalFreqHzKey, LLPlaid1TemporalModulationKey, 
								   LLPlaid1TemporalModulationParamKey, LLPlaid1TemporalPhaseDegKey, 
								   nil]];
		if (![NSValueTransformer valueTransformerForName:@"MultiplierTransformer"]) {
			transformPC = [[[LLMultiplierTransformer alloc] init] autorelease];;
			[transformPC setMultiplier:100.0];
			[NSValueTransformer setValueTransformer:transformPC forName:@"MultiplierTransformer"];
		}
	}
    return self; 
}

// Load a plaid structure with the current settings

- (void)loadPlaid:(Plaid *)pPlaid;
{
	long index;
	PlaidComponent c, outComp;
	
	pPlaid->azimuthDeg = azimuthDeg;							// Center of plaid 
	pPlaid->elevationDeg = elevationDeg;						// Center of plaid 
	pPlaid->radiusDeg = radiusDeg;								// Radius of drawing
	pPlaid->sigmaDeg = sigmaDeg;								// Plaid standard deviation
	for (index = 0; index < kComponents; index++) {
		outComp = pPlaid->components[index];
		c = components[index];
		outComp.contrast = c.contrast;									// Contrast [0:pPlaid->1]
		outComp.directionDeg = c.directionDeg;							// Direction
		outComp.kdlThetaDeg = c.kdlThetaDeg;							// kdl space (deg)
		outComp.kdlPhiDeg = c.kdlPhiDeg;								// kdl space (deg)
		outComp.spatialFreqCPD = c.spatialFreqCPD;						// Spatial frequency
		outComp.spatialModulation = c.spatialModulation;				// Spatial Modulation:component. SINE, SQUARE, TRIANGLE
		outComp.spatialPhaseDeg = c.spatialPhaseDeg;					// Spatial Phase
		outComp.temporalFreqHz = c.temporalFreqHz;						// Temporal frequency
		outComp.temporalModulationParam = c.temporalModulationParam;	// Parameter modulated in time
		outComp.temporalModulation = c.temporalModulation;				// Temporal Modulation:basePlaid. COUNTERPHASE, DRIFTING
		outComp.temporalPhaseDeg = c.temporalPhaseDeg;					// Temporal Phase		
	}
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

- (void) makeCycleTexture;
{
    short x, c;
    
    for (x = 0; x < kCyclePix; x++) {
        c = (GLubyte)(sin(k2PI / kCyclePix * x) * 127.0 + 127.0);
		sinImage[x] = (GLubyte)c;
	}
    for (x = 0; x < kCyclePix; x++) {
        if (x < kCyclePix / 2) {
            squareImage[x] = 0;
        }
        else {
            squareImage[x] = 255;
		}
    }
    for (x = 0; x <= kCyclePix / 4; x++) {
        triImage[x] = triImage[kCyclePix / 2 - x] = (float)x / (kCyclePix / 4) * 127.0 + 127.0;
        triImage[kCyclePix / 2 + x] = 255 - triImage[x];
        if (x > 0) {
			triImage[kCyclePix - x] = triImage[kCyclePix / 2 + x];
		}
    }         
    glEnable(GL_TEXTURE_1D);							// had this enable/disable commented out 050617
    glBindTexture(GL_TEXTURE_1D, cycleTexture);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexImage1D(GL_TEXTURE_1D, 0, GL_RGB, kCyclePix, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, sinImage);
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
//	circleMask = (radiusDeg < kRadiusLimitSigma * sigmaDeg);
    glNewList(displayListNum + kLLPlaidDrawColor, GL_COMPILE);				// compile drawlist for color
    [self updateCycleTextureGL];
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
	sigma = halfWidth / kRadiusLimitSigma;
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
	glBindTexture(GL_TEXTURE_2D, gaussianTexture);
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

- (void)restore;
{
	[self setPlaidData:basePlaid];
}

- (void)runSettingsDialog;
{
	if (dialogWindow == nil) {
		[NSBundle loadNibNamed:@"LLPlaid" owner:self];
		if (taskPrefix != nil) {
			[dialogWindow setTitle:[NSString stringWithFormat:@"%@ Plaid", taskPrefix]];
		}
	}
	[dialogWindow makeKeyAndOrderFront:self];
}

- (void)setAchromatic:(BOOL)newState;
{
	long index;
	PlaidComponent c;
	float contrasts[kComponents];
	static float oldKdlThetaDeg[kComponents];
	static float oldKdlPhiDeg[kComponents];
	
	if (newState & !achromatic) {
		achromatic = newState;
		for (index = 0; index < kComponents; index++) {
			c = components[index];
			oldKdlThetaDeg[index] = c.kdlThetaDeg;
			oldKdlPhiDeg[index] = c.kdlPhiDeg;
			c.kdlThetaDeg = 90.0;
			c.kdlPhiDeg = 0.0;
		}
		[self updateIntegerDefault:achromatic key:LLPlaidAchromaticKey];
	}
	else if (!newState && achromatic) {
		achromatic = newState;
		for (index = 0; index < kComponents; index++) {
			c = components[index];
			c.kdlThetaDeg = oldKdlThetaDeg[index];
			c.kdlPhiDeg = oldKdlPhiDeg[index];
			contrasts[index] = c.contrast;
		}
		[self setContrasts:contrasts];					// make sure we're within the chromatic limit
		[self updateIntegerDefault:achromatic key:LLPlaidAchromaticKey];
	}
}

- (void)setContrasts:(float *)newContrasts;
{
	components[0].contrast = MIN(newContrasts[0], achromatic ? 1.0 : 1.0 / sqrt(2.0));
	[self updateFloatDefault:newContrasts[0] key:LLPlaid0ContrastKey];
	components[1].contrast = MIN(newContrasts[1], achromatic ? 1.0 : 1.0 / sqrt(2.0));
	[self updateFloatDefault:newContrasts[1] key:LLPlaid1ContrastKey];
}

// Advance the plaid one time interval (for counterphase, drifting, etc)

- (void)setFrame:(NSNumber *)frameNumber;
{
    long frame, index;
	float frameRateHz, framesPerHalfCycle, newPhaseDeg;
	PlaidComponent c;
	
	frame = [frameNumber longValue];
	frameRateHz = (displays == nil) ? 60.0 : [displays frameRateHz:displayIndex];
	for (index = 0; index < kComponents; index++) {
		c = components[index];
		if (c.temporalFreqHz > 0.0 && frameRateHz > 0.0) {
			framesPerHalfCycle = frameRateHz / c.temporalFreqHz / 2.0;
			switch (c.temporalModulation) {
				case kLLPlaidDrifting:
				case kLLPlaidRandom:
					if (c.temporalModulation == kLLPlaidRandom) {
						if ((frame % (long)ceil(framesPerHalfCycle)) > 0) {
							break;
						}
						else {
							newPhaseDeg = (rand() % 360);
						}
					}
					else {
						newPhaseDeg = (c.temporalPhaseDeg + frame / framesPerHalfCycle * 180.0);
					}
					newPhaseDeg -= floor(newPhaseDeg / 360.0) * 360.0;					// limit to first cycle
					switch (c.temporalModulationParam) {
						case kLLPlaidDirection:
							[self setDirectionDeg:newPhaseDeg];
							break;
						case kLLPlaidKdlTheta:
							c.kdlThetaDeg = newPhaseDeg;
							break;
						case kLLPlaidKdlPhi:
							c.kdlPhiDeg = newPhaseDeg;
							break;
						case kLLPlaidSPhase:
						default:
							c.spatialPhaseDeg = newPhaseDeg;
							break;
					}
					break;
					// 
					// NB: You must set the basePlaid values (using -store) before starting a counterphasing grating, and
					// you must restore the original contrast (using -restore) when you have finished the counterphasing.
					//				
				case kLLPlaidCounterPhase:
				default:
					c.contrast = (basePlaid.components[index].contrast *
								  sin(frame / framesPerHalfCycle * kPI + c.temporalPhaseDeg * kRadiansPerDeg));
					break;
			}
		}
	}
}

- (void)setPlaidData:(Plaid)p;
{
	long lValues[kComponents];
	float values[kComponents];
	
	[self setAzimuthDeg:p.azimuthDeg];								// Center of plaid 
	[self setElevationDeg:p.elevationDeg];							// Center of plaid 
	[self setRadiusDeg:p.radiusDeg];								// Radius of drawing
	[self setSigmaDeg:p.sigmaDeg];									// Plaid	standard deviation
	values[0] = p.components[0].contrast;
	values[1] = p.components[1].contrast;
	[self setContrasts:values];										// Contrast [0:1]
	components[0].directionDeg = p.components[0].directionDeg;
	components[1].directionDeg = p.components[1].directionDeg;
	components[0].kdlThetaDeg = p.components[0].kdlThetaDeg;
	components[1].kdlThetaDeg = p.components[1].kdlThetaDeg;
	components[0].kdlPhiDeg = p.components[0].kdlPhiDeg;
	components[1].kdlPhiDeg = p.components[1].kdlPhiDeg;
	values[0] = p.components[0].spatialFreqCPD;
	values[1] = p.components[1].spatialFreqCPD;
	[self setSpatialFreqsCPD:values];								// Spatial frequency
	lValues[0] = p.components[0].spatialModulation;
	lValues[1] = p.components[1].spatialModulation;
	[self setSpatialModulations:lValues];							// Spatial Modulation: SINE, SQUARE, TRIANGLE
	values[0] = p.components[0].spatialPhaseDeg;
	values[1] = p.components[1].spatialPhaseDeg;
	[self setSpatialPhasesDeg:values];								// Spatial Phase
	values[0] = p.components[0].temporalFreqHz;
	values[1] = p.components[1].temporalFreqHz;
	[self setTemporalFreqsHz:values];								// Temporal frequency
	lValues[0] = p.components[0].temporalModulationParam;
	lValues[1] = p.components[1].temporalModulationParam;
	[self setTemporalModulationParams:lValues];						// Parameter modulated in time
	lValues[0] = p.components[0].temporalModulation;
	lValues[1] = p.components[1].temporalModulation;
	[self setTemporalModulations:lValues];							// Temporal Modulation: COUNTERPHASE, DRIFTING
	values[0] = p.components[0].temporalPhaseDeg;
	values[1] = p.components[1].temporalPhaseDeg;
	[self setTemporalPhasesDeg:values];								// Temporal Phase
}

// Advance the phase of the currently active temporal modulation type (called by setFrame)
/*
- (void)setPhaseDeg:(float)newPhaseDeg;
{
	newPhaseDeg -= floor(newPhaseDeg / 360.0) * 360.0;					// limit to first cycle
	switch (temporalModulationParam) {
		case kLLPlaidDirection:
			[self setDirectionDeg:newPhaseDeg];
			break;
		case kLLPlaidKdlTheta:
			[self setKdlThetaDeg:newPhaseDeg];
			break;
		case kLLPlaidKdlPhi:
			[self setKdlPhiDeg:newPhaseDeg];
			break;
		case kLLPlaidSPhase:
		default:
			[self setSpatialPhaseDeg:newPhaseDeg];
			break;
	}
}
*/
- (void)setSpatialFreqsCPD:(float *)newSFs;
{
    components[0].spatialFreqCPD = newSFs[0];
    components[1].spatialFreqCPD = newSFs[1];
	[self updateFloatDefault: newSFs[0] key:LLPlaid0SpatialFreqCPDKey];
	[self updateFloatDefault: newSFs[1] key:LLPlaid1SpatialFreqCPDKey];
}

- (void)setSigmaDeg:(float)newSigma;
{
    sigmaDeg = newSigma;
	[self updateFloatDefault:sigmaDeg key:LLPlaidSigmaDegKey];
}

- (void)setSpatialPhasesDeg:(float *)newSPhases;
{
    components[0].spatialPhaseDeg = newSPhases[0];
    components[1].spatialPhaseDeg = newSPhases[1];
	[self updateFloatDefault:newSPhases[0] key:LLPlaid0SpatialPhaseDegKey];
	[self updateFloatDefault:newSPhases[1] key:LLPlaid1SpatialPhaseDegKey];
}

- (void)setSpatialModulations:(long *)newSMods;
{
    components[0].spatialModulation = newSMods[0];
    components[1].spatialModulation = newSMods[1];
	[self updateIntegerDefault:newSMods[0] key:LLPlaid0SpatialModulationKey];
	[self updateIntegerDefault:newSMods[1] key:LLPlaid1SpatialModulationKey];
}

- (void)setTemporalFreqsHz:(float *)newTFs;
{
    components[0].temporalFreqHz = newTFs[0];
    components[1].temporalFreqHz = newTFs[1];
	[self updateFloatDefault:newTFs[0] key:LLPlaid0TemporalFreqHzKey];
	[self updateFloatDefault:newTFs[1] key:LLPlaid1TemporalFreqHzKey];
}

- (void)setTemporalModulations:(long *)newTMods;
{
    components[0].temporalModulation = newTMods[0];
    components[1].temporalModulation = newTMods[1];
	[self updateIntegerDefault:newTMods[0] key:LLPlaid0TemporalModulationKey];
	[self updateIntegerDefault:newTMods[1] key:LLPlaid1TemporalModulationKey];
}

- (void)setTemporalModulationParams:(long *)newTParams;
{
    components[0].temporalModulationParam = newTParams[0];
    components[1].temporalModulationParam = newTParams[1];
	[self updateIntegerDefault:newTParams[0] key:LLPlaid0TemporalModulationParamKey];
	[self updateIntegerDefault:newTParams[1] key:LLPlaid1TemporalModulationParamKey];
}

- (void)setTemporalPhasesDeg:(float *)newTPhases;
{
	components[0].temporalPhaseDeg = newTPhases[0];
	components[1].temporalPhaseDeg = newTPhases[1];
	[self updateFloatDefault:newTPhases[0] key:LLPlaid0TemporalPhaseDegKey];
	[self updateFloatDefault:newTPhases[1] key:LLPlaid1TemporalPhaseDegKey];
}


- (float *)spatialFreqsCPD;
{
	static float SF[kComponents];
	
	SF[0] = components[0].spatialFreqCPD;
	SF[1] = components[1].spatialFreqCPD;
	return SF;
}

- (float)sigmaDeg;
{
	return sigmaDeg;
}

/*
- (float)spatialPhaseDeg;
{
	return spatialPhaseDeg;
}

- (long)spatialModulation;
{
	return spatialModulation;
}
*/

- (void)store;
{
	[self loadPlaid:&basePlaid];
}

/*
- (float)temporalFreqHz;
{
	return temporalFreqHz;
}

- (long)temporalModulation;
{
	return temporalModulation;
}

- (long)temporalModulationParam;
{
	return temporalModulationParam;
}

- (float)temporalPhaseDeg;
{
	return temporalPhaseDeg;
}
*/
// Only change the 1D cycle texture if necessary. For example, drifting gratings won't require a change.
	
- (void)updateCycleTexture;
{
	long index;
	BOOL noChanges;
	PlaidComponent c, last, list;
	
	for (index = 0, noChanges = YES; index < kComponents; index++) {
		c = components[index];
		last = lastPlaid.components[index];
		noChanges = noChanges && c.contrast == last.contrast && c.kdlThetaDeg == last.kdlThetaDeg && 
			kdlPhiDeg == last.kdlPhiDeg && c.spatialModulation == last.spatialModulation;
	}
	if (noChanges) {
		return;
	}
	for (index = 0, noChanges = YES; index < kComponents; index++) {
		c = components[index];
		list = displayListPlaid.components[index];
		noChanges = noChanges && c.contrast == list.contrast && c.kdlThetaDeg == list.kdlThetaDeg &&
			c.kdlPhiDeg == list.kdlPhiDeg && c.spatialModulation == list.spatialModulation;
	}
	if (displayListNum > 0 && noChanges) {
			glCallList(displayListNum + kLLPlaidDrawColor);					// use display list if valid one exists
		}
	else {
		[self updateCycleTextureGL];								// else draw in immediate mode
	}
}

- (void)updateCycleTextureGL;
{
    RGBDouble rgb;
	
	if (displays == nil) {
		return;
	}
	if (achromatic) {
		rgb.red = rgb.green = rgb.blue = components[0].contrast;			//????????????????????????????????????
	}
	else {
		rgb = [displays RGB:displayIndex kdlTheta:kdlThetaDeg kdlPhi:kdlPhiDeg];
		rgb.red *= components[0].contrast;
		rgb.green *= components[0].contrast;
		rgb.blue *= components[0].contrast;
	}
	
// convert RGBColor [-1 1] to OpenGL RGB [0 1]  

    glEnable(GL_TEXTURE_1D);
    glBindTexture(GL_TEXTURE_1D, cycleTexture);	
    glPixelTransferf(GL_RED_BIAS, 0.5 - rgb.red / 2.0);
    glPixelTransferf(GL_GREEN_BIAS, 0.5 - rgb.green / 2.0);
    glPixelTransferf(GL_BLUE_BIAS, 0.5 - rgb.blue / 2.0);
    glPixelTransferf(GL_RED_SCALE, rgb.red);
    glPixelTransferf(GL_GREEN_SCALE, rgb.green);
    glPixelTransferf(GL_BLUE_SCALE, rgb.blue);
	
    switch (components[0].spatialModulation) { //????????????????????????????????????????????????
        case kLLPlaidSquareModulation:
			glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, squareImage);
            break;
        case kLLPlaidTriangleModulation:
			glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, triImage);
            break;
        case kLLPlaidSineModulation:
		default:
			glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, sinImage);
            break;
    }   
    glDisable(GL_TEXTURE_1D);     
}

@end

