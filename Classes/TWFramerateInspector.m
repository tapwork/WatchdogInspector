//
//  TWFramerateInspector.m
//  Tapwork GmbH
//
//  Created by Christian Menschel on 25/01/16.
//
//

#import "TWFramerateInspector.h"
#include <mach/mach_time.h>
#import <execinfo.h>
#import <YourStatusBar/TWYourStatusBar.h>

static CFRunLoopObserverRef kObserverRef;
static CFTimeInterval kLoopTimeEntry = 0.0;
static UILabel *kTextLabel = nil;

@implementation TWFramerateInspector

static void runloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    if (activity == kCFRunLoopAfterWaiting) {
        kLoopTimeEntry = CACurrentMediaTime();
    } else if (activity == kCFRunLoopBeforeWaiting) {
        CFTimeInterval time = CACurrentMediaTime() - kLoopTimeEntry;
        double fps = 1/time;
        if (fps <= 60 && fps >= 1) {
            updateColorWithFramerate(fps);
        }
    } else if (activity == kCFRunLoopExit) {
        updateColorWithFramerate(0);
    }
}

static void updateColorWithFramerate(double framerate)
{
    //fade from green to red
    double n = 1 - (framerate/60);
    double red = (255 * n);
    double green = (255 * (1 - n));
    double blue = 0;
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    if (framerate > 0.0) {
        kTextLabel.backgroundColor = color;
        kTextLabel.text = [NSString stringWithFormat:@"Framerate: %.2f", framerate];
    } else {
        kTextLabel.backgroundColor = [UIColor lightGrayColor];
        kTextLabel.text = nil;
    }
}

#pragma mark - Start / Stop

+ (void)start
{
    [self stop];
    CFRunLoopObserverContext context = {0, (__bridge void *)(self),
        NULL,
        NULL,
        NULL
    };
    
    kObserverRef = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopObserverCallback, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
    if (!kTextLabel) {
        [self setupStatusBarLabel];
    }
}

+ (void)stop
{
    if (kObserverRef) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
        CFRelease(kObserverRef);
        kObserverRef = nil;
    }
}

- (void)dealloc
{
    [[self class] stop];
}

+ (void)setupStatusBarLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor lightGrayColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [UIFont systemFontOfSize:11];
    CGSize size = [UIApplication sharedApplication].statusBarFrame.size;
    label.frame = CGRectMake(0, 0, size.width, size.height);
    [TWYourStatusBar setCustomView:label];
    kTextLabel = label;
}

@end
