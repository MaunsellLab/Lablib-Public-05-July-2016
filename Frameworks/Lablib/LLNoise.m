//
//  LLNoise.m
//  Lablib
//
//  Created by Geoff Ghose on 5/16/05.
//  Copyright 2005. All rights reserved.
//	A subclass of LLGabor providing Gaussian masked bandpass noise.
//	The draw sequence is virtually identical to LLGabor with a 2D noise texture replacing a 1D cycle texture.
//	A noise field is created over which a window can drift (noiseAzimuth and noiseElevation) allow drifting noise
//	in user specified direction and speed.
//	An additional structure called Noise contains these "position" parameters as well as other noise specific parameters 
//	including SF and OR bandwidths, and initial seed.
//	Most animation (setFrame) is of similar speed to LLGabor. The major exception is animation in color space or
//	contrast (e.g. counter-phasing). This is MUCH slower than LLGabor and probably prohibitively slow. The culprit is
//	updateNoiseTextureGL which must copy the entire noise field to the 2d texture (unlike LLGabor in which only a small
//	1D cycle texture is copied).

//	Bug fixes 7/05: circular texture vertices fixed. updateNoiseTexture fixed,makeNoiseTexture fixed.

#import "LLNoise.h"

extern GLuint	circularTexture;
extern GLuint 	gaussianTexture;
extern GLint	numTextureUnits;
extern Gabor	lastGabor;
static Noise	lastNoise;
static Gabor	lastNoiseGabor;
void fourn(float data[], unsigned long nn[], int ndim, int isign);
float *vector(long nl, long nh);
void free_vector(float *v, long nl, long nh);
unsigned long *lvector(long nl, long nh);
void free_lvector(unsigned long *v, long nl, long nh);

@implementation LLNoise

- (void)dealloc;
{
	free_vector(freq,1,2*kNoisePix*kNoisePix);   
	[super dealloc];
} 


- (void)draw;
{
    [self updateNoiseTexture];
	[self drawCircularStencil];
	[self drawTextures];
	[self loadGabor:&lastGabor];
	[self loadGabor:&lastNoiseGabor];
	lastNoise = drawNoise;
}
	

- (void) drawTextures;
{
    if (displayListNum > 0 &&
		radiusDeg == displayListGabor.radiusDeg &&
        sigmaDeg == displayListGabor.sigmaDeg &&
        azimuthDeg == displayListGabor.azimuthDeg &&
        elevationDeg == displayListGabor.elevationDeg &&
        directionDeg == displayListGabor.directionDeg &&
		drawNoise.noiseAzimuthDeg == displayListNoise.noiseAzimuthDeg &&
		drawNoise.noiseElevationDeg == displayListNoise.noiseElevationDeg) {
			glCallList(displayListNum + kDrawTextures);			// use display list if valid one exists
	}
    else {
        [self drawTexturesGL];									// else draw in immediate mode
	}
}

- (void)drawTexturesGL;
{
    float corner, texCorners[5];
	float noiseTexCorners[8];
	float x,y,noiseSize;
    short i;
    double orientationRad, limitedRadiusDeg;
	NSSize displaySizeDeg;
     
	limitedRadiusDeg = MIN(radiusDeg, kRadiusLimitSigma * sigmaDeg);
	orientationRad = directionDeg * kRadiansPerDeg;
	if(displays==nil)
		return;
	displaySizeDeg=[displays displaySizeDeg:displayIndex];
	noiseSize=kNoisePix/(float)[displays widthPix:displayIndex]*displaySizeDeg.width;
    corner = limitedRadiusDeg / sigmaDeg / (kRadiusLimitSigma * 2.00);
    for (i = 0; i < 4; i++) {					// vertices of the complete gabor
		x=(float)((i / 2) * 2 - 1) * limitedRadiusDeg;
		y=(float)((((i + 1) / 2) % 2) * 2 - 1) * limitedRadiusDeg;
		vertices[i * 2] = azimuthDeg + x;
        vertices[i * 2 + 1] = elevationDeg + y;
        noiseTexCorners[i * 2] = drawNoise.noiseAzimuthDeg  + x*cos(orientationRad) + y*sin(orientationRad) ;
		noiseTexCorners[i * 2] = noiseTexCorners[i * 2]/noiseSize+.5;
        noiseTexCorners[i * 2 + 1] = drawNoise.noiseElevationDeg + y*cos(orientationRad) - x*sin(orientationRad) ;
		noiseTexCorners[i * 2 + 1] = noiseTexCorners[i * 2 + 1]/noiseSize+.5;
        texCorners[i] = 0.5 + (((i % 4) / 2) * 2 - 1) * corner;
   }
   texCorners[4]=texCorners[0];

// Bind each texture to a texture unit

    glActiveTexture(GL_TEXTURE0_ARB);				// activate texture unit 0 and noise texture 
    glEnable(GL_TEXTURE_2D);						
    glBindTexture(GL_TEXTURE_2D, noiseTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE); // replace mode

    glActiveTexture(GL_TEXTURE1_ARB);				// activate texture unit 1 and gaussian texture
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, gaussianTexture);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);   // decal mode
	
