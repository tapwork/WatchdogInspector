//
//  TWWatchdogInspectorStatusBarView.m
//  Pods
//
//  Created by Christian Menschel on 10/02/16.
//
//

#import "TWWatchdogInspectorStatusBarView.h"

@interface TWWatchdogInspectorStatusBarView ()

@property (nonatomic, nonnull) UILabel *label;

@end

@implementation TWWatchdogInspectorStatusBarView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];

        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:11];
        [self addSubview:label];
        _label = label;
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];

    _label.frame = self.bounds;
}

#pragma mark - Setter

- (void)setFps:(double)fps
{
    _fps = fps;
    [self updateColorWithFPS:fps];
}

- (void)updateColorWithFPS:(double)fps
{
    //fade from green to red
    double n = 1 - (fps/60);
    double red = (255 * n);
    double green = (255 * (1 - n)/2);
    double blue = 0;
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    if (fps > 0.0) {
        self.backgroundColor = color;
        self.label.text = [NSString stringWithFormat:@"fps: %.2f", fps];
    } else {
        self.backgroundColor = [UIColor lightGrayColor];
        self.label.text = nil;
    }
}

@end
