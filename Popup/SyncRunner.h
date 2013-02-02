
#import <Foundation/Foundation.h>
#import "SyncInstruction.h"
#import "PutIOAPI.h"

typedef enum{
    SyncRunnerOperationPreflight,
    SyncRunnerOperationOriginScan,
} SyncRunnerOperation;


@class SyncRunner;
@protocol SyncRunnerDelegate <NSObject>
- (void)syncRunner:(SyncRunner*)runner willBeginOperation:(SyncRunnerOperation)operation;
- (void)syncRunnerDidFinish:(SyncRunner*)runner afterFindingFiles:(NSUInteger)fileCount;
- (void)syncRunnerDidCancel:(SyncRunner*)runner;
- (void)syncRunner:(SyncRunner*)runner didFailWithError:(NSError*)error;
@end

@interface SyncRunner : NSObject
<PutIOAPIDelegate>
{
    SyncInstruction *syncInstruction;
    PutIOAPI *putio;
    BOOL busy;
    SyncRunnerOperation currentOperation;
    
    NSMutableArray *nodeQueue;
    NSTreeNode *originTree;
    NSString *destinationPath;
    NSUInteger foundFiles;
}

@property (unsafe_unretained) id<SyncRunnerDelegate> delegate;
@property (readonly) BOOL isBusy;
@property (readonly) SyncInstruction *syncInstruction;
@property (readonly, strong) NSString *localizedOperationName;

- (id)initWithSyncInstruction:(SyncInstruction*)instruction;
- (void)run;
- (void)cancel;

@end
