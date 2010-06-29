//
//  RMCircle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/28/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "RMCircle.h"
#import "RMMapContents.h"
#import "RMMapView.h"
#import "RMMercatorToScreenProjection.h"
#import "RMPixel.h"
#import "RMProjection.h"

#define kDefaultLineWidth 100
#define kDefaultLineColor [UIColor blackColor]
#define kDefaultFillColor [UIColor redColor]

@interface RMCircle (RMCirclePrivate)

@property (nonatomic, assign) RMProjectedPoint projectedLocation;

- (void)recalculateGeometry;

@end

#pragma mark -

@implementation RMCircle

@synthesize scaleLineWidth;
@synthesize projectedLocation;
@synthesize enableDragging;
@synthesize enableRotation;

- (id)initWithContents:(RMMapContents *)inContents centerCoordinate:(RMLatLong)centerCoordinate radius:(float)meterRadius
{
	if ( ! [super init])
		return nil;
	
	contents = inContents;
    
	lineWidth   = kDefaultLineWidth;
	drawingMode = kCGPathFillStroke;
	lineColor   = kDefaultLineColor;
	fillColor   = kDefaultFillColor;
	
	self.masksToBounds = YES;
	
	scaleLineWidth = NO;
	enableDragging = YES;
	enableRotation = YES;
    
    projectedLocation = [[contents projection] latLongToPoint:centerCoordinate];
    
    path = CGPathCreateMutable();

    self.position = [[contents mercatorToScreenProjection] projectXYPoint:projectedLocation];
    
    float pixelRadius = meterRadius / contents.metersPerPixel;
    
    float scaledLineWidth = lineWidth;

	if ( ! scaleLineWidth)
    {
		renderedScale = [contents metersPerPixel];
		scaledLineWidth *= renderedScale;
	}
    
    CGRect rectangle = CGRectMake(self.position.x - pixelRadius - scaledLineWidth, 
                                  self.position.y - pixelRadius - scaledLineWidth, 
                                  (pixelRadius * 2) + (2 * scaledLineWidth), 
                                  (pixelRadius * 2) + (2 * scaledLineWidth));
    
    CGPathAddEllipseInRect(path, NULL, rectangle);
    
    [self recalculateGeometry];
    [self setNeedsDisplay];
    
	return self;
}

- (id)initForMap:(RMMapView *)map centerCoordinate:(RMLatLong)centerCoordinate radius:(float)meterRadius
{
	return [self initWithContents:[map contents] centerCoordinate:centerCoordinate radius:meterRadius];
}

- (void)dealloc
{
    CGPathRelease(path);
    
    [self setLineColor:nil];
    [self setFillColor:nil];
	
	[super dealloc];
}

#pragma mark -

- (float)lineWidth
{
	return lineWidth;
}

- (void)setLineWidth:(float)newLineWidth
{
	lineWidth = newLineWidth;
	
    [self recalculateGeometry];
	[self setNeedsDisplay];
}

- (CGPathDrawingMode)drawingMode
{
	return drawingMode;
}

- (void)setDrawingMode:(CGPathDrawingMode)newDrawingMode
{
	drawingMode = newDrawingMode;
    
	[self setNeedsDisplay];
}

- (UIColor *)lineColor
{
    return lineColor; 
}

- (void)setLineColor:(UIColor *)aLineColor
{
    if (lineColor != aLineColor)
    {
        [lineColor release];
        lineColor = [aLineColor retain];

		[self setNeedsDisplay];
    }
}

- (UIColor *)fillColor
{
    return fillColor; 
}

- (void)setFillColor:(UIColor *)aFillColor
{
    if (fillColor != aFillColor)
    {
        [fillColor release];
        fillColor = [aFillColor retain];
		
        [self setNeedsDisplay];
    }
}

#pragma mark -

- (id <CAAction>)actionForKey:(NSString *)key
{
	return nil;
}

