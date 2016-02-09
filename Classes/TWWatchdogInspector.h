//
//  TWWatchdogInspector.h
//  Tapwork GmbH
//
//  Created by Christian Menschel on 25/01/16.
//
//

#import <Foundation/Foundation.h>

@interface TWWatchdogInspector : NSObject

+ (void)start;
+ (void)stop;

/**
 *  The timeout in seconds for mainthread stalling.
 *  If the mainthread stalls longer than this given time,
 *  an exception will be thrown.
 *  Default is 3 seconds
 */
+ (void)setStallingThreshhold:(NSTimeInterval)time;

@end
