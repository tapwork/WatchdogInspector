//
//  TWWatchdogInspectorStatusBarView.m
//  Pods
//
//  Created by Christian Menschel on 10/02/16.
//
//

#import "TWWatchdogInspectorStatusBarView.h"

static const double kBestFrameRate = 60.0;
static const CGFloat kBarViewWidth = 10.0;
static const CGFloat kBarViewPaddingX = 8.0;
static const CGFloat kBarViewAnimationDuration = 2.0;

@interface TWWatchdogInspectorStatusBarView ()
@property (nonatomic, nonnull) UILabel *label;
@property (nonatomic, nonnull) NSHashTable *barViews;
@end

@implementation TWWatchdogInspectorStatusBarView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];

        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:14];
        label.numberOfLines = 2;
        [self addSubview:label];
        _label = label;
        
        _barViews = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _label.frame = CGRectInset(self.bounds, 4, 0);
}

#pragma mark - Public methods

- (void)updateLabelWithFPS:(double)fps stallingTime:(NSTimeInterval)stallingTime
{
    if (fps > 0.0) {
        self.label.text = [NSString stringWithFormat:@"fps: %.2f\nStalling: %.2f Sec", fps, stallingTime];
    } else {
        self.label.text = nil;
    }

    [self updateColorWithFPS:fps];
    [self addBarWithFPS:fps];
}

#pragma mark - Private methods

- (void)updateColorWithFPS:(double)fps
{
    //fade from green to red
    double n = 1 - (fps/kBestFrameRate);
    double red = (255 * n);
    double green = (255 * (1 - n)/2);
    double blue = 0;
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    if (fps == 0.0) {
        color = [UIColor lightGrayColor];
    }

    [UIView animateWithDuration:0.2 animations:^{
        self.layer.backgroundColor = color.CGColor;
    }];
}

- (void)addBarWithFPS:(double)fps
{
    CGFloat height = self.bounds.size.height * (fps / kBestFrameRate);
    CGFloat xPos = self.bounds.size.width;
    CGFloat yPos = self.bounds.size.height - height;
    UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(xPos, yPos, kBarViewWidth, height)];
    barView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    [self addSubview:barView];
    [self.barViews addObject:barView];
    [self animateBarViews];
}

- (void)animateBarViews {
    [self bringSubviewToFront:self.label];
    for (UIView *barView in self.barViews) {
        CGRect rect = barView.frame;
        rect.origin.x = rect.origin.x - rect.size.width - kBarViewPaddingX;
        [UIView animateWithDuration:kBarViewAnimationDuration animations:^{
            barView.frame = rect;
        } completion:^(BOOL finished) {
            if (finished) {
                [self removeBarViewIfNeeded:barView];
            }
        }];
    }
}

- (void)removeBarViewIfNeeded:(UIView *)barView
{
    if (CGRectGetMaxX(barView.frame) <= -kBarViewPaddingX) {
        [barView removeFromSuperview];
    }
}

@end
