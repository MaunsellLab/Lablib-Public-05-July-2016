//
//  LLHistView.h
//  Lablib
//
//  Created by John Maunsell on Thu May 01 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLViewScale.h"

#define kDefaultBins		50
#define kHighlightPix		1
#define kLLMarginPix			2
#define kLabelExtraPix		15						// Extra margin for x tick labels
#define kShadowPix			1

#define topMarginPix		(kHighlightPix + kLLMarginPix + textLineHeightPix)
#define leftMarginPix		(kHighlightPix + kLLMarginPix + 2 * textLineHeightPix + kTickHeightPix)
#define kRightMarginPix		(kShadowPix + kHighlightPix + kLLMarginPix + kLabelExtraPix)
#define bottomMarginPix		(kShadowPix + kHighlightPix + kLLMarginPix + 2 * textLineHeightPix + kTickHeightPix)

typedef struct {
    float	xMin;
    float	xMax;
    long 	yPix;
    NSColor *color;
} XHistAxisMark;
    
@interface LLHistView : NSView {

    BOOL				autoBinWidth;				// auto adjust binwidth
	NSMutableArray		*colorArray;
    double				*data;						// pointer to data array
	NSMutableArray		*dataArray;
    long				dataLength;					// length of data array
	NSMutableArray		*enableArray;
    BOOL				highlight;					// whether the histogram view is highlighted
    BOOL				hidden;
    NSColor				*histColor;
    float				maxBin;						// value of largest plotting bin
    NSMutableArray		*marks;
    long 				plotBins;					// number of bins to plot
    LLViewScale			*scale;
    BOOL				sumWhenBinning;				// controls whether values are summed or averaged
    NSString			*title;
    float				textLineHeightPix;
    BOOL				useXDisplayValues;
    BOOL				useYDisplayValues;
    NSString			*xAxisLabel;
    float				xMaxDisplayValue;			// Values written on the axes
    float				xMinDisplayValue;
    float				xTickLabelSpacing;
    float				xTickSpacing;
    NSString			*yAxisLabel;						
    float				yMaxDisplayValue;						
    float				yMinDisplayValue;
    NSMutableArray		*yUnitArray;					
}

- (void)clearAllFills;
- (void)disableAll;
- (void)enableAll;
- (void)fillXAxisFrom:(float)xMin to:(float)xMax heightPix:(long)heightPix color:(NSColor *)color; 
- (void)fillXFrom:(float)xMin to:(float)xMax color:(NSColor *)color; 
- (void)handleScaleChange:(NSNotification *)note;
- (void)hide:(BOOL)state;
- (void)initializeHistView;
- (id)initWithFrame:(NSRect)frame scaling:(LLViewScale *)histScale; 
- (void)setAutoBinWidth:(BOOL)state;
- (void)setData:(double *)histData length:(long)histLength color:(NSColor *)color;
- (void)setDataLength:(long)length;
- (void)setDisplayXMin:(float)xMin xMax:(float)xMax;
- (void)setDisplayYMin:(float)yMin yMax:(float)yMax;
- (void)setHighlightHist:(BOOL)state;
- (void)setPlotBins:(long)binsToPlot;
- (void)setScale:(LLViewScale *)newScaling;
- (void)setSumWhenBinning:(BOOL)state;
- (void)setTitle:(NSString *)string;
- (void)setXAxisLabel:(NSString *)label;
- (void)setXAxisTickLabelSpacing:(float)spacing;
- (void)setXAxisTickSpacing:(float)spacing;
- (void)setYAxisLabel:(NSString *)label;
- (void)setYUnit:(double)unitValue;
- (void)setYUnit:(double)unitValue index:(long)index;

@end