// Assign the vertex coordinate to each of the textures

	glEnable(GL_STENCIL_TEST);
	glStencilFunc(GL_EQUAL,0x1,0x1);
	glStencilOp(GL_KEEP,GL_KEEP,GL_KEEP);
    
    glBegin(GL_QUADS);
	for (i=0;i < 4;i++) {
		glMultiTexCoord2fv(GL_TEXTURE0_ARB, &noiseTexCorners[i*2]); 
		glMultiTexCoord2fv(GL_TEXTURE1_ARB, &texCorners[i]);
		
		glVertex2fv(&vertices[i*2]);
	}
    glEnd();
    
    glActiveTexture(GL_TEXTURE0_ARB);
    glDisable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE1_ARB);
    glDisable(GL_TEXTURE_2D);

	glDisable(GL_STENCIL_TEST);
}

// Initialize and set default parameters

- (id)init;
{
    if ((self = [super init]) != nil) {
		noiseType = kWhiteNoise;										// default white noise
		drawNoise.orientationDegBand = 180.0;							// no orientation
		drawNoise.spatialFreqBandOct = 10.0;							// broad band noise
		drawNoise.noiseAzimuthDeg = drawNoise.noiseElevationDeg = 0.0;
		drawNoise.motionSpeed = 0.0;
		drawNoise.motionDir = 90.0;
		drawNoise.seed = 0;
		lastNoise.seed = -1;											// force drawing initially
		freq = vector(1, 2 * kNoisePix * kNoisePix);			
		glClearColor(0.5, 0.5, 0.5, 1.0);								// set the background color
		glShadeModel(GL_FLAT);											// flat shading
		glGenTextures(1, &noiseTexture);

//set up noiseTexture

		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, noiseTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, kNoisePix, kNoisePix, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, noiseImage);
		glDisable(GL_TEXTURE_2D);  
	}
    return self; 
}

- (void)makeDisplayLists;
{
    
// if no display lists then generate, otherwise overwrite

    if (displayListNum == 0) {
		displayListNum = glGenLists(kDrawTypes);
	}
    glNewList(displayListNum + kDrawColor, GL_COMPILE);				// compile drawlist for color
    [self updateNoiseTextureGL];
    glEndList();
    glNewList(displayListNum + kDrawTextures, GL_COMPILE);			// compile drawlist for textures
    [self drawTexturesGL];
    glEndList();
    glNewList(displayListNum + kDrawCircle, GL_COMPILE);			// compile drawlist for circle
    [self drawCircularStencilGL];
    glEndList();
    [self loadGabor:&displayListGabor];
    [self loadGabor:&baseGabor];
	displayListNoise = drawNoise;
	baseNoise=drawNoise;
}

// Make the noise 

