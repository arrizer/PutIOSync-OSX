
#import "Download.h"
#import "PutIODownloadManager.h"
#import "PutIOAPIFileDeletionRequest.h"
#import "ApplicationDelegate.h"

@interface Download() <NSURLSessionDownloadDelegate>
{
    NSString *localPath;
    NSString *subdirectoryPath;
    NSURLSession *urlSession;
    NSURLSessionDownloadTask *download;
    NSTimer *progressUpdateTimer;
    NSTimeInterval currentSessionStartTime;
    NSTimeInterval lastProgressUpdate;
    NSUInteger receivedBytesInCurrentSession;
    NSUInteger receivedBytesSinceLastProgressUpdate;
    NSFileHandle *fileHandle;
    NSUInteger numberOfRetries;
}

@property NSData *resumeData;

@end

@implementation Download

@dynamic putIOFileArchive;
@dynamic localFile;
@dynamic localPath;
@dynamic subdirectoryPath;
@dynamic progress;
@dynamic progressIsKnown;
@dynamic estimatedRemainingTime;
@dynamic estimatedRemainingTimeIsKnown;
@dynamic totalSize;
@dynamic receivedSize;
@dynamic localFileTemporary;
@dynamic status;
@dynamic shouldResumeOnAppLaunch;
@dynamic originatingSyncInstruction;
@dynamic resumeData;

@synthesize downloadError = _downloadError;
@synthesize bytesPerSecond = _bytesPerSecond;
@synthesize putioFile = _putioFile;
@synthesize localizedStatus = _localizedStatus;

#pragma mark - Init

- (instancetype)initWithPutIOFile:(PutIOAPIFile*)file
                        localPath:(NSString*)path
                 subdirectoryPath:(NSString*)subPath
       originatingSyncInstruction:(SyncInstruction*)syncInstruction
{
    self = [self initWithEntity:[[Persistency manager] entityNamed:@"Download"] insertIntoManagedObjectContext:[Persistency manager].context];
    if (self) {
        urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
                                                   delegate:self
                                              delegateQueue:nil];
        self.putioFile = file;
        localPath = path;
        subdirectoryPath = [subPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        self.localFile = nil;
        self.progress = 0.0f;
        self.progressIsKnown = NO;
        self.estimatedRemainingTime = 0;
        self.estimatedRemainingTimeIsKnown = NO;
        self.originatingSyncInstruction = syncInstruction;
        self.shouldResumeOnAppLaunch = NO;
        numberOfRetries = 0;
        [self changeStatus:PutIODownloadStatusPending];
        [[NSNotificationCenter defaultCenter] postNotificationName:PutIODownloadAddedNotification object:nil];
    }
    return self;
}

-(void)awakeFromFetch
{
    urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
                                               delegate:self
                                          delegateQueue:nil];
    [self changeStatus:self.status andDeliverNotification:NO];
    numberOfRetries = 0;
    self.estimatedRemainingTimeIsKnown = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:PutIODownloadAddedNotification object:nil];
    if(self.status == PutIODownloadStatusDownloading){
        [self startDownload];
    }
}

-(void)dealloc
{
    [self stopWaitingForOtherDownloads];
}

#pragma mark - Accessors

-(void)setPutioFile:(PutIOAPIFile *)putioFile
{
    self.putIOFileArchive = [NSKeyedArchiver archivedDataWithRootObject:putioFile];
}

-(PutIOAPIFile *)putioFile
{
    if(_putioFile == nil){
        _putioFile = [NSKeyedUnarchiver unarchiveObjectWithData:self.putIOFileArchive];
    }
    return _putioFile;
}

#pragma mark - Controlling the download

-(void)startDownload
{
    if(self.status == PutIODownloadStatusFinished || self.status == PutIODownloadStatusCancelled)
        return;
    
    if(![[PutIOAPI api] isAuthenticated])
        return;
    
    [self changeStatus:PutIODownloadStatusPending];
    [self stopWaitingForOtherDownloads];
    
    NSInteger maxParallelDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:@"general_paralleldownloads"];
    if(maxParallelDownloads != 0 && [[PutIODownloadManager manager] numberOfRunningDownloads] >= maxParallelDownloads){
        // The maximum number of downloads is already runnung, wait for another
        [self startWaitingForOtherDownloads];
        return;
    }
    
    self.estimatedRemainingTimeIsKnown = NO;
    self.bytesPerSecond = 0;
    self.progressIsKnown = NO;
    currentSessionStartTime = 0.0f;
    receivedBytesInCurrentSession = 0;
    self.localFile = nil;
    receivedBytesSinceLastProgressUpdate = 0;
    progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                           target:self
                                                         selector:@selector(updateProgress)
                                                         userInfo:nil repeats:YES];
    
    NSURL *requestURL = [[PutIOAPI api] downloadURLForFileWithID:(self.putioFile).fileID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60.0f];
    
    if(self.resumeData != nil){
        // Resume the download
        NSLog(@"%@ resuming download", self);
        download = [urlSession downloadTaskWithResumeData:self.resumeData];
        receivedBytesSinceLastProgressUpdate = download.countOfBytesReceived;
    }else{
        // Download from beginning
        NSLog(@"%@ starting download from beginning", self);
        download = [urlSession downloadTaskWithRequest:request];
    }
    
    [download resume];
    [self changeStatus:PutIODownloadStatusDownloading];
}

