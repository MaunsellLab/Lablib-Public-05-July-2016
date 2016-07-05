//
// LLOldGabor.m
//
// Created by John Maunsell & Geoff Ghose on Sat Feb 15 2003.
// Copyright (c) 2003. All rights reserved.
//
// Comments below describe modifications and OpenGL implementation
// details.

// Important note: ATI driver bug can screw up Gabors.
// Updating OS X from 10.2 to 10.3.1 seems to fix the problem. The symptom is that the background color
// of the square containing the Gabor is black instead of mean-level gray.
//
// Gabor rendering (see draw):
// 1. One-dimension cycles (sine, triangle, & square), a 2-D Gaussian, and a 2-D circular aperture are
//		computed (make* methods) in [LLGabor init].
// 2. The 1-D cycle (sine, triangle or square) is mapped along RGB color space 
//		[LLGabor updateCycleTexture]oldCycleTexture
// 3. A circular drawing mask is defined according to the radius
//		[LLGabor drawCircularStencil]
// 4. This cycle is applied to 2-D space using spatial phase, frequency and position 
//		[LLGabor drawTextures]
// 5. The Gaussian envelope is applied according to the desired sigma 
//		and position [LLGabor drawTextures].

// To maximize performance the components of the gabor can be encapsulated in an OpenGL
// display lists by the method makeDisplayLists. makeDisplayLists would typically be called
// at the beginning of a trial, before frame-by-frame updating so that the display
// lists are created well in advance of their invoking.

// If makeDisplayLists is not called, no display lists are created, and
// each draw will call OpenGL code in "immediate" mode.  If display lists are
// created, the list for each component of the gabor be used if the relevant gabor parameters 
// have not changed since it was created.  If relevant gabor parameters have changed, the draw 
// will be done in "immediate" mode.  There are separate display lists for color, texture and circle.  
// These are used independently, so, for example, if you wanted to modulate color frame by frame, the 
// color would be done in "immediate" mode, but the textures and circle could be done using their 
// display lists.

// Each instance of LLGabor has display lists associated with a particular
// display. Display specific information is used in mapping to color space and
// temporal updating. A single Gabor can not therefore span multiple displays.

// If many copies of a single Gabor need to be rendered, you can construct a display list for
// an entire LLGabor. You would do this by glNewList .... [gabor draw] glEndList. This should
// also work if you've already done a makeDisplayLists since nested display lists are
// supported.

// Temporal updating can be done by the setFrame method. Three types of updating
// are available: counterphase, drift, and random. Updating can be applied to any
// circular parameter: spatial phase, orientation, and kdl angles. Note that the order
// of messages to Gabor can be critical. For example, if you want to suddenly change
// the contrast of a Gabor that has been setup for counter-phasing (which affects
// contrast) that the setContrast message must follow the setFrame message.
// Also note that setFrame need not be called at all: all temporal changes can be
// accomplished by manually setting parameters. Note that setFrame takes an object so
// as to ease the simultaneous updating of an array of Gabors.

// Multitexturing is used speed things up. Profiling reveals that the vertex operations
// (glBegin.. glEnd) are very expensive, and multitexturing allows a single set of 
// glBegin and glEnd to apply to all textures (sine and Gaussian).

// To optimize texture transfers several Apple specific optimizations are used:
// For VRAM texturing:
//    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
// before glTexImage.  This probably isn't a big deal because the textures are 
// only created at the first Gabor initialization, but it should help with startup time. 

// glTexImage calls are quite expensive in terms of time. The 2D texture (Gaussian) 
// are only generated once and never need to be modified. However, the 1D texture might
// need to be modified every frame (e.g., contrast or color changes), which can be very costly. 
// To avoid redefining the 1D texture, glTexImage1D is called only once during initialization 
// and subsequent updating of the texture is done with glTexSubImage1D. The savings are enormous: 
// on a GeForce 4 the average glTeXImage1D was 152 us while the average glTexSubImage1D is 35 us.
// For some reason the Apple optimization glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1) screws things
// up (The pixel transfers are not applied correctly with SubImage but they are with TexImage).
// Thank you Apple!!!!!


