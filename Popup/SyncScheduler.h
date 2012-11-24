
#import <Foundation/Foundation.h>
#import "SyncRunner.h"
#import "SyncInstruction.h"

#define SyncDidBeginOrFinishNotification @"runningSyncsDidChange"

@interface SyncScheduler : NSObject
<SyncRunnerDelegate>
{
    NSUInteger foundFiles;
    NSTimer *timer;
}

+(id)sharedSyncScheduler;

@property (strong) NSMutableArray *runningSyncs;

-(void)scheduleSyncs;
-(void)startSyncingAll;
-(void)cancelAllSyncsInProgress;
-(void)cancelSyncForInstruction:(SyncInstruction*)instruction;

@end
