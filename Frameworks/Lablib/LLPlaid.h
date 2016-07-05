//
//  LLPlaid.h
//
//  Created by John Maunsell on Sat Feb 15 2009.
//  Copyright (c) 2009. All rights reserved.
//

#import "LLVisualStimulus.h"
#import "LLDataEventDef.h"

#define kLLPlaidEventDesc \
{{@"float", @"azimuthDeg", 1, offsetof(Plaid, azimuthDeg)},\
{@"float", @"elevationDeg", 1, offsetof(Plaid, elevationDeg)},\
{@"float", @"radiusDeg", 1, offsetof(Plaid, radiusDeg)},\
{@"float", @"sigmaDeg", 1, offsetof(Plaid, sigmaDeg)},\
{@"float", @"contrast0", 1, offsetof(Plaid, contrast0)},\
{@"float", @"contrast1", 1, offsetof(Plaid, contrast1)},\
{@"float", @"directionDeg0", 1, offsetof(Plaid, directionDeg0)},\
{@"float", @"directionDeg1", 1, offsetof(Plaid, directionDeg1)},\
{@"float", @"kdlThetaDeg0", 1, offsetof(Plaid, kdlThetaDeg0)},\
{@"float", @"kdlThetaDeg1", 1, offsetof(Plaid, kdlThetaDeg1)},\
{@"float", @"kdlPhiDeg0", 1, offsetof(Plaid, kdlPhiDeg0)},\
{@"float", @"kdlPhiDeg1", 1, offsetof(Plaid, kdlPhiDeg1)},\
{@"float", @"spatialFreqCPD0", 1, offsetof(Plaid, spatialFreqCPD0)},\
{@"float", @"spatialFreqCPD1", 1, offsetof(Plaid, spatialFreqCPD1)},\
{@"long", @"spatialModulation0", 1, offsetof(Plaid, spatialModulation0)},\
{@"long", @"spatialModulation1", 1, offsetof(Plaid, spatialModulation1)},\
{@"float", @"spatialPhaseDeg0", 1, offsetof(Plaid, spatialPhaseDeg0)},\
{@"float", @"spatialPhaseDeg1", 1, offsetof(Plaid, spatialPhaseDeg1)},\
{@"float", @"temporalFreqHz0", 1, offsetof(Plaid, temporalFreqHz0)},\
{@"float", @"temporalFreqHz1", 1, offsetof(Plaid, temporalFreqHz1)},\
{@"long", @"temporalModulation0", 1, offsetof(Plaid, temporalModulation0)},\
{@"long", @"temporalModulation1", 1, offsetof(Plaid, temporalModulation1)},\
{@"long", @"temporalModulationParam0", 1, offsetof(Plaid, temporalModulationParam0)},\
{@"long", @"temporalModulationParam1", 1, offsetof(Plaid, temporalModulationParam1)},\
{@"float", @"temporalPhaseDeg0", 1, offsetof(Plaid, temporalPhaseDeg0)},\
{@"float", @"temporalPhaseDeg1", 1, offsetof(Plaid, temporalPhaseDeg1)},\
{nil}}

typedef struct {
    float	contrast;					// Contrast [0:1]
    float	directionDeg;				// Direction
    float	kdlThetaDeg;				// kdl space (deg)
    float	kdlPhiDeg;					// kdl space (deg)
    float	spatialFreqCPD;             // Spatial frequency
    long	spatialModulation;			// Spatial Modulation: SINE, SQUARE, TRIANGLE
    float	spatialPhaseDeg;			// Spatial Phase
    float	temporalFreqHz;             // Temporal frequency
    long	temporalModulation;         // Temporal Modulation: COUNTERPHASE, DRIFTING
    long	temporalModulationParam;	// Parameter modulated in time
    float	temporalPhaseDeg;			// Temporal Phase
} Grating;

