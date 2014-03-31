
#import "SyncRunner.h"
#import "PutIODownload.h"

@interface SyncRunner()
@property (strong) NSString *localizedOperationName;
@end

@implementation SyncRunner

- (id)initWithSyncInstruction:(SyncInstruction*)instruction
{
    self = [super init];
    if (self) {
        syncInstruction = instruction;
        putio = [PutIOAPI api];
        self.localizedOperationName = NSLocalizedString(@"Looking for items to download", nil);
    }
    return self;
}

-(BOOL)isBusy
{
    return busy;
}

-(SyncInstruction *)syncInstruction
{
    return syncInstruction;
}

-(void)run
{
    if([self isBusy])
        return;
    //NSLog(@"%@ sync run began", [self description]);
    foundFiles = 0;
//    [self performPreflightChecks];
    [self deepScanOrigin];
}

- (void)cancel
{
    [putio cancel];
    if([_delegate respondsToSelector:@selector(syncRunnerDidCancel:)])
        [_delegate syncRunnerDidCancel:self];
}

#pragma mark - Scan Origin

-(void)deepScanOrigin
{
//    [self beginOperation:SyncRunnerOperationOriginScan];
    [putio cancel];
    originTree = nil;
    nodeQueue = [NSMutableArray array];
    [nodeQueue addObject:[NSNull null]];
    [self scanNextOriginItem];
}

-(void)scanNextOriginItem
{
    PutIOAPICompletionBlock completion = ^(id result, NSError *error, BOOL cancelled){
        if(error == nil && !cancelled){
            NSTreeNode *currentNode = nil;
            if([nodeQueue objectAtIndex:0] == [NSNull null]){
                originTree = [[NSTreeNode alloc] initWithRepresentedObject:result[@"parent"]];
                currentNode = originTree;
            }else{
                currentNode = [nodeQueue objectAtIndex:0];
            }
            for(PutIOAPIFile *file in result[@"files"]){
                NSTreeNode *node = [[NSTreeNode alloc] initWithRepresentedObject:file];
                [[currentNode mutableChildNodes] addObject:node];
                if([file isFolder]){
                    if(syncInstruction.recursive)
                        [nodeQueue addObject:node];
                }else{
                    [self evaulateFileAtNode:node];
                }
            }
            [nodeQueue removeObjectAtIndex:0];
            
            PutIOAPIFile *folder = result[@"parent"];
            if(syncInstruction.deleteRemoteEmptyFolders && folder.fileID != syncInstruction.originFolderID && [result[@"files"] count] == 0){
                NSLog(@"Deleting empty folder");
                [putio deleteFileWithID:folder.fileID completion:^(id result, NSError *error, BOOL cancelled) {
                    [self scanNextOriginItem];
                }];
            }else{
                [self scanNextOriginItem];
            }
        }else{
            [self failWithError:error];
        }
    };
    
    if([nodeQueue count] > 0){
        id nextNode = [nodeQueue objectAtIndex:0];
        if(nextNode == [NSNull null]){
            NSLog(@"%@ scanning put.io folder: %@", [self description], syncInstruction.originFolderName);
            [putio filesInFolderWithID:syncInstruction.originFolderID completion:completion];
        }else{
            PutIOAPIFile *folder = (PutIOAPIFile*)[(NSTreeNode*)nextNode representedObject];
            NSLog(@"%@ scanning put.io folder: %@", [self description], [folder name]);
            [putio filesInFolderWithID:[folder fileID] completion:completion];
        }
    }else{
        originTree = nil;
        nodeQueue = nil;
        [self finish];
    }
}

-(void)evaulateFileAtNode:(NSTreeNode*)node
{
    PutIOAPIFile *file = [node representedObject];
    if([syncInstruction itemWithIDIsKnown:[file fileID]])
        return;
    NSString *relativePath = nil;
    if(!syncInstruction.flattenSubdirectories)
        relativePath = [self relativePathOfFileAtNode:node];
    //NSString *filename = [file name];

    if(![PutIODownload downloadExistsForFile:file]){
        //NSLog(@"%@ found file to download: %@/%@", [self description], relativePath, filename);
        NSString *localPath = [syncInstruction.localDestination relativePath];
        PutIODownload *download = [[PutIODownload alloc] initWithPutIOFile:file
                                                                 localPath:localPath
                                                          subdirectoryPath:relativePath 
                                                originatingSyncInstruction:syncInstruction];
        [download startDownload];
        foundFiles++;
    }
    //[syncInstruction addKnownItemWithID:[file fileID]];
}

- (NSString*)relativePathOfFileAtNode:(NSTreeNode*)node
{
    NSMutableArray *parentFolderNames = [NSMutableArray array];
    NSTreeNode *parentNode = [node parentNode];
    while(parentNode != nil && parentNode != originTree){
        NSString *folderName = [(PutIOAPIFile*)[parentNode representedObject] name];
        [parentFolderNames insertObject:folderName atIndex:0];
        parentNode = [parentNode parentNode];
    }
    NSString *relativePath = @"";
    if([parentFolderNames count] > 0)
        relativePath = [parentFolderNames componentsJoinedByString:@"/"];
    return relativePath;
}

#pragma mark - Flow Control

-(void)failWithError:(NSError*)error
{
    if([_delegate respondsToSelector:@selector(syncRunner:didFailWithError:)])
       [_delegate syncRunner:self didFailWithError:error];
}

-(void)finish
{
    NSLog(@"%@ sync run finished", [self description]);
    syncInstruction.lastSynced = [NSDate date];
    [SyncInstruction saveAllSyncInstructions];
//    if([downloadQueue count] > 0)
//        if([_delegate respondsToSelector:@selector(syncRunner:foundFilesForDownload:)])
//            [_delegate syncRunner:self foundFilesForDownload:downloadQueue];
    if([_delegate respondsToSelector:@selector(syncRunnerDidFinish:afterFindingFiles:)])
        [_delegate syncRunnerDidFinish:self afterFindingFiles:foundFiles];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"SyncRunner<%@>", syncInstruction.originFolderName];
}

@end
