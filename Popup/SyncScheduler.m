
#import "SyncScheduler.h"
#import "PutIODownload.h"

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
    }
    return self;
}

-(void)startSyncingAll
{
    if([PutIOAPI oAuthAccessToken] == nil)
        return;
    for(SyncInstruction *instruction in [SyncInstruction allSyncInstructions]){
        if(![self syncForInstructionIsInProgess:instruction]){
            SyncRunner *runner = [[SyncRunner alloc] initWithSyncInstruction:instruction];
            [runner setDelegate:self];
            [runner run];
            [self.runningSyncs addObject:runner];
            [[NSNotificationCenter defaultCenter] postNotificationName:SyncDidBeginOrFinishNotification object:runner];
        }
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
        if([runner.syncInstruction uniqueID] == instruction.uniqueID)
            [runner cancel];
}

-(BOOL)syncForInstructionIsInProgess:(SyncInstruction*)instruction
{
    for(SyncRunner *runner in self.runningSyncs)
        if([runner.syncInstruction uniqueID] == instruction.uniqueID) return YES;
    return NO;
}

#pragma mark - Sync Runner Delegate

-(void)syncRunner:(SyncRunner *)runner willBeginOperation:(SyncRunnerOperation)operation
{
    
}

-(void)syncRunner:(SyncRunner *)runner didFailWithError:(NSError *)error
{
    
}

-(void)syncRunnerDidFinish:(SyncRunner *)runner
{
    [self.runningSyncs removeObject:runner];
    [[NSNotificationCenter defaultCenter] postNotificationName:SyncDidBeginOrFinishNotification object:runner];
}

-(void)syncRunnerDidCancel:(SyncRunner *)runner
{
    [self.runningSyncs removeObject:runner];
    [[NSNotificationCenter defaultCenter] postNotificationName:SyncDidBeginOrFinishNotification object:runner];
}

@end
