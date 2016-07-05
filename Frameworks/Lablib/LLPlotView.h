//
//  LLPlotView.h
//  Lablib
//
//  Created by John Maunsell on Sun May 04 2003.
//  Copyright (c) 2003. All rights reserved.
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
} AxisHighlight;

@interface LLPlotView : NSView {
@protected
    long				dataPoints;					// length of data array
    LLPlotColors		*defaultColors;
    NSMutableArray		*enable;
    BOOL				highlightPlot;				// draw a box around the entire plot
    float				maxBin;						// value of largest plotting bin
    NSMutableArray		*plotColors;
    NSMutableArray		*plotValues;
    long 				plotPoints;					// number of points to plot
    LLViewScale			*scale;						// Leave the scaling accessible
    NSString			*title;
    float				textLineHeightPix;
    BOOL				useXDisplayValues;
    BOOL				useYDisplayValues;
    NSString			*xAxisLabel;
    AxisHighlight 		xHighlight;
    float				xMaxDisplayValue;			// Values written on the axes
    float				xMinDisplayValue;
    NSArray				*xTickLabels;
    float				xTickSpacing;
    NSString			*yAxisLabel;						
    AxisHighlight 		yHighlight;
    float				yMaxDisplayValue;						
    float				yMinDisplayValue;						
    NSArray				*yTickLabels;
    float				yTickSpacing;
}

- (void)addPlot:(NSArray *)values plotColor:(NSColor *)color;
- (void)disableAll;
- (void)enableAll;
- (void)handleScaleChange:(NSNotification *)note;
- (void)initializeWithScale:(LLViewScale *)plotScale;
- (id) initWithFrame:(NSRect)frame; 
- (id) initWithFrame:(NSRect)frame scaling:(LLViewScale *)histScale;
- (long)points;
- (LLViewScale *)scale;
- (void)setColor:(NSColor *)newColor forPlot:(long)plotIndex;
- (void)setHighlightPlot:(BOOL)state;
- (void)setHighlightXRangeColor:(NSColor *)color; 
- (void)setHighlightXRangeFrom:(float)minValue to:(float)maxValue;
- (void)setHighlightYRangeColor:(NSColor *)color; 
- (void)setHighlightYRangeFrom:(float)minValue to:(float)maxValue;
- (void)setPoints:(long)binsToPlot;
- (void)setScale:(LLViewScale *)newScale;
- (void)setTitle:(NSString *)string;
- (void)setXAxisLabel:(NSString *)label;
- (void)setXAxisTickLabels:(NSArray *)tickLabelArray;
- (void)setXAxisTickSpacing:(float)spacing;
- (void)setXMin:(float)xMin xMax:(float)xMax;
- (void)setYAxisLabel:(NSString *)label;
- (void)setYAxisTickLabels:(NSArray *)tickLabelArray;
- (void)setYAxisTickSpacing:(float)spacing;
- (void)setYMin:(float)yMin yMax:(float)yMax;
- (float)xMaxDisplayValue;
- (float)xMinDisplayValue;

@end
