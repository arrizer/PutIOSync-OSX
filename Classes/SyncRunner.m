
#import "SyncRunner.h"
#import "PutIODownloadManager.h"
#import "PutIOAPIFileRequest.h"
#import "PutIOAPIFileDeletionRequest.h"
#import "Download.h"

@interface SyncRunner()
{
    SyncInstruction *syncInstruction;
    PutIOAPI *putio;
    BOOL busy;
    
    NSTreeNode *originTree;
    NSString *destinationPath;
    NSUInteger foundFiles;
    NSUInteger pendingRequests;
}

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
    [putio cancelAllRequests];
    if([_delegate respondsToSelector:@selector(syncRunnerDidCancel:)])
        [_delegate syncRunnerDidCancel:self];
}

#pragma mark - Scan Origin

-(void)deepScanOrigin
{
//    [self beginOperation:SyncRunnerOperationOriginScan];
    [putio cancelAllRequests];
    originTree = nil;
    [self scanNode:nil];
}

-(void)scanNode:(NSTreeNode*)node
{
    NSInteger folderID;
    if(node == nil){
        folderID = [syncInstruction.originFolderID integerValue];
    }else{
        folderID = ((PutIOAPIFile*)[(NSTreeNode*)node representedObject]).fileID;
    }
    
    __block PutIOAPIFileRequest *request = [PutIOAPIFileRequest requestFilesInFolderWithID:folderID completion:^{
        pendingRequests--;
        if(request.error == nil && !request.isCancelled){
            NSTreeNode *currentNode = nil;
            if(node == nil){
                originTree = [[NSTreeNode alloc] initWithRepresentedObject:request.parentFolder];
                currentNode = originTree;
            }else{
                currentNode = node;
            }
            for(PutIOAPIFile *file in request.files){
                NSTreeNode *childNode = [[NSTreeNode alloc] initWithRepresentedObject:file];
                [[currentNode mutableChildNodes] addObject:childNode];
                if([file isFolder]){
                    if([syncInstruction.recursive boolValue]){
                        [self scanNode:childNode];
                    }
                }else{
                    [self evaulateFileAtNode:childNode];
                }
            }
            
            PutIOAPIFile *folder = request.parentFolder;
            if([syncInstruction.deleteRemoteEmptyFolders boolValue] && folder.fileID != [syncInstruction.originFolderID integerValue] && [request.files count] == 0){
                NSLog(@"Deleting empty folder");
                PutIOAPIFileDeletionRequest *deleteRequest = [PutIOAPIFileDeletionRequest requestDeletionOfFileWithID:folder.fileID completion:nil];
                [putio performRequest:deleteRequest];
            }
        }else{
            [self failWithError:request.error];
        }
        if(pendingRequests == 0){
            originTree = nil;
            [self finish];
        }
    }];
    pendingRequests++;
    [putio performRequest:request];
}

-(void)evaulateFileAtNode:(NSTreeNode*)node
{
    PutIOAPIFile *file = [node representedObject];
    if([syncInstruction itemWithIDIsKnown:[file fileID]])
        return;
    NSString *relativePath = nil;
    if(![syncInstruction.flattenSubdirectories boolValue])
        relativePath = [self relativePathOfFileAtNode:node];
    //NSString *filename = [file name];

    if(![[PutIODownloadManager manager] downloadExistsForFile:file]){
        //NSLog(@"%@ found file to download: %@/%@", [self description], relativePath, filename);
        NSString *localPath = [syncInstruction.localDestination relativePath];
        if(localPath != nil){
            Download *download = [[Download alloc] initWithPutIOFile:file
                                                           localPath:localPath
                                                    subdirectoryPath:relativePath
                                          originatingSyncInstruction:syncInstruction];
            [[PutIODownloadManager manager] addDownload:download];
            [download startDownload];
            foundFiles++;
        }
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
    [syncInstruction.managedObjectContext save:nil];
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
