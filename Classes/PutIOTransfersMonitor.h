
@import Foundation;
#import "PutIOAPI.h"

#define PutIOTransfersMonitorUpdatedNotification @"PutIOTransfersMonitorUpdatedNotification"

@interface PutIOTransfersMonitor : NSObject

+ (instancetype)monitor;

- (void)startMonitoringTransfers;
- (void)stopMonitoringTransfers;
- (void)updateTransfers;
@property (nonatomic, readonly, copy) NSArray *allActiveTransfers;

@end
