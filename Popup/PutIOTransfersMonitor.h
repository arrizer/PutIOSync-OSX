
#import <Foundation/Foundation.h>
#import "PutIOAPI.h"

#define TransfersUpdatedNotification @"putioTransfersUpdated"

@interface PutIOTransfersMonitor : NSObject
<PutIOAPIDelegate>
{
    NSArray *activeTransfers;
    NSTimer *updateTransfersTimer;
    PutIOAPI *api;
}

+ (id)monitor;

- (void)startMonitoringTransfers;
- (void)stopMonitoringTransfers;
- (void)updateTransfers;
- (NSArray*)allActiveTransfers;

@end