- (void)pauseDownload
{
    [self stopWaitingForOtherDownloads];
    if(download){
        [download cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [self.managedObjectContext performBlockAndWait:^{
                self.resumeData = resumeData;
            }];
        }];
        [progressUpdateTimer invalidate];
        progressUpdateTimer = nil;
        download = nil;
    }
    [self changeStatus:PutIODownloadStatusPaused];
}

- (void)cancelDownload
{
    [download cancel];
    [progressUpdateTimer invalidate];
    progressUpdateTimer = nil;
    [self stopWaitingForOtherDownloads];
    [self changeStatus:PutIODownloadStatusCancelled];
}

#pragma mark - Manage temporary file

- (BOOL)moveTemporaryDataFileToFinalLocation:(NSURL*)temporaryFileURL
{
    NSString *path = localPath;
    NSError *error;
    if(subdirectoryPath){
        NSFileManager *fm = [NSFileManager defaultManager];
        path = [path stringByAppendingFormat:@"/%@", subdirectoryPath];
        if(![fm fileExistsAtPath:path]){
            if(![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]){
                [self failWithError:error];
                return NO;
            }
        }
    }
    self.localFile = [NSString stringWithFormat:@"%@/%@", path, self.putioFile.name];
    self.localFile = [self resolveNamingConflictForFileAtPath:self.localFile];
    if (![[NSFileManager defaultManager] moveItemAtURL:temporaryFileURL toURL:[NSURL fileURLWithPath:self.localFile] error:&error]) {
        self.localFile = nil;
        [self failWithError:error];
        return NO;
    }
    return YES;
}

- (NSString*)resolveNamingConflictForFileAtPath:(NSString*)filePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSUInteger number = 0;
    while([fm fileExistsAtPath:filePath])
        filePath = [NSString stringWithFormat:@"%@/%@-%li.%@", filePath.stringByDeletingLastPathComponent,
                    filePath.lastPathComponent.stringByDeletingPathExtension, ++number, filePath.pathExtension];
    return filePath;
}

#pragma mark - Verifying downloaded files

- (BOOL)verifyDownloadAt:(NSURL*)temporaryFileURL
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:temporaryFileURL.path error:nil];
    if((self.receivedSize == self.totalSize || self.totalSize == NSURLSessionTransferSizeUnknown)
       && (self.receivedSize == [attributes fileSize])
       && (self.receivedSize == self.putioFile.size)){
        // File size == HTTP Content-Length == PutIO API file size == Received size => it worked!
        return YES;
    }else{
        NSLog(@"%@ downloaded file has not expected size:\nBytes received = %lli\nContent-length = %lli\nPutIO file size = %li\nActual file size = %lli", self, self.receivedSize, self.totalSize, self.putioFile.size, [attributes fileSize]);
        download = nil;
        [self failWithLocalizedErrorDescription:@"Unexpected file size"];
    }
    return NO;
}

- (void)unlinkFromOriginatingSyncInstruction
{
    // Call this when the sync instruction has been edited and the download should not add a known item to the
    // edited instruction when finished anymore
    self.originatingSyncInstruction = nil;
}

#pragma mark - Download Task Delegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    dispatch_sync(dispatch_get_main_queue() , ^{
        [progressUpdateTimer invalidate];
        progressUpdateTimer = nil;
        
        [self updateProgress];
        
        if(![self verifyDownloadAt:location]){
            return;
        }
        if(![self moveTemporaryDataFileToFinalLocation:location]){
            return;
        }
        
        self.progressIsKnown = YES;
        self.progress = 1.0f;
        self.estimatedRemainingTimeIsKnown = YES;
        self.estimatedRemainingTime = 0;
        download = nil;
        [self changeStatus:PutIODownloadStatusFinished];
        NSLog(@"%@: Download finished", self);
        if(self.originatingSyncInstruction != nil){
            [self.originatingSyncInstruction addKnownItemWithID:self.putioFile.fileID];
            if((self.originatingSyncInstruction.deleteRemoteFilesAfterSync).boolValue){
                PutIOAPIFileDeletionRequest *request = [PutIOAPIFileDeletionRequest requestDeletionOfFileWithID:self.putioFile.fileID
                                                                                                     completion:nil];
                [[PutIOAPI api] performRequest:request];
            }
        }
    });
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error != nil && !([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)) {
        dispatch_async(dispatch_get_main_queue() , ^{
            numberOfRetries++;
            NSLog(@"%@ failed: %@ but trying again, retry number %li", self, error.localizedDescription, numberOfRetries);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startDownload];
            });
        });
    }
}

#pragma mark - Progress and remaining time calulations