typedef struct {
    float	azimuthDeg;					// Center of plaid
    float	elevationDeg;				// Center of plaid
    float	radiusDeg;					// Radius of drawing
    float	sigmaDeg;					// standard deviation
    float	contrast0;					// Contrast [0:1]
    float	contrast1;					// Contrast [0:1]
    float	directionDeg0;				// Direction
    float	directionDeg1;				// Direction
    float	kdlThetaDeg0;				// kdl space (deg)
    float	kdlThetaDeg1;				// kdl space (deg)
    float	kdlPhiDeg0;					// kdl space (deg)
    float	kdlPhiDeg1;					// kdl space (deg)
    float	radiusLimitSigma;			// max radius in sigmas
    float	spatialFreqCPD0;			// Spatial frequency
    float	spatialFreqCPD1;			// Spatial frequency
    long	spatialModulation0;			// Spatial Modulation: SINE, SQUARE, TRIANGLE
    long	spatialModulation1;			// Spatial Modulation: SINE, SQUARE, TRIANGLE
    float	spatialPhaseDeg0;			// Spatial Phase
    float	spatialPhaseDeg1;			// Spatial Phase
    float	temporalFreqHz0;			// Temporal frequency
    float	temporalFreqHz1;			// Temporal frequency
    long	temporalModulation0;		// Temporal Modulation: COUNTERPHASE, DRIFTING
    long	temporalModulation1;		// Temporal Modulation: COUNTERPHASE, DRIFTING
    long	temporalModulationParam0;	// Parameter modulated in time
    long	temporalModulationParam1;	// Parameter modulated in time
    float	temporalPhaseDeg0;			// Temporal Phase
    float	temporalPhaseDeg1;			// Temporal Phase
} Plaid;

enum  {kLLPlaidSineModulation = 0, kLLPlaidSquareModulation, kLLPlaidTriangleModulation} SpatialModulation0;	// spatial modulation
enum {kLLPlaidCounterPhase = 0, kLLPlaidDrifting, kLLPlaidRandom} TemporalModulation0;							// temporal modulation
enum {kLLPlaidSPhase = 0, kLLPlaidDirection, kLLPlaidKdlTheta, kLLPlaidKdlPhi} TemporalModulationParam0;		// temporal modulation param
enum {kLLPlaidDrawColor, kLLPlaidDrawTextures, kLLPlaidDrawCircle, kLLPlaidDrawTypes} DisplayList0;				// display lists

#define kComponents			2

extern NSString *LLPlaidAzimuthDegKey;
extern NSString *LLPlaidBackColorKey;
//extern NSString *LLPlaidDirectionDegKey;
extern NSString *LLPlaidElevationDegKey;
extern NSString *LLPlaidForeColorKey;
//extern NSString *LLPlaidKdlThetaDegKey;
//extern NSString *LLPlaidKdlPhiDegKey;
extern NSString *LLPlaidRadiusDegKey;

extern NSString *LLPlaid0ContrastKey;
extern NSString *LLPlaid0DirectionDegKey;
extern NSString *LLPlaid0KdlPhiDegKey;
extern NSString *LLPlaid0KdlThetaDegKey;
extern NSString *LLPlaid0SpatialFreqCPDKey;
extern NSString *LLPlaid0SigmaDegKey;
extern NSString *LLPlaid0SpatialModulationKey;
extern NSString *LLPlaid0SpatialPhaseDegKey;
extern NSString *LLPlaid0TemporalFreqHzKey;
extern NSString *LLPlaid0TemporalModulationKey;
extern NSString *LLPlaid0TemporalModulationParamKey;
extern NSString *LLPlaid0TemporalPhaseDegKey;

extern NSString *LLPlaid1ContrastKey;
extern NSString *LLPlaid1DirectionDegKey;
extern NSString *LLPlaid1KdlPhiDegKey;
extern NSString *LLPlaid1KdlThetaDegKey;
extern NSString *LLPlaid1SpatialFreqCPDKey;
extern NSString *LLPlaid1SigmaDegKey;
extern NSString *LLPlaid1SpatialModulationKey;
extern NSString *LLPlaid1SpatialPhaseDegKey;
extern NSString *LLPlaid1TemporalFreqHzKey;
extern NSString *LLPlaid1TemporalModulationKey;
extern NSString *LLPlaid1TemporalModulationParamKey;
extern NSString *LLPlaid1TemporalPhaseDegKey;

@interface LLPlaid : LLVisualStimulus {