// GMG 05/05
// Modified so that list of active gabor variables is stored within a Gabor data structure (gabor).
// Moved oldNumTextureUnits out of Gabor object and made a class variable.
// Made statics globals so that subclasses (LLNoise) can use
// Cleaned up drawTexturesGL and drawCircleGL code (vertex loops)
// Contrast now goes from -1 to 1 to allow straight-forward counter-phasing
// makeDisplayLists now also sets baseGabor

// GMG 03/06
// implemented circular stencil, eliminated circular texture

// GMG 04/06
// optimized circular stencil by removing extraneous glClear


#import "LLOldGabor.h"
#import "LLTextUtil.h"

#define glMultiTexCoord2f	glMultiTexCoord2fARB
#define glMultiTexCoord2fv	glMultiTexCoord2fvARB
#define glActiveTexture		glActiveTextureARB
#define kCyclePix			256						// must be a power of 2
#define kGaussianImagePix   256						// must be a power of 2

// The following are declared as class variables, because the same textures can be used to 
// draw all the instances of LLGabor.  lastGabor keeps track of the texture variables
// of the last Gabor that was drawn.

GLuint 	oldCycleTexture = 0;
GLuint 	oldGaussianTexture = 0;
static OldGabor	lastGabor = {};
static GLubyte	sinImage[kCyclePix];
static GLubyte	triImage[kCyclePix];
static GLubyte	squareImage[kCyclePix];
static GLuint	circleList;
GLint	oldNumTextureUnits=0;
static NSString *azimuthDegKey = @"azimuthDeg";
static NSString *contrastKey = @"contrast";
static NSString *elevationDegKey = @"elevationDeg";
static NSString *kdlThetaDegKey = @"kdlThetaDeg";
static NSString *kdlPhiDegKey = @"kdlPhiDeg";
static NSString *orientationDegKey = @"orientationDeg";
static NSString *radiusDegKey = @"radiusDeg";
static NSString *spatialFreqCPDKey = @"spatialFreqCPD";
static NSString *sigmaDegKey = @"sigmaDeg";
static NSString *spatialModulationTypeKey = @"spatialModulationType";
static NSString *spatialPhaseDegKey = @"spatialPhaseDeg";
static NSString *temporalFreqHzKey = @"temporalFreqHz";
static NSString *temporalModulationTypeKey = @"temporalModulationType";
static NSString *temporalModulationParamKey = @"temporalModulationParam";
static NSString *temporalPhaseDegKey = @"temporalPhaseDeg";

@implementation LLOldGabor
- (double)azimuthDeg;
{
	return gabor.azimuthDeg;
}
- (double)contrast;
{
	return gabor.contrast;
}

- (void)bindValuesToKeysWithPrefix:(NSString *)newPrefix;
{
	NSEnumerator *enumerator;
	NSString *key;
	
	[self unbindValues];
	prefix = newPrefix;
	[prefix retain];
	
	enumerator = [keys objectEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		[self bind:key 
				toObject:[NSUserDefaultsController sharedUserDefaultsController] 
				withKeyPath:[NSString stringWithFormat:@"values.%@", 
				[LLTextUtil capitalize:key prefix:prefix]]
				options:nil];
	}
}


- (void)dealloc {

	[self unbindValues];
	[keys release];
    if (displayListNum > 0) {
        glDeleteLists(displayListNum, kDrawCircle + 1);
	}
	if (displays != nil) {
		[displays release];
	}
	[super dealloc];
} 


- (NSString *)description {

    return[NSString stringWithFormat:@"\n\tAz = %.1f, El = %.1f\n\tOri = %.1f Cont = %.2f\n\
\tRad = %.1f, Sig = %.1f, SF = %.1f\n\tKdl = %.1f, %.1f",
        gabor.azimuthDeg, gabor.elevationDeg, gabor.orientationDeg, gabor.contrast, gabor.radiusDeg, 
		gabor.sigmaDeg, gabor.sf, gabor.kdlThetaDeg, gabor.kdlPhiDeg];
}
// We need this to adhere to the LLVisualStimulus protocol

- (float)directionDeg;
{
	return gabor.orientationDeg;
}

