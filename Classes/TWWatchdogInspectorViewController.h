//
//  TWWatchdogInspectorViewController.h
//  Pods
//
//  Created by Christian Menschel on 10/02/16.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TWWatchdogInspectorViewController : UIViewController

- (void)updateFPS:(double)fps;
- (void)updateStallingTime:(NSTimeInterval)stallingTime;


@end

NS_ASSUME_NONNULL_END
