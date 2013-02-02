
#import "PutIOTransfersMonitor.h"

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
        api = [PutIOAPI apiWithDelegate:self];
    }
    return self;
}

-(void)startMonitoringTransfers
{
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
    [api activeTransfers];
}

-(NSArray *)allActiveTransfers
{
    return activeTransfers;
}

-(void)api:(PutIOAPI *)api didFinishRequest:(PutIOAPIRequest)request withResult:(id)result
{
    activeTransfers = (NSArray*)result;
    [[NSNotificationCenter defaultCenter] postNotificationName:TransfersUpdatedNotification object:nil];
    // Update again in a few seconds:
    updateTransfersTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTransfers) userInfo:nil repeats:NO];
}

@end