- (void) drawCircularStencil
{
	// only redraw stencil if necessary
	if (gabor.radiusDeg != lastGabor.radiusDeg || gabor.elevationDeg != lastGabor.elevationDeg
		|| gabor.azimuthDeg != lastGabor.azimuthDeg ) {
		if (displayListNum > 0 && 
			gabor.radiusDeg == displayListGabor.radiusDeg &&
			gabor.azimuthDeg == displayListGabor.azimuthDeg &&
			gabor.elevationDeg == displayListGabor.elevationDeg) {
			glCallList(displayListNum + kDrawCircle);		// use display list if valid one exists
		}
		else {
			[self drawCircularStencilGL];					// else draw in immediate mode
		}
	}
}

- (void)draw;
{
    [self updateCycleTexture];
	[self drawCircularStencil];
	[self drawTextures];
	lastGabor=gabor;
}

- (void) drawCircularStencilGL
{
	float limitedRadiusDeg = MIN(gabor.radiusDeg, kRadiusLimitSigma * gabor.sigmaDeg);
	glEnable(GL_STENCIL_TEST);
	glClearStencil(0x0);
//	glClear(GL_STENCIL_BUFFER_BIT);
	glStencilFunc(GL_ALWAYS,0x1,0x1);
	glStencilOp(GL_REPLACE,GL_REPLACE,GL_REPLACE);
	glPushMatrix();
	glTranslatef(gabor.azimuthDeg,gabor.elevationDeg,0.);
	glScalef(limitedRadiusDeg,limitedRadiusDeg,0.);
	glCallList(circleList);
	glPopMatrix();
	glDisable(GL_STENCIL_TEST);
}

- (void) drawTextures {

    if (displayListNum > 0 &&
		gabor.azimuthDeg == displayListGabor.azimuthDeg &&
        gabor.elevationDeg == displayListGabor.elevationDeg &&
		gabor.radiusDeg == displayListGabor.radiusDeg &&
        gabor.sigmaDeg == displayListGabor.sigmaDeg &&
        gabor.sf == displayListGabor.sf &&
        gabor.sPhaseDeg == displayListGabor.sPhaseDeg &&
        gabor.orientationDeg == displayListGabor.orientationDeg) {
			glCallList(displayListNum + kDrawTextures);			// use display list if valid one exists
	}
    else {
        [self drawTexturesGL];									// else draw in immediate mode
	}
}

- (void)drawTexturesGL {

    float corner, texCorners[5],phases[4],x,y;
    short i;
    double radiusPeriods, sinRadius, cosRadius, phaseOffset, orientationRad, limitedRadiusDeg;
     
	limitedRadiusDeg = MIN(gabor.radiusDeg, kRadiusLimitSigma * gabor.sigmaDeg);
    radiusPeriods = limitedRadiusDeg * gabor.sf;
	orientationRad = gabor.orientationDeg * kRadiansPerDeg;
    sinRadius = radiusPeriods * sin(orientationRad);
    cosRadius = radiusPeriods * cos(orientationRad);
    phaseOffset = gabor.sPhaseDeg / 360.0;
    corner = limitedRadiusDeg / gabor.sigmaDeg / (kRadiusLimitSigma * 2.00);
    for (i = 0; i < 4; i++) {					// vertices of the complete gabor
		x=(float)((i / 2) * 2 - 1);
		y=(float)((((i + 1) / 2) % 2) * 2 - 1);
		vertices[i*2]=gabor.azimuthDeg+x*limitedRadiusDeg;
		vertices[i*2+1]=gabor.elevationDeg+y*limitedRadiusDeg;
		phases[i]=phaseOffset+x*cosRadius+y*sinRadius;
        texCorners[i] = 0.5 + (((i % 4) / 2) * 2 - 1) * corner;
    }
	texCorners[4]=texCorners[0];

// Bind each texture to a texture unit

    glActiveTexture(GL_TEXTURE0_ARB);				// activate texture unit 0 and cycle texture 
    glEnable(GL_TEXTURE_1D);						
    glBindTexture(GL_TEXTURE_1D, oldCycleTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE); // replace mode

    glActiveTexture(GL_TEXTURE1_ARB);				// activate texture unit 1 and gaussian texture
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, oldGaussianTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);   // decal mode
	
	
// Assign the vertex coordinate to each of the textures
	glEnable(GL_STENCIL_TEST);
	glStencilFunc(GL_EQUAL,0x1,0x1);
	glStencilOp(GL_KEEP,GL_KEEP,GL_KEEP);
    
    glBegin(GL_QUADS);
	for(i=0;i<4;i++) {
		glMultiTexCoord1f(GL_TEXTURE0_ARB, phases[i]); 
		glMultiTexCoord2fv(GL_TEXTURE1_ARB, &texCorners[i]);
				
		glVertex2fv(&vertices[i*2]);
	}
    glEnd();
    
    glActiveTexture(GL_TEXTURE1_ARB);
    glDisable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE0_ARB);
    glDisable(GL_TEXTURE_1D);
	
	glDisable(GL_STENCIL_TEST);
}