-(void)updateProgress
{
    self.totalSize = download.countOfBytesExpectedToReceive;
    self.receivedSize = download.countOfBytesReceived;
    
    NSUInteger chunkSize = download.countOfBytesReceived - receivedBytesSinceLastProgressUpdate;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSUInteger averageBytesPerSecond = 0;
    
    if(currentSessionStartTime == 0.0f){
        currentSessionStartTime = now;
    }else{
        self.bytesPerSecond = (int)round((double)chunkSize / (now - lastProgressUpdate));
        averageBytesPerSecond = (int)round((double)receivedBytesInCurrentSession / (now - currentSessionStartTime));
        self.estimatedRemainingTime = ((double)(self.totalSize - self.receivedSize) / (double)averageBytesPerSecond);
        self.estimatedRemainingTimeIsKnown = (now - currentSessionStartTime) >= 5.0f && receivedBytesInCurrentSession > 1024;
    }
    receivedBytesInCurrentSession += chunkSize;
    if(self.totalSize > 0){
        self.progress = ((float)self.receivedSize / (float)self.totalSize);
        self.progressIsKnown = YES;
    }
    lastProgressUpdate = now;
    receivedBytesSinceLastProgressUpdate = self.receivedSize;
    
    NSLog(@"%@ - chunkSize: %lu bytes, speed: %lu bps (avg %lu bps)", self, chunkSize, self.bytesPerSecond, averageBytesPerSecond);
}

#pragma mark - Error handling

-(void)failWithLocalizedErrorDescription:(NSString*)errorDescription
{
    NSError *error = [NSError errorWithDomain:@"putiodownload"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
    [self failWithError:error];
}

-(void)failWithError:(NSError *)error
{
    [download cancel];
    download = nil;
    [progressUpdateTimer invalidate];
    progressUpdateTimer = nil;
    self.downloadError = error;
    NSLog(@"%@ failed: %@", self, error.localizedDescription);
    [self stopWaitingForOtherDownloads];
    [self changeStatus:PutIODownloadStatusFailed];
}

#pragma mark - Download status

-(void)changeStatus:(PutIODownloadStatus)newStatus
{
    [self changeStatus:newStatus andDeliverNotification:YES];
}

-(void)changeStatus:(PutIODownloadStatus)newStatus andDeliverNotification:(BOOL)deliverNotification
{
    NSDictionary *localizedStatusDescriptions = @{
                                                  @((int)PutIODownloadStatusPending) : NSLocalizedString(@"Pending", nil),
                                                  @((int)PutIODownloadStatusDownloading) : NSLocalizedString(@"Downloading", nil),
                                                  @((int)PutIODownloadStatusPaused) : NSLocalizedString(@"Paused", nil),
                                                  @((int)PutIODownloadStatusFinished) : NSLocalizedString(@"Finished", nil),
                                                  @((int)PutIODownloadStatusCancelled) : NSLocalizedString(@"Cancelled", nil),
                                                  @((int)PutIODownloadStatusFailed) : NSLocalizedString(@"Failed", nil)
                                                  };
    NSDictionary *notificationNames = @{
                                        @((int)PutIODownloadStatusDownloading) : PutIODownloadStartedNotification,
                                        @((int)PutIODownloadStatusPaused) : PutIODownloadPausedNotification,
                                        @((int)PutIODownloadStatusFinished) : PutIODownloadFinishedNotification,
                                        @((int)PutIODownloadStatusCancelled) : PutIODownloadCancelledNotification,
                                        @((int)PutIODownloadStatusFailed) : PutIODownloadFailedNotification
                                        };

    self.localizedStatus = localizedStatusDescriptions[@((int)newStatus)];
    self.status = newStatus;
    NSString *notificationName = notificationNames[@((int)newStatus)];
    if(notificationName != nil)
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    if(deliverNotification)
        [self deliverUserNotification];
}

#pragma mark - User Notifications

- (void)deliverUserNotification
{
    NSString *identifier = nil;
    NSString *message = self.putioFile.name;
    if(self.status == PutIODownloadStatusFinished){
        identifier = @"downloadfinished";
    }
    if(self.status == PutIODownloadStatusFailed){
        identifier = @"downloadfailed";
        message = [message stringByAppendingFormat:NSLocalizedString(@" failed: %@",nil), self.downloadError.localizedDescription];
    }
    if(identifier == nil)
        return;
    [(ApplicationDelegate*)NSApp.delegate deliverUserNotificationWithIdentifier:identifier message:message];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"PutIODownload<%@>", self.putioFile.name];
}

#pragma mark - Coordinate Parallel Downloads

- (void)startWaitingForOtherDownloads
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(otherDownloadDidFinishOrPause)
               name:PutIODownloadFinishedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(otherDownloadDidFinishOrPause)
               name:PutIODownloadPausedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(otherDownloadDidFinishOrPause)
               name:PutIODownloadFailedNotification
             object:nil];
}

- (void)stopWaitingForOtherDownloads
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)otherDownloadDidFinishOrPause
{
    if(self.status == PutIODownloadStatusPending){
        NSInteger maxParallelDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:@"general_paralleldownloads"];
        if(maxParallelDownloads == 0 || [[PutIODownloadManager manager] numberOfRunningDownloads] < maxParallelDownloads){
            [self startDownload];
        }
    }
}

@end
