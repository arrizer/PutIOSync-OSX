
#import "PutIOTransfersMonitor.h"

@interface PutIOTransfersMonitor()
{
    NSArray *activeTransfers;
    NSTimer *updateTransfersTimer;
    PutIOAPI *api;
}
@end

@implementation PutIOTransfersMonitor

static PutIOTransfersMonitor *sharedInstance;

+(id)monitor
{
    if(!sharedInstance)
        sharedInstance = [[PutIOTransfersMonitor alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        activeTransfers = [NSArray array];
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
    [api activeTransfersWithCompletion:^(id result, NSError *error, BOOL cancelled) {
        if(error == nil && !cancelled){
            activeTransfers = (NSArray*)result;
            [[NSNotificationCenter defaultCenter] postNotificationName:PutIOTransfersMonitorUpdatedNotification object:nil];
            // Update again in a few seconds:
            updateTransfersTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTransfers) userInfo:nil repeats:NO];
        }
    }];
}

-(NSArray *)allActiveTransfers
{
    return activeTransfers;
}

@end