- (OldGabor *)gaborData {
	
	return &gabor;
}

- (id)init {

	GLuint	allTextures[2] = {};
	
    if ((self = [super init]) != nil) {
		keys = [[NSArray arrayWithObjects:azimuthDegKey, contrastKey, elevationDegKey, kdlThetaDegKey, 
				kdlPhiDegKey, orientationDegKey, radiusDegKey, spatialFreqCPDKey, sigmaDegKey, 
				spatialModulationTypeKey, spatialPhaseDegKey, temporalFreqHzKey,
				temporalModulationTypeKey, temporalModulationParamKey, temporalPhaseDegKey, nil] retain];
		gabor.contrast = 1.0;									// default gabor parameters
		gabor.orientationDeg = 45.0;
		gabor.radiusDeg = 4.0;
		gabor.sPhaseDeg = 0.0;
		gabor.sf = 2.0;
		gabor.tf = 0.0;
		gabor.sigmaDeg = 0.5;
		gabor.radiusDeg = 1.5;
		gabor.sModulation = kSineModulation;
		gabor.tModulation = kCounterPhase;
		gabor.tModulationParam = kSPhase;
			
		displayListNum = 0;										// no display lists yet
		glClearColor(0.5, 0.5, 0.5, 1.0);						// set the background color
		glShadeModel(GL_FLAT);									// flat shading
		if(!oldNumTextureUnits)
			glGetIntegerv(GL_MAX_TEXTURE_UNITS, &oldNumTextureUnits);

// only need to generate textures once for all gabors

		if (!oldCycleTexture) {
			glGenTextures(2, allTextures);
			oldCycleTexture = allTextures[0];
			oldGaussianTexture = allTextures[1];
			[self makeCycleTexture];
			[self makeGaussianTexture];
			[self makeCircle];
		}
	}
    return self; 
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
    glEnable(GL_TEXTURE_1D);
    glBindTexture(GL_TEXTURE_1D, oldCycleTexture);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexImage1D(GL_TEXTURE_1D, 0, GL_RGB, kCyclePix, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, sinImage);
    glDisable(GL_TEXTURE_1D);     
}

- (void)makeDisplayLists {

    displayListGabor = gabor;
	[self store];
    
// if no display lists then generate, otherwise overwrite

    if (displayListNum == 0) {
		displayListNum = glGenLists(kDrawTypes);
	}
    glNewList(displayListNum + kDrawColor, GL_COMPILE);				// compile drawlist for color
    [self updateCycleTextureGL];
    glEndList();
    glNewList(displayListNum + kDrawTextures, GL_COMPILE);			// compile drawlist for textures
    [self drawTexturesGL];
    glEndList();
    glNewList(displayListNum + kDrawCircle, GL_COMPILE);			// compile drawlist for circle
    [self drawCircularStencilGL];
    glEndList();
}

// Make a circular polygon
- (void)makeCircle {
	int i;
	int sections=40; //number of triangles to use to estimate a circle
	
	circleList=glGenLists(1);
	glNewList(circleList,GL_COMPILE);
	glBegin(GL_TRIANGLE_FAN);
	glVertex2f(0., 0.); // origin
	for(i = 0; i <= sections;i++) { 
		glVertex2f(cos(i * 2 * M_PI / sections), 
				   sin(i * 2 * M_PI / sections));
	}
	glEnd();
	glEndList();
}	
// Make a Gaussian texture that will give the Gaussian contrast profile to the Gabor

