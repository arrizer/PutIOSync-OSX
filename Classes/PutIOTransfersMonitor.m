
#import "PutIOTransfersMonitor.h"
#import "PutIOAPITransfersRequest.h"

@interface PutIOTransfersMonitor()
{
    NSArray *activeTransfers;
    NSTimer *updateTransfersTimer;
    PutIOAPI *api;
}
@end

@implementation PutIOTransfersMonitor

static PutIOTransfersMonitor *sharedInstance;

+(instancetype)monitor
{
    if(!sharedInstance)
        sharedInstance = [[PutIOTransfersMonitor alloc] init];
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        activeTransfers = @[];
        api = [PutIOAPI api];
    }
    return self;
}

-(void)startMonitoringTransfers
{
    [self stopMonitoringTransfers];
    [self updateTransfers];
}

-(void)stopMonitoringTransfers
{
    if(updateTransfersTimer != nil){
        [updateTransfersTimer invalidate];
        updateTransfersTimer = nil;
    }
}

-(void)updateTransfers
{
    __block PutIOAPITransfersRequest *request = [PutIOAPITransfersRequest requestAllTransfersWithCompletion:^{
        if(request.error == nil && !request.isCancelled){
            activeTransfers = request.transfers;
            [[NSNotificationCenter defaultCenter] postNotificationName:PutIOTransfersMonitorUpdatedNotification object:nil];
            // Update again in a few seconds:
            updateTransfersTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTransfers) userInfo:nil repeats:NO];
        }
    }];
    [api performRequest:request];
}

-(NSArray *)allActiveTransfers
{
    return activeTransfers;
}

@end
