//
//  MetatoneTouchView.m
//  Metatone
//
//  Created by Charles Martin on 17/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "MetatoneTouchView.h"
#import <QuartzCore/QuartzCore.h>

@interface MetatoneTouchView()

@property (strong, nonatomic) UIImage *lastFrame;

@property (strong, nonatomic) UIColor *touchColour;
@property (strong, nonatomic) UIColor *loopColour;
@property (strong, nonatomic) NSString *deviceID;

@end

@implementation MetatoneTouchView

- (NSMutableArray *) touchCirclePoints {
    if (!_touchCirclePoints) _touchCirclePoints = [[NSMutableArray alloc] init];
    return _touchCirclePoints;
}

- (NSMutableArray *)noteCirclePoints {
    if (!_noteCirclePoints) _noteCirclePoints = [[NSMutableArray alloc] init];
    return _noteCirclePoints;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
        if ([self.deviceID isEqual:@"1D7BCDC1-5AAB-441B-9C92-C3F00B6FF930"]) {
            self.touchColour = [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:0.8];
        } else if ([self.deviceID isEqual:@"6769FE40-5F64-455B-82D4-814E26986A99"]) {
            self.touchColour = [UIColor colorWithRed:0.1 green:0.1 blue:0.9 alpha:0.8];
        } else if ([self.deviceID isEqual:@"2678456D-9AE7-4DCC-A561-688A4766C325"]) {
            self.touchColour = [UIColor colorWithRed:0.1 green:0.9 blue:0.4 alpha:0.8];
        } else if ([self.deviceID isEqual:@"97F37307-2A95-4796-BAC9-935BF417AC42"]) {
            self.touchColour = [UIColor colorWithRed:0.9 green:0.8 blue:0.1 alpha:0.8];
        } else {
            self.touchColour = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
        }
        self.loopColour = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8];

        // init code.
        self.movingTouchCircleLayer = [self makeCircleLayerWithColour:self.touchColour];
        [self.layer addSublayer:self.movingTouchCircleLayer];
        self.movingTouchCircleLayer.hidden = YES;
        [self.layer addSublayer:self.touchCirclesLayer];
        self.touchCirclesLayer.hidden = NO;
        [self.layer addSublayer:self.loopCirclesLayer];
        self.loopCirclesLayer.hidden = NO;
    }
    return self;
}


-(void) drawTouchCircleAt:(CGPoint) point {
    CALayer *layer = [self makeCircleLayerWithColour:self.touchColour];
    layer.position = point;
    [self.layer addSublayer:layer];
    [self.touchCirclePoints addObject:layer];
    
    // reveal layer
    [layer setOpacity:(float) 0.0];
    layer.hidden = NO;
    
    [CATransaction flush];
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        [layer removeFromSuperlayer];
        [self.touchCirclePoints removeObject:layer];
    }];
    
    // Reducing animation
    CABasicAnimation *reduce = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    reduce.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    reduce.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)];
    reduce.duration = 2.0;
    
    // Fadeout animation
    CABasicAnimation *opaqueAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opaqueAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    opaqueAnimation.toValue = [NSNumber numberWithFloat:0.0];
    opaqueAnimation.duration = 2.0;
    
    [layer addAnimation:reduce forKey:@"transform.scale"];
    [layer addAnimation:opaqueAnimation forKey:@"opacity"];
    
    [CATransaction commit];
}

-(void) drawNoteCircleAt:(CGPoint) point {
    CALayer *layer = [self makeCircleLayerWithColour:self.loopColour];
    [self.layer addSublayer:layer];
    [self.noteCirclePoints addObject:layer];
    layer.position = point;
    layer.hidden = NO;
    
    [layer setOpacity:(float) 0.0];
    layer.hidden = NO;
    
    [CATransaction flush];
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        layer.hidden = YES;
        [layer removeFromSuperlayer];
        [self.touchCirclePoints removeObject:layer];
    }];
    
    // expand animation
    float scaleFactor = 1.3 + arc4random_uniform(100)/33;
    CABasicAnimation *expand = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    expand.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    expand.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleFactor, scaleFactor, 1.0)];
    expand.duration = 2.9;
    expand.fillMode = kCAFillModeForwards;
    expand.removedOnCompletion = NO;
    
    // fadeout animation
    CABasicAnimation *opaqueAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opaqueAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    opaqueAnimation.toValue = [NSNumber numberWithFloat:0.0];
    opaqueAnimation.duration = 3.0;
    expand.fillMode = kCAFillModeForwards;
    opaqueAnimation.removedOnCompletion = NO;
    
    [layer addAnimation:expand forKey:@"transform.scale"];
    [layer addAnimation:opaqueAnimation forKey:@"opacity"];
    [CATransaction commit];
}

-(CALayer *) makeCircleLayerWithColour:(UIColor *) colour {
    CALayer *layer = [[CALayer alloc] init];
    layer.backgroundColor = colour.CGColor;
    layer.shadowOffset = CGSizeMake(0, 3);
    layer.shadowRadius = 5.0;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.8;
    layer.frame = CGRectMake(0, 0, 50, 50);
    layer.cornerRadius = 25.0;
    layer.hidden = YES;
    return layer;
}

-(void) drawMovingTouchCircleAt:(CGPoint)point {
    self.movingTouchCircleLayer.hidden = NO;
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.0];
    [self.movingTouchCircleLayer setOpacity:(float) 1.0];
    self.movingTouchCircleLayer.position = point;
    [CATransaction commit];
}

-(void) hideMovingTouchCircle {
    // reveal layer
    [self.movingTouchCircleLayer setOpacity:(float) 0.0];
    
    [CATransaction flush];
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        self.movingTouchCircleLayer.hidden = YES;
    }];
    // Fadeout animation
    CABasicAnimation *opaqueAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opaqueAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    opaqueAnimation.toValue = [NSNumber numberWithFloat:0.0];
    opaqueAnimation.duration = 1.0;
    [self.movingTouchCircleLayer addAnimation:opaqueAnimation forKey:@"opacity"];
    [CATransaction commit];
}

@end