- (void)makeGaussianTexture {

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
            
	glBindTexture(GL_TEXTURE_2D, oldNumTextureUnits);
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

- (void)restore {

	gabor = baseGabor;
}

- (void)setAzimuthDeg:(double)aziDeg {

    gabor.azimuthDeg = aziDeg;
}

- (void)setAzimuthDeg:(double)aziDeg elevationDeg:(double)eleDeg {

    gabor.azimuthDeg = aziDeg;
    gabor.elevationDeg = eleDeg;
}

- (void)setContrast:(double)newContrast {

	newContrast = MIN(newContrast, 1.0);
    gabor.contrast = newContrast;
}

- (void)setDisplays:(LLDisplays *)newDisplays displayIndex:(long)index {
	
	[newDisplays retain];
	if (displays != nil) {
		[displays release];
	}
    displays = newDisplays;
	displayIndex = index;
}

- (void)setElevationDeg:(double)eleDeg {

    gabor.elevationDeg = eleDeg;
}

// Advance the gabor one time interval (for counterphase, drifting, etc)

- (void)setFrame:(NSNumber *)frameNumber {

    long framesPerHalfCycle, cycles, frame;
	float frameRateHz;
    double *currentPhase = &gabor.sPhaseDeg;
		
	frame = [frameNumber longValue];
	if(displays==nil)
		frameRateHz=60.;
	else
		frameRateHz = [displays frameRateHz:displayIndex];
    if (gabor.tf > 0.0 && frameRateHz > 0.0) {
		framesPerHalfCycle = frameRateHz / gabor.tf / 2.0;
        switch (gabor.tModulationParam) {
            case kDirection:
                currentPhase = &gabor.orientationDeg;
                break;
            case kKdlTheta:
                currentPhase = &gabor.kdlThetaDeg;
                break;
            case kKdlPhi:
                currentPhase = &gabor.kdlPhiDeg;
                break;
            case kSPhase:
			default:
                currentPhase = &gabor.sPhaseDeg;
                break;
        }
        switch (gabor.tModulation) {
            case kDrifting:
                *currentPhase = gabor.tPhaseDeg + (double)frame / framesPerHalfCycle * 180.0;
                break;
            case kRandom:
                if ((frame % framesPerHalfCycle) == 0) {
                    *currentPhase = (rand() % 360);
				}
                break;
            case kCounterPhase:
			default:
			/*
                if (frame > 0 && ((frame % framesPerHalfCycle) == 0)) {
                    *currentPhase += 180.0;
				}
                gabor.contrast = baseGabor.contrast * 
						fabs(sin(frame / (double)framesPerHalfCycle * kPI + gabor.tPhaseDeg * kRadiansPerDeg));
			*/
				gabor.contrast=baseGabor.contrast *
						sin(frame / (double)framesPerHalfCycle * kPI + gabor.tPhaseDeg * kRadiansPerDeg);
				break;
        }
    }
    cycles = floor(*currentPhase / 360.0);
    *currentPhase -= cycles * 360.0;
}    
- (void)setGaborData:(OldGabor)newGabor {

	gabor=newGabor;
}


- (void)setKdltheta:(double)newKdltheta {

    gabor.kdlThetaDeg = newKdltheta;
}

- (void)setKdlphi:(double)newKdlphi {

    gabor.kdlPhiDeg = newKdlphi;
}

- (void)setKdlThetaDeg:(double)newKdltheta {

    gabor.kdlThetaDeg = newKdltheta;
}

- (void)setKdlPhiDeg:(double)newKdlphi {

    gabor.kdlPhiDeg = newKdlphi;
}

- (void)setOrientationDeg:(double)newOri {

    gabor.orientationDeg = newOri;
}

- (void)setRadiusDeg:(double)newRadius {

    gabor.radiusDeg = newRadius;
}

- (void)setSpatialFreqCPD:(double)newSF {

    gabor.sf = newSF;
}

- (void)setSF:(double)newSF {

    gabor.sf = newSF;
}

- (void)setSigmaDeg:(double)newSigma {
    
    gabor.sigmaDeg = newSigma;
}

- (void)setSPhaseDeg:(double)newSPhase {

    gabor.sPhaseDeg = newSPhase;
}

- (void)setSpatialPhaseDeg:(double)newSPhase {

   gabor.sPhaseDeg = newSPhase;
}

- (void)setSpatialModulationType:(short)newSMod {

    gabor.sModulation = newSMod;
}

- (void)setSMod:(short)newSMod {

    gabor.sModulation = newSMod;
}

- (void)setTF:(double)newTF {

    gabor.tf = newTF;
}

- (void)setTemporalFreqHz:(double)newTF {

	gabor.tf = newTF;
}

- (void)setTMod:(short)newTMod {

    gabor.tModulation = newTMod;
}

- (void)setTemporalModulationType:(short)newTMod {

    gabor.tModulation = newTMod;
}

- (void)setTParam:(short)newTParam {

    gabor.tModulationParam = newTParam;
}

- (void)setTemporalModulationParam:(short)newTParam {

    gabor.tModulationParam = newTParam;
}

- (void)setTPhaseDeg:(double)newTPhase {

    gabor.tPhaseDeg = newTPhase;
}

- (void)setTemporalPhaseDeg:(double)newTPhase {

    gabor.tPhaseDeg = newTPhase;
}

- (void)store {

	baseGabor = gabor;
}
- (double)temporalFreqHz;
{
	return gabor.tf;
}

- (short)temporalModulationType;
{
	return gabor.tModulation;
}

- (short)temporalModulationParam;
{
	return gabor.tModulationParam;
}

- (double)temporalPhaseDeg;
{
	return gabor.tPhaseDeg;
}

- (void)unbindValues;
{
	NSEnumerator *enumerator;
	NSString *key;
	
	if (prefix != nil) {
		enumerator = [keys objectEnumerator];
		while ((key = [enumerator nextObject]) != nil) {
			[self unbind:key];
		}
		[prefix release];
		prefix = nil;
	}
}

// Only change the 1D cycle texture if necessary. For example, drifting gratings won't require a change.
	
- (void)updateCycleTexture;
{
	if (gabor.contrast != lastGabor.contrast || gabor.kdlThetaDeg != lastGabor.kdlThetaDeg ||
					gabor.kdlPhiDeg != lastGabor.kdlPhiDeg || 
					gabor.sModulation != lastGabor.sModulation) {
		if (displayListNum > 0 && 
				gabor.contrast == displayListGabor.contrast &&
				gabor.kdlThetaDeg == displayListGabor.kdlThetaDeg &&
				gabor.kdlPhiDeg == displayListGabor.kdlPhiDeg &&
				gabor.sModulation == displayListGabor.sModulation) {
			glCallList(displayListNum + kDrawColor);					// use display list if valid one exists
		}
		else {
			[self updateCycleTextureGL];								// else draw in immediate mode
		}
	}
}


- (void)updateCycleTextureGL;
{
    RGBDouble rgb;
	
	if (displays == nil) {
		return;
	}
	rgb = [displays RGB:displayIndex kdlTheta:gabor.kdlThetaDeg kdlPhi:gabor.kdlPhiDeg];
    rgb.red *= gabor.contrast;
    rgb.green *= gabor.contrast;
    rgb.blue *= gabor.contrast;

// convert RGBColor [-1 1] to OpenGL RGB [0 1] 

    glEnable(GL_TEXTURE_1D);
    glBindTexture(GL_TEXTURE_1D, oldCycleTexture);	
    glPixelTransferf(GL_RED_BIAS, 0.5 - rgb.red / 2.0);
    glPixelTransferf(GL_GREEN_BIAS,0.5 - rgb.green / 2.0);
    glPixelTransferf(GL_BLUE_BIAS, 0.5 - rgb.blue / 2.0);
    glPixelTransferf(GL_RED_SCALE, rgb.red);
    glPixelTransferf(GL_GREEN_SCALE, rgb.green);
    glPixelTransferf(GL_BLUE_SCALE, rgb.blue);
	
    switch (gabor.sModulation) {
        case kSquareModulation:
			glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, squareImage);
            break;
        case kTriangleModulation:
			glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, triImage);
            break;
        case kSineModulation:
		default:
			glTexSubImage1D(GL_TEXTURE_1D, 0, 0, kCyclePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, sinImage);
            break;
    }   
    glDisable(GL_TEXTURE_1D);     
}

@end