- (void)recalculateGeometry
{
	float scale = [[contents mercatorToScreenProjection] metersPerPixel];
	float scaledLineWidth;
	CGPoint myPosition;
	CGRect pixelBounds, screenBounds;
	float offset;
	const float outset = 100.0f; // provides a buffer off screen edges for when path is scaled or moved
	
	
	// The bounds are actually in mercators...
	/// \bug if "bounds are actually in mercators", shouldn't be using a CGRect
	scaledLineWidth = lineWidth;
	if(!scaleLineWidth) {
		renderedScale = [contents metersPerPixel];
		scaledLineWidth *= renderedScale;
	}
	
	CGRect boundsInMercators = CGPathGetBoundingBox(path);
	boundsInMercators.origin.x -= scaledLineWidth;
	boundsInMercators.origin.y -= scaledLineWidth;
	boundsInMercators.size.width += 2*scaledLineWidth;
	boundsInMercators.size.height += 2*scaledLineWidth;
	
	pixelBounds = CGRectInset(boundsInMercators, -scaledLineWidth, -scaledLineWidth);
	
	pixelBounds = RMScaleCGRectAboutPoint(pixelBounds, 1.0f / scale, CGPointZero);
	
	// Clip bound rect to screen bounds.
	// If bounds are not clipped, they won't display when you zoom in too much.
	myPosition = [[contents mercatorToScreenProjection] projectXYPoint: projectedLocation];
	screenBounds = [contents screenBounds];
	
	// Clip top
	offset = myPosition.y + pixelBounds.origin.y - screenBounds.origin.y + outset;
	if(offset < 0.0f) {
		pixelBounds.origin.y -= offset;
		pixelBounds.size.height += offset;
	}
	// Clip left
	offset = myPosition.x + pixelBounds.origin.x - screenBounds.origin.x + outset;
	if(offset < 0.0f) {
		pixelBounds.origin.x -= offset;
		pixelBounds.size.width += offset;
	}
	// Clip bottom
	offset = myPosition.y + pixelBounds.origin.y + pixelBounds.size.height - screenBounds.origin.y - screenBounds.size.height - outset;
	if(offset > 0.0f) {
		pixelBounds.size.height -= offset;
	}
	// Clip right
	offset = myPosition.x + pixelBounds.origin.x + pixelBounds.size.width - screenBounds.origin.x - screenBounds.size.width - outset;
	if(offset > 0.0f) {
		pixelBounds.size.width -= offset;
	}
	
	self.position = myPosition;
	self.bounds = pixelBounds;
	//RMLog(@"x:%f y:%f screen bounds: %f %f %f %f", myPosition.x, myPosition.y,  screenBounds.origin.x, screenBounds.origin.y, screenBounds.size.width, screenBounds.size.height);
	//RMLog(@"new bounds: %f %f %f %f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
	
	self.anchorPoint = CGPointMake(-pixelBounds.origin.x / pixelBounds.size.width,-pixelBounds.origin.y / pixelBounds.size.height);
	[self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)theContext
{
	renderedScale = [contents metersPerPixel];
	
	float scale = 1.0f / [contents metersPerPixel];
	
	float scaledLineWidth = lineWidth;
	
    if ( ! scaleLineWidth)
		scaledLineWidth *= renderedScale;
    
	CGContextScaleCTM(theContext, scale, scale);
    
    CGContextBeginPath(theContext);
    CGContextAddPath(theContext, path); 

    CGContextSetLineWidth(theContext, scaledLineWidth);
	CGContextSetStrokeColorWithColor(theContext, [lineColor CGColor]);
	CGContextSetFillColorWithColor(theContext, [fillColor CGColor]);
    
	CGContextDrawPath(theContext, drawingMode);
}

#pragma mark -

- (void)moveBy:(CGSize)delta
{
	if (enableDragging)
    {
		[super moveBy:delta];
        
		[self recalculateGeometry];
	}
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)pivot
{
	[super zoomByFactor:zoomFactor near:pivot];
	
    // don't redraw if the path hasn't been scaled very much
	float newScale = [contents metersPerPixel];
	
    if (newScale / renderedScale >= 1.10f || newScale / renderedScale <= 0.90f)
	{
		[self recalculateGeometry];
		[self setNeedsDisplay];
	}
}

@end