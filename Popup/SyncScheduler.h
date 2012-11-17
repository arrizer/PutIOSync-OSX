
#import <Foundation/Foundation.h>
#import "SyncRunner.h"
#import "SyncInstruction.h"

#define SyncDidBeginOrFinishNotification @"runningSyncsDidChange"

@interface SyncScheduler : NSObject
<SyncRunnerDelegate>
{

}

+(id)sharedSyncScheduler;

@property (strong) NSMutableArray *runningSyncs;

-(void)startSyncingAll;
-(void)cancelAllSyncsInProgress;
-(void)cancelSyncForInstruction:(SyncInstruction*)instruction;

@end