- (void)makeNoiseTexture;
{
	unsigned long *nn;
	short n;
	long x, y, xr, yc, xindex, rowSize, row, col;
	float real,imag;
	float rpeak, rWidthOct, awidth;
	float r, rDistOct, ang;
	float xp,yp;
	float f1,f2;
	float *lfreq;
	long fx, fy;
	float phase, maxf;
	long halfNoisePix;
    //	NSSize displaySizeDeg;

NSLog(@"Start makeNoiseTexture");

	nn = lvector(1,2);
	nn[1] = kNoisePix;
	nn[2] = kNoisePix;
	halfNoisePix = kNoisePix / 2;
	
// fill with random phases to produce real numbers equal pos and neg freq, zero DC freq

	if (drawNoise.seed != lastNoise.seed) {
		srandom(drawNoise.seed);
		for (row = 0; row < halfNoisePix; row++) {
			for (col = 0; col < halfNoisePix; col++) {
				xr = halfNoisePix - row;
				yc = halfNoisePix - col;
				xindex = xr * 2 * kNoisePix + yc * 2;
				phase = (float)random() / ((1<<31)-1) * k2PI;
				real = cos(phase);
				imag = sin(phase);
				freq[xindex] = real;
				freq[xindex + 1] = imag;				
				yc = halfNoisePix + col;
				xindex = xr * 2 * kNoisePix + yc * 2;
				freq[xindex] = real;
				freq[xindex + 1] = imag;
				xr = halfNoisePix + row;
				xindex = xr * 2 * kNoisePix + yc * 2;
				freq[xindex] = real;
				freq[xindex+1] = imag;
				yc = halfNoisePix - col;
				xindex = xr * 2 * kNoisePix + yc * 2;
				freq[xindex] = real;
				freq[xindex+1] = imag;				
			}	
		}
		lastNoise.seed = drawNoise.seed;
	}
	if (displays == nil) {
		return;
	}
	
// compute filter where r = 1 is equal to Nyquist orientation is taken care of in drawTextures

	lfreq = vector(1, 2 * kNoisePix * kNoisePix);
	if (drawNoise.spatialFreqBandOct != lastNoise.spatialFreqBandOct || 
						spatialFreqCPD != lastNoiseGabor.spatialFreqCPD || 
						drawNoise.orientationDegBand != lastNoise.orientationDegBand) {
        //		displaySizeDeg = [displays displaySizeDeg:displayIndex];
		rpeak = spatialFreqCPD / [displays highestSpatialFreqCPD:displayIndex];		// peak as fraction of limit
		rWidthOct = drawNoise.spatialFreqBandOct;
		awidth = drawNoise.orientationDegBand * kRadiansPerDeg;
//		maxf = 0;
		for (x = 0; x < kNoisePix; x++) {
			xp = (float)(x - halfNoisePix) / halfNoisePix;		// radii from center
			for (y = 0; y < kNoisePix;y++) {
				yp = (float)(y - halfNoisePix) / halfNoisePix;	// radii from center
				r = sqrt(xp * xp + yp * yp) + 0.001;
				if (r > 1) {									// clip to circle
					rfact[x][y] = 0.0;
				}
				else {
					if (rWidthOct > 10.0) {						// effective infinite bandwidth
						rfact[x][y] = 1.0;
					}
					else {
						rDistOct = log(r / rpeak) / log(2);	// absolute distance in octaves
						switch (noiseType) {
						case kGaussianNoise:
							if (fabs(rDistOct) < 3 * rWidthOct) {	// less than 3 bands
								rfact[x][y] = exp(-1.0 * rDistOct * rDistOct / 2.0 / rWidthOct / rWidthOct);
							}
							else {
								rfact[x][y] = 0.0;
							}
							break;
						case kOneOverFNoise:
							if (fabs(rDistOct) >= rWidthOct / 2.0) {
								rfact[x][y] = 0.0;			// beyond band
							}
							else {
								rfact[x][y] = exp(log(0.5) * (rWidthOct / 2.0 + rDistOct));
							}
							break;
						case kWhiteNoise:
						default:
							rfact[x][y] = (fabs(rDistOct) < rWidthOct / 2.0) ? 1.0 : 0.0;
							break;
						}
					}
					if (awidth < k2PI) {						// do gaussian orientation bandwidth
						ang = fabs(atan2f(yp, xp));
						if (ang < 3 * awidth) {
							rfact[x][y] *= exp(-1 * ang * ang / 2 / awidth / awidth);
						}
						else {
							rfact[x][y] = 0.0;
						}
					}
				}
			}
		}
		lastNoise.spatialFreqBandOct = drawNoise.spatialFreqBandOct;
		lastNoiseGabor.spatialFreqCPD = spatialFreqCPD;
		lastNoise.orientationDegBand = drawNoise.orientationDegBand;
	}

// zero DC

	rfact[halfNoisePix][halfNoisePix] = 0.0;
	
// implement filter on random phases

	rowSize = 2 * kNoisePix;
//	maxf=0;
	for (x=1; x < kNoisePix * kNoisePix * 2; ) {
		row=floor((x-1)/rowSize);
		if(row <= halfNoisePix)
			f1=(float)row/(halfNoisePix);
		else
			f1=(float)(row-kNoisePix)/(halfNoisePix);
		col=((x-1)-row*rowSize)/2;
		if(col<=halfNoisePix)
			f2=(float)col/(halfNoisePix);
		else
			f2=(float)(col-kNoisePix)/(halfNoisePix);
		fx=f1*halfNoisePix+halfNoisePix;
		fy=f2*halfNoisePix+halfNoisePix;
		lfreq[x]=freq[x]*rfact[fx][fy];
//		if(fabs(lfreq[x])>maxf) {
//			maxf=fabs(lfreq[x]);
//		}
		x++;
		lfreq[x] = freq[x]*rfact[fx][fy];
//		if(fabs(lfreq[x])>maxf) {
//			maxf=fabs(lfreq[x]);
//		}
		x++;
	}
	fourn(lfreq, nn, 2, -1);	
	for(x=1, maxf = 0.0; x < kNoisePix * kNoisePix * 2; x += 2) {
		if(fabs(lfreq[x]) > maxf) {
			maxf = fabs(lfreq[x]);
		}
	}
	for( x=1;x<kNoisePix*kNoisePix*2;x+=2) {	
		row=floor((x-1)/rowSize);
		col=((x-1)-row*rowSize)/2;
		n = (GLubyte)(lfreq[x] / maxf * 127.0 + 127.0);
		noiseImage[row][col]=(GLubyte)n;
	}
	free_vector(lfreq,1,2*kNoisePix*kNoisePix);
	free_lvector(nn,1,2);
NSLog(@"End makeNoiseTexture");
}

