
#import "SyncScheduler.h"
#import "PutIODownload.h"
#import "ApplicationDelegate.h"

@implementation SyncScheduler

static SyncScheduler* sharedInstance;

+(id)sharedSyncScheduler
{
    if(!sharedInstance)
        sharedInstance = [[SyncScheduler alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.runningSyncs = [NSMutableArray array];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver:self
                   forKeyPath:@"general_syncinterval"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    [self scheduleSyncs];
}

-(void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"general_syncinterval"];
    [timer invalidate];
}

-(void)scheduleSyncs
{
    if(timer)
        [timer invalidate];
    NSInteger intervalPreset = [[NSUserDefaults standardUserDefaults] integerForKey:@"general_syncinterval"];
    NSTimeInterval interval = 0;
    if(intervalPreset == 0)
        interval = 60; // Every minute
    if(intervalPreset == 1)
        interval = 60 * 5; // Every 5 minutes
    if(intervalPreset == 2)
        interval = 60 * 10;
    if(intervalPreset == 3)
        interval = 60 * 30;
    if(intervalPreset == 4)
        interval = 60 * 60;
    if(interval == 0)
        return;
    timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(startSyncingAll) userInfo:nil repeats:YES];
    
    NSLog(@"%@ scheduled sync every %f seconds", self, interval);
}

-(void)startSyncingAll
{
    if(![[PutIOAPI api] isAuthenticated])
        return;
    if([self.runningSyncs count] > 0)
        return;
    foundFiles = 0;
    for(SyncInstruction *instruction in [SyncInstruction allSyncInstructions]){
        SyncRunner *runner = [[SyncRunner alloc] initWithSyncInstruction:instruction];
        [runner setDelegate:self];
        [runner run];
        [self.runningSyncs addObject:runner];
        [[NSNotificationCenter defaultCenter] postNotificationName:SyncSchedulerSyncDidChangeNotification object:runner];
    }
}

-(void)cancelAllSyncsInProgress
{
    for(SyncRunner *runner in self.runningSyncs)
        [runner cancel];
}

-(void)cancelSyncForInstruction:(SyncInstruction*)instruction
{
    for(SyncRunner *runner in self.runningSyncs)
        if([runner.syncInstruction.objectID.URIRepresentation isEqual:instruction.objectID.URIRepresentation])
            [runner cancel];
}

//-(BOOL)syncForInstructionIsInProgess:(SyncInstruction*)instruction
//{
//    for(SyncRunner *runner in self.runningSyncs)
//        if([runner.syncInstruction uniqueID] == instruction.uniqueID) return YES;
//    return NO;
//}

#pragma mark - Sync Runner Delegate

-(void)syncRunner:(SyncRunner *)runner didFailWithError:(NSError *)error
{
    [self.runningSyncs removeObject:runner];
    [[NSNotificationCenter defaultCenter] postNotificationName:SyncSchedulerSyncDidChangeNotification object:runner];
    [self deliverNotificationConditionally];
}

-(void)syncRunnerDidFinish:(SyncRunner *)runner afterFindingFiles:(NSUInteger)fileCount
{
    [self.runningSyncs removeObject:runner];
    [[NSNotificationCenter defaultCenter] postNotificationName:SyncSchedulerSyncDidChangeNotification object:runner];
    foundFiles += fileCount;
    [self deliverNotificationConditionally];
}

-(void)syncRunnerDidCancel:(SyncRunner *)runner
{
    [self.runningSyncs removeObject:runner];
    [[NSNotificationCenter defaultCenter] postNotificationName:SyncSchedulerSyncDidChangeNotification object:runner];
    [self deliverNotificationConditionally];
}

-(void)deliverNotificationConditionally
{
    if([self.runningSyncs count] == 0 && foundFiles > 0){
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%i files from put.io began downloading",nil),
                             foundFiles];
        [(ApplicationDelegate*)[NSApp delegate] deliverUserNotificationWithIdentifier:@"newfiles" message:message];
    }
}

@end
