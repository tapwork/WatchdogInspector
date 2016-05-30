//
//  TWWatchdogInspectorViewController.m
//  Pods
//
//  Created by Christian Menschel on 10/02/16.
//
//

#import "TWWatchdogInspectorViewController.h"

static const double kBestFrameRate = 60.0;
static const CGFloat kBarViewWidth = 10.0;
static const CGFloat kBarViewPaddingX = 8.0;
static const NSTimeInterval kBarViewAnimationDuration = 2.0;
static const CGFloat kLabelWidth = 150.0;
static NSTimeInterval lastUpdateFPSTIme = 0.0;

@interface TWWatchdogInspectorViewController ()
@property (nonatomic, nonnull) UILabel *fpsLabel;
@property (nonatomic, nonnull) UILabel *timeLabel;
@property (nonatomic, nonnull) NSHashTable <UIView*>*barViews;
@end

@implementation TWWatchdogInspectorViewController

#pragma mark - View Life Cycle

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UILabel *fpsLabel = [[UILabel alloc] init];
    fpsLabel.backgroundColor = [UIColor clearColor];
    fpsLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.view addSubview:fpsLabel];
    _fpsLabel = fpsLabel;
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.view addSubview:timeLabel];
    _timeLabel = timeLabel;
    _barViews = [NSHashTable weakObjectsHashTable];
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.fpsLabel.frame = CGRectMake(4, 0, kLabelWidth, self.view.bounds.size.height);
    self.timeLabel.frame = CGRectMake(CGRectGetMaxX(_fpsLabel.frame), 0, kLabelWidth, self.view.bounds.size.height);
}

#pragma mark - Public methods

- (void)updateFPS:(double)fps
{
    if (fps > 0) {
        self.fpsLabel.text = [NSString stringWithFormat:@"fps: %.2f", fps];
    } else {
        self.fpsLabel.text = nil;
    }
    [self updateColorWithFPS:fps];
    [self addBarWithFPS:fps];
    lastUpdateFPSTIme = [NSDate timeIntervalSinceReferenceDate];
}

- (void)updateStallingTime:(NSTimeInterval)stallingTime
{
    if (stallingTime > 0) {
        self.timeLabel.text = [NSString stringWithFormat:@"Stalling: %.2f Sec", stallingTime];
    } else {
        self.timeLabel.text = nil;
    }
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
        self.view.layer.backgroundColor = color.CGColor;
    }];
}

- (void)addBarWithFPS:(double)fps
{
    NSTimeInterval duration = kBarViewAnimationDuration;
    if (lastUpdateFPSTIme > 0) {
        duration = [NSDate timeIntervalSinceReferenceDate] - lastUpdateFPSTIme;
    }
    CGFloat xPos = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height * (fps / kBestFrameRate);
    CGFloat yPos = self.view.bounds.size.height - height;
    UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(xPos, yPos, kBarViewWidth, height)];
    barView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    [self.view addSubview:barView];
    [self.barViews addObject:barView];

    [self.view bringSubviewToFront:self.fpsLabel];
    [self.view bringSubviewToFront:self.timeLabel];
    for (UIView *barView in self.barViews) {
        [barView.layer removeAllAnimations];
        CGRect rect = barView.frame;
        rect.origin.x = rect.origin.x - rect.size.width - kBarViewPaddingX;
        [UIView animateWithDuration:duration animations:^{
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
