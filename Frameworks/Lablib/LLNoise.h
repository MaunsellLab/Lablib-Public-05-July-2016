//
//  LLNoise.h
//  Lablib
//
//  Created by Geoff Ghose on 5/16/05.
//  Copyright 2005. All rights reserved.
//	A subclass of the LLGabor object where a noise texture replaces a cycle texture.

#import "LLGabor.h"

typedef struct {
	double orientationDegBand;
	double spatialFreqBandOct;
	double noiseAzimuthDeg;
	double noiseElevationDeg;
	double motionSpeed;
	double motionDir;
	long   seed;
} Noise;

enum {kWhiteNoise, kOneOverFNoise, kGaussianNoise} NoiseType;

#define	kNoisePix (1 << 9)
#define kNoisePos (kKdlPhi + 1)

@interface LLNoise : LLGabor {
	Noise		baseNoise, displayListNoise, drawNoise;				
	float		*freq;
	GLubyte		noiseImage[kNoisePix][kNoisePix];
	GLuint		noiseTexture;
	long		noiseType;
	float		rfact[kNoisePix][kNoisePix];
}

- (void) draw;
- (void) drawTextures;
- (void) drawTexturesGL;
- (Noise *)noiseData;
- (void)makeDisplayLists;
- (void)makeNoiseTexture;
- (void)restore;
- (void)setFrame:(NSNumber *)frameObject;
- (void)setNoiseData:(Noise)newNoise;
- (void)setNoiseAzimuth:(double)az elevation:(double)el;
- (void)setSpatialFreqBandOct:(double)sfBand;
- (void)setOrientationBandDeg:(double)orBand;
- (void)setNoiseData:(Noise)newNoise;
- (void)setNoiseType:(long)newType;
- (void)setMotionSpeed:(double)motionSpeed;
- (void)setMotionDir:(double)motionDir;
- (void)setSeed:(long)seed;
- (void)store;
- (void)updateNoiseTexture;
- (void)updateNoiseTextureGL;


@end

