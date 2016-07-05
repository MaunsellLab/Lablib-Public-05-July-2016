//
//  LLHeatMapView.h
//  Lablib
//
//  Created by John Maunsell September 15, 2012.
//  Copyright (c) 2012. All rights reserved.
//

#import "LLPlotColors.h"
#import "LLViewScale.h"

#define kHighlightPix		1
#define kLLMarginPix			2
#define kLabelExtraPix		15						// Extra margin for x tick labels
#define kShadowPix			1
#define kXAxisExtraSpace	0.5
#define kExtraSpaceFraction	0.05

#define topMarginPix		(kHighlightPix + kLLMarginPix + textLineHeightPix)
#define leftMarginPix		(kHighlightPix + kLLMarginPix + 2 * textLineHeightPix + kTickHeightPix)
#define kRightMarginPix		(kShadowPix + kHighlightPix + kLLMarginPix + kLabelExtraPix)
#define bottomMarginPix		(kShadowPix + kHighlightPix + kLLMarginPix + 2 * textLineHeightPix + kTickHeightPix)

typedef struct {
    float	minValue;
    float	maxValue;
    NSColor *color;
} HMAxisHighlight;

@interface LLHeatMapView : NSView {
    
@protected
    long				dataPoints;					// length of data array
    LLPlotColors		*defaultColors;
    BOOL				highlightPlot;				// draw a box around the entire plot
    float				maxBin;						// value of largest plotting bin
    NSMutableArray		*plotColors;
    NSMutableArray		*plotValues;
    long                plotXPoints;
    long                plotYPoints;
    LLViewScale			*scale;						// Leave the scaling accessible
    NSString			*title;
    float				textLineHeightPix;
    NSString			*xAxisLabel;
    HMAxisHighlight 	xHighlight;
    float				xMaxValue;                  // Values written on the axes
    float				xMinValue;
    NSArray				*xTickLabels;
    float				xTickSpacing;
    NSString			*yAxisLabel;						
    HMAxisHighlight 	yHighlight;
    float				yMaxValue;
    float				yMinValue;
    NSArray				*yTickLabels;
    float				yTickSpacing;
}

@property (retain) NSArray *plotValues;
@property (nonatomic, assign) long plotXPoints;
@property (nonatomic, assign) long plotYPoints;
@property (retain) NSString *title;
@property (nonatomic, assign) float xMaxValue;
@property (nonatomic, assign) float xMinValue;
@property (nonatomic, assign) float yMaxValue;
@property (nonatomic, assign) float yMinValue;

- (void)handleScaleChange:(NSNotification *)note;
- (void)initializeWithScale:(LLViewScale *)plotScale;
- (id) initWithFrame:(NSRect)frame; 
- (id) initWithFrame:(NSRect)frame scaling:(LLViewScale *)histScale;
- (LLViewScale *)scale;
- (void)setHighlightPlot:(BOOL)state;
- (void)setHighlightXRangeColor:(NSColor *)color; 
- (void)setHighlightXRangeFrom:(float)minValue to:(float)maxValue;
- (void)setHighlightYRangeColor:(NSColor *)color; 
- (void)setHighlightYRangeFrom:(float)minValue to:(float)maxValue;
- (void)setScale:(LLViewScale *)newScale;
- (void)setTitle:(NSString *)string;
- (void)setXAxisLabel:(NSString *)label;
- (void)setXAxisTickLabels:(NSArray *)tickLabelArray;
- (void)setXAxisTickSpacing:(float)spacing;
- (void)setYAxisLabel:(NSString *)label;
- (void)setYAxisTickLabels:(NSArray *)tickLabelArray;
- (void)setYAxisTickSpacing:(float)spacing;

@end
