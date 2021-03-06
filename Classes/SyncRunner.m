
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

- (instancetype)initWithSyncInstruction:(SyncInstruction*)instruction
{
    self = [super init];
    if (self) {
        syncInstruction = instruction;
        putio = [PutIOAPI new];
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
    if (self.isBusy) {
        return;
    }
    
    foundFiles = 0;
    
    [self deepScanOrigin];
}

- (void)cancel
{
    [putio cancelAllRequests];
    if([_delegate respondsToSelector:@selector(syncRunnerDidCancel:)]){
        [_delegate syncRunnerDidCancel:self];
    }
}

#pragma mark - Scan Origin

-(void)deepScanOrigin
{
    [putio cancelAllRequests];
    originTree = nil;
    [self scanNode:nil];
}

-(void)scanNode:(NSTreeNode*)node
{
    NSInteger folderID;
    if(node == nil){
        folderID = (syncInstruction.originFolderID).integerValue;
    }else{
        folderID = ((PutIOAPIFile*)((NSTreeNode*)node).representedObject).fileID;
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
                [currentNode.mutableChildNodes addObject:childNode];
                if(file.isFolder){
                    if((syncInstruction.recursive).boolValue){
                        [self scanNode:childNode];
                    }
                }else{
                    [self evaulateFileAtNode:childNode];
                }
            }
            
            PutIOAPIFile *folder = request.parentFolder;
            if((syncInstruction.deleteRemoteEmptyFolders).boolValue && folder.fileID != (syncInstruction.originFolderID).integerValue && (request.files).count == 0){
                NSLog(@"Deleting empty folder");
                PutIOAPIFileDeletionRequest *deleteRequest = [PutIOAPIFileDeletionRequest requestDeletionOfFileWithID:folder.fileID completion:nil];
                [putio performRequest:deleteRequest];
            }
        }else if(request.error != nil){
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
    PutIOAPIFile *file = node.representedObject;
    if([syncInstruction itemWithIDIsKnown:file.fileID])
        return;
    NSString *relativePath = nil;
    if(!(syncInstruction.flattenSubdirectories).boolValue)
        relativePath = [self relativePathOfFileAtNode:node];
    //NSString *filename = [file name];

    if(![[PutIODownloadManager manager] downloadExistsForFile:file]){
        //NSLog(@"%@ found file to download: %@/%@", [self description], relativePath, filename);
        NSString *localPath = (syncInstruction.localDestination).relativePath;
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
}

- (NSString*)relativePathOfFileAtNode:(NSTreeNode*)node
{
    NSMutableArray *parentFolderNames = [NSMutableArray array];
    NSTreeNode *parentNode = node.parentNode;
    while(parentNode != nil && parentNode != originTree){
        NSString *folderName = ((PutIOAPIFile*)parentNode.representedObject).name;
        [parentFolderNames insertObject:folderName atIndex:0];
        parentNode = parentNode.parentNode;
    }
    NSString *relativePath = @"";
    if(parentFolderNames.count > 0)
        relativePath = [parentFolderNames componentsJoinedByString:@"/"];
    return relativePath;
}

#pragma mark - Flow Control

-(void)failWithError:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(syncRunner:didFailWithError:)]){
            [_delegate syncRunner:self didFailWithError:error];
        }
    });
}

-(void)finish
{
    NSLog(@"%@ sync run finished", self.description);
    [syncInstruction.managedObjectContext performBlockAndWait:^{
        syncInstruction.lastSynced = [NSDate date];
        [syncInstruction.managedObjectContext save:nil];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(syncRunnerDidFinish:afterFindingFiles:)]) {
            [_delegate syncRunnerDidFinish:self afterFindingFiles:foundFiles];
        }
    });
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"SyncRunner<%@>", syncInstruction.originFolderName];
}

@end