// Advance the gabor one time interval (for counterphase, drifting, etc)

- (void)setFrame:(NSNumber *)frameNumber;
{
    long framesPerHalfCycle, cycles, frame;
	float frameRateHz;
    float *currentPhase = &spatialPhaseDeg;
	NSSize displaySizeDeg;
		
	frame = [frameNumber longValue];
	if (displays == nil) {
		return;
	}
	frameRateHz = [displays frameRateHz:displayIndex];
	displaySizeDeg = [displays displaySizeDeg:displayIndex];
    if (frameRateHz > 0.0 && temporalFreqHz > 0.0) {
		framesPerHalfCycle = frameRateHz / temporalFreqHz / 2.0;
		switch (temporalModulationParam) {
			case kDirection:
				currentPhase = &directionDeg;
				break;
			case kKdlTheta:
				currentPhase = &kdlThetaDeg;
				break;
			case kKdlPhi:
				currentPhase = &kdlPhiDeg;
				break;
		}
        switch (temporalModulation) {
            case kDrifting:
				if(temporalModulationParam == kNoisePos) {
					drawNoise.noiseAzimuthDeg-=drawNoise.motionSpeed*sin(drawNoise.motionDir*kRadiansPerDeg)/frameRateHz;
					drawNoise.noiseElevationDeg+=drawNoise.motionSpeed*cos(drawNoise.motionDir*kRadiansPerDeg)/frameRateHz;
				}
				else
					*currentPhase = temporalPhaseDeg + (double)frame / framesPerHalfCycle * 180.0;
                break;
            case kRandom:
                if ((frame % framesPerHalfCycle) == 0) {
					if(temporalModulationParam == kNoisePos) {
						drawNoise.noiseAzimuthDeg=((float)(random()%kNoisePix)/kNoisePix-.5)*displaySizeDeg.width;
						drawNoise.noiseElevationDeg=((float)(random()%kNoisePix)/kNoisePix-.5)*displaySizeDeg.height;
					}
					else
						*currentPhase = (random() % 360);
				}
                break;
            case kCounterPhase:
			default:
                contrast = baseGabor.contrast * 
						(sin(frame / (double)framesPerHalfCycle * kPI + temporalPhaseDeg * kRadiansPerDeg));
				break;
        }
		cycles = floor(*currentPhase / 360.0);
		*currentPhase -= cycles * 360.0;
    }
} 
   