	BOOL		achromatic;							// Achromatic grating
	Plaid		basePlaid;
	float		contrast0;							// Contrast [0:1]
	float		contrast1;							// Contrast [0:1]
	float		directionDeg0;
	float		directionDeg1;
	Plaid		displayListPlaid;
	GLuint		displayListNum;
	float		kdlThetaDeg0;
	float		kdlThetaDeg1;
	float		kdlPhiDeg0;
	float		kdlPhiDeg1;
    NSLock      *modLock;
	Plaid		plaid;
	float		radiusLimitSigma;
	float		sigmaDeg;							// Plaid standard deviation
	float		spatialFreqCPD0;						// Spatial frequency
	float		spatialFreqCPD1;						// Spatial frequency
	float		spatialPhaseDeg0;					// Spatial Phase
	float		spatialPhaseDeg1;					// Spatial Phase
	long		spatialModulation0;					// Spatial Modulation: SINE, SQUARE, TRIANGLE */
	long		spatialModulation1;					// Spatial Modulation: SINE, SQUARE, TRIANGLE */
	float		temporalFreqHz0;
	float		temporalFreqHz1;
	long		temporalModulation0;
	long		temporalModulation1;
	long		temporalModulationParam0;
	long		temporalModulationParam1;
	float		temporalPhaseDeg0;
	float		temporalPhaseDeg1;
	GLfloat		texVertices[8];
	GLfloat		vertices[8];
	GLfloat		vertices1[8];
}

- (float)contrast0;
- (float)contrast1;
- (float)directionDeg0;
- (float)directionDeg1;
- (void)directSetContrast0:(float)newContrast;
- (void)directSetContrast1:(float)newContrast;
- (void)directSetFrame:(NSNumber *)frameNumber;
- (void)directSetSigmaDeg:(float)newSigma;
- (void)directSetSpatialFreqCPD0:(float)newSF;
- (void)directSetSpatialFreqCPD1:(float)newSF;
- (void)directSetSpatialPhaseDeg0:(float)newSPhase;
- (void)directSetSpatialPhaseDeg1:(float)newSPhase;
- (void)directSetTemporalFreqHz0:(float)newTF;
- (void)directSetTemporalFreqHz1:(float)newTF;
- (void)directSetTemporalPhaseDeg0:(float)newTPhase;
- (void)directSetTemporalPhaseDeg1:(float)newTPhase;
- (void)drawCircularStencil;
- (void)drawCircularStencilGL;
- (void)drawTextures;
- (void)drawTexturesGL;
- (Plaid *)plaidData;
- (void)loadPlaid:(Plaid *)pPlaid;
- (void)makeCircle;
- (void)makeCycleTextures;
- (void)makeDisplayLists;
- (void)makeGaussianTexture;
- (void)restore;
- (void)restore:(long)gratingNum;
- (void)setAchromatic:(BOOL)newState;
- (void)setContrast0:(float)newContrast;
- (void)setContrast1:(float)newContrast;
- (void)setDirectionDeg0:(float)newDirection;
- (void)setDirectionDeg1:(float)newDirection;
- (void)setFrame:(NSNumber *)frameObject;
- (void)setPlaidData:(Plaid)newPlaid;
- (void)setRadiusLimitSigma:(float)newLimit;
- (void)setSpatialFreqCPD0:(float)newSF;
- (void)setSpatialFreqCPD1:(float)newSF;
- (void)setSigmaDeg:(float)newSigma;
- (void)setSpatialModulation0:(long)newSMod;
- (void)setSpatialModulation1:(long)newSMod;
- (void)setSpatialPhaseDeg0:(float)newSPhase;
- (void)setSpatialPhaseDeg1:(float)newSPhase;
- (void)setTemporalFreqHz0:(float)newTF;
- (void)setTemporalFreqHz1:(float)newTF;
- (void)setTemporalModulation0:(long)newTMod;
- (void)setTemporalModulation1:(long)newTMod;
- (void)setTemporalModulationParam0:(long)newTParam;
- (void)setTemporalModulationParam1:(long)newTParam;
- (void)setTemporalPhaseDeg0:(float)newTPhase;
- (void)setTemporalPhaseDeg1:(float)newTPhase;
- (float)sigmaDeg;
- (float)spatialFreqCPD0;
- (float)spatialFreqCPD1;
- (void)store;
- (void)store:(long)gratingNum;
- (void)updateCycleTextures;
- (void)updateCycleTexturesGL;


@end

