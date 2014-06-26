
#import <Foundation/Foundation.h>
#import "SyncInstruction.h"
#import "PutIOAPI.h"

@class SyncRunner;
@protocol SyncRunnerDelegate <NSObject>
- (void)syncRunnerDidFinish:(SyncRunner*)runner afterFindingFiles:(NSUInteger)fileCount;
- (void)syncRunnerDidCancel:(SyncRunner*)runner;
- (void)syncRunner:(SyncRunner*)runner didFailWithError:(NSError*)error;
@end

@interface SyncRunner : NSObject

@property (unsafe_unretained) id<SyncRunnerDelegate> delegate;
@property (readonly) BOOL isBusy;
@property (readonly) SyncInstruction *syncInstruction;
@property (readonly, strong) NSString *localizedOperationName;

- (id)initWithSyncInstruction:(SyncInstruction*)instruction;
- (void)run;
- (void)cancel;

@end
