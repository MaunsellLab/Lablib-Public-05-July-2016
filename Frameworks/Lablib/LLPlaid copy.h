//
//  LLPlaid.h
//
//  Created by John Maunsell on Sat Feb 15 2009.
//  Copyright (c) 2009. All rights reserved.
//

#import "LLVisualStimulus.h"

typedef struct {
	float	contrast;				// Contrast [0:1]
	float	directionDeg;			// Direction
	float	kdlThetaDeg;			// kdl space (deg)
	float	kdlPhiDeg;				// kdl space (deg)
	float	spatialFreqCPD;			// Spatial frequency
	long	spatialModulation;		// Spatial Modulation: SINE, SQUARE, TRIANGLE
	float	spatialPhaseDeg;		// Spatial Phase
	float	temporalFreqHz;			// Temporal frequency
	long	temporalModulation;		// Temporal Modulation: COUNTERPHASE, DRIFTING
	long	temporalModulationParam;// Parameter modulated in time
	float	temporalPhaseDeg;		// Temporal Phase
} PlaidComponent;

typedef struct {
	float	azimuthDeg;				// Center of plaid 
	float	elevationDeg;			// Center of plaid 
	float	radiusDeg;				// Radius of drawing
	float	sigmaDeg;				// standard deviation
	PlaidComponent components[2];	// Description of the components
} Plaid;

enum {kLLPlaidSineModulation = 0, kLLPlaidSquareModulation, kLLPlaidTriangleModulation};	// spatial modulation
enum {kLLPlaidCounterPhase = 0, kLLPlaidDrifting, kLLPlaidRandom};							// temporal modulation
enum {kLLPlaidSPhase = 0, kLLPlaidDirection, kLLPlaidKdlTheta, kLLPlaidKdlPhi};							// temporal modulation param
enum {kLLPlaidDrawColor, kLLPlaidDrawTextures, kLLPlaidDrawCircle, kLLPlaidDrawTypes};									// display lists

#define kComponents			2
#define kRadiusLimitSigma   3.0						// maximum radius relative to sigma

extern NSString *LLPlaidAzimuthDegKey;
extern NSString *LLPlaidBackColorKey;
extern NSString *LLPlaidDirectionDegKey;
extern NSString *LLPlaidElevationDegKey;
extern NSString *LLPlaidForeColorKey;
extern NSString *LLPlaidKdlThetaDegKey;
extern NSString *LLPlaidKdlPhiDegKey;
extern NSString *LLPlaidRadiusDegKey;

extern NSString *LLPlaidContrastKey;
extern NSString *LLPlaidSpatialFreqCPDKey;
extern NSString *LLPlaidSigmaDegKey;
extern NSString *LLPlaidSpatialModulationKey;
extern NSString *LLPlaidSpatialPhaseDegKey;
extern NSString *LLPlaidTemporalFreqHzKey;
extern NSString *LLPlaidTemporalModulationKey;
extern NSString *LLPlaidTemporalModulationParamKey;
extern NSString *LLPlaidTemporalPhaseDegKey;
	
@interface LLPlaid : LLVisualStimulus {
//	float		contrast;							// Contrast [0:1]
//	float		spatialFreqCPD;						// Spatial frequency
//	float		spatialPhaseDeg;					// Spatial Phase
//	long		spatialModulation;					// Spatial Modulation: SINE, SQUARE, TRIANGLE */
//	float		temporalFreqHz;
//	long		temporalModulation;
//	long		temporalModulationParam;
//	float		temporalPhaseDeg;

	BOOL		achromatic;							// Achromatic grating
	Plaid		basePlaid;
	PlaidComponent components[2];					// Descriptions of the plaid's components
	Plaid		displayListPlaid;
	GLuint		displayListNum;
	Plaid		plaid;
	float		sigmaDeg;							// Plaid standard deviation
	GLfloat		texVertices[8];
	GLfloat		vertices[8];
}

+ (LLDataDef *)LLPlaidEventDesc;
- (float *)contrasts;
- (void)directSetContrasts:(float *)newContrast;
- (void)directSetSigmaDeg:(float)newSigma;
- (void)directSetSpatialFreqsCPD:(float *)newSFs;
- (void)directSetSpatialPhasesDeg:(float *)newSPhases;
- (void)directSetTemporalFreqsHz:(float *)newTFs;
- (void)directSetTemporalPhasesDeg:(float *)newTPhases;
- (void)drawCircularStencil;
- (void)drawCircularStencilGL;
- (void)drawTextures;
- (void)drawTexturesGL;
- (Plaid *)plaidData;
- (void)loadPlaid:(Plaid *)pPlaid;
- (void)makeCircle;
- (void)makeCycleTexture;
- (void)makeDisplayLists;
- (void)makeGaussianTexture;
- (void)restore;
- (void)setContrasts:(float *)newContrasts;
- (void)setFrame:(NSNumber *)frameObject;
- (void)setPlaidData:(Plaid)newPlaid;
//- (void)setPhaseDeg:(float)newPhaseDeg;
- (void)setSpatialFreqsCPD:(float *)newSFs;
- (void)setSigmaDeg:(float)newSigma;
- (void)setSpatialModulations:(long *)newSMods;
- (void)setSpatialPhasesDeg:(float *)newSPhases;
- (void)setTemporalFreqsHz:(float *)newTF;
- (void)setTemporalPhasesDeg:(float *)newTPhases;
- (void)setTemporalModulations:(long *)newTMods;
- (void)setTemporalModulationParams:(long *)newTParams;
- (void)setTemporalPhasesDeg:(float *)newTPhase;
- (float)sigmaDeg;
- (float *)spatialFreqsCPD;
//- (float)spatialPhaseDeg;
//- (long)spatialModulation;
- (void)store;
//- (float)temporalFreqHz;
//- (long)temporalModulation;
//- (long)temporalModulationParam;
//- (float)temporalPhaseDeg;
- (void)updateCycleTexture;
- (void)updateCycleTextureGL;


@end