- (Noise *)noiseData;
{
	return(&drawNoise);
}

- (void)restore;
{
	drawNoise=baseNoise;
	[super restore];
}

- (void)setNoiseAzimuth:(double)az elevation:(double)el;
{
	drawNoise.noiseAzimuthDeg=az;
	drawNoise.noiseElevationDeg=el;
}

- (void)setNoiseData:(Noise)newNoise;
{
	drawNoise=newNoise;
}

- (void)setNoiseType:(long)newType;
{
	noiseType = newType;
}

- (void)setSpatialFreqBandOct:(double)sfBand;
{
	drawNoise.spatialFreqBandOct = sfBand;
}

- (void)setOrientationBandDeg:(double)orBand;
{
	drawNoise.orientationDegBand=orBand;
}

- (void)setMotionSpeed:(double)motionSpeed;
{
	drawNoise.motionSpeed=motionSpeed;
}

- (void)setMotionDir:(double)motionDir;
{
	drawNoise.motionDir=motionDir;
}

- (void)setSeed:(long)seed;
{
	drawNoise.seed = seed;
}

- (void)store;
{
	baseNoise=drawNoise;
	[super store];
}

// Only change the 2D noise texture if necessary.
	
- (void)updateNoiseTexture;
{
	if (spatialFreqCPD != lastNoiseGabor.spatialFreqCPD ||
					drawNoise.orientationDegBand != lastNoise.orientationDegBand ||
					drawNoise.spatialFreqBandOct != lastNoise.spatialFreqBandOct ||
					drawNoise.seed != lastNoise.seed) {
		[self makeNoiseTexture];
		[self updateNoiseTextureGL];								// else draw in immediate mode
	}
	else if (contrast != lastNoiseGabor.contrast || kdlThetaDeg != lastNoiseGabor.kdlThetaDeg ||
					kdlPhiDeg != lastNoiseGabor.kdlPhiDeg ) {
		if (displayListNum > 0 && 
				contrast == displayListGabor.contrast &&
				kdlThetaDeg == displayListGabor.kdlThetaDeg &&
				kdlPhiDeg == displayListGabor.kdlPhiDeg)  {
			glCallList(displayListNum + kDrawColor);					// use display list if valid one exists
		}
		else {
			[self updateNoiseTextureGL];								// else draw in immediate mode
		}
	}
}

- (void)updateNoiseTextureGL;
{
    RGBDouble rgb;
	
	if (displays == nil) {
		return;
	}
	rgb = [displays RGB:displayIndex kdlTheta:kdlThetaDeg kdlPhi:kdlPhiDeg];
    rgb.red *= contrast;
    rgb.green *= contrast;
    rgb.blue *= contrast;

// convert RGBColor [-1 1] to OpenGL RGB [0 1] 

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, noiseTexture);	
    glPixelTransferf(GL_RED_BIAS, 0.5 - rgb.red / 2.0);
    glPixelTransferf(GL_GREEN_BIAS,0.5 - rgb.green / 2.0);
    glPixelTransferf(GL_BLUE_BIAS, 0.5 - rgb.blue / 2.0);
    glPixelTransferf(GL_RED_SCALE, rgb.red);
    glPixelTransferf(GL_GREEN_SCALE, rgb.green);
    glPixelTransferf(GL_BLUE_SCALE, rgb.blue);
	
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, kNoisePix, kNoisePix, GL_LUMINANCE, GL_UNSIGNED_BYTE, noiseImage);

    glDisable(GL_TEXTURE_2D);     
}


@end
