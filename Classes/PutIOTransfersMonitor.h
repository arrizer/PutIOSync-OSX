
#import <Foundation/Foundation.h>
#import "PutIOAPI.h"

#define PutIOTransfersMonitorUpdatedNotification @"PutIOTransfersMonitorUpdatedNotification"

@interface PutIOTransfersMonitor : NSObject

+ (id)monitor;

- (void)startMonitoringTransfers;
- (void)stopMonitoringTransfers;
- (void)updateTransfers;
- (NSArray*)allActiveTransfers;

@end
