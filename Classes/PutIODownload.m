
#import "PutIODownload.h"
#import "PersistenceManager.h"
#import "ApplicationDelegate.h"
#import "PutIOAPIFileDeletionRequest.h"

#define PUTIO_API_DOWNLOAD_ENDPOINT @"https://api.put.io/v2/files/%ld/download?oauth_token=%@"

@interface PutIODownload()
{
    NSString *localPath;
    NSString *subdirectoryPath;
    NSString *localFileTemporary;
    NSURLConnection *connection;
    NSTimeInterval currentSessionStartTime;
    NSTimeInterval lastProgressUpdate;
    NSUInteger receivedBytesSinceLastProgressUpdate;
    NSUInteger receivedBytesInCurrentSession;
    NSFileHandle *fileHandle;
    NSUInteger numberOfRetries;
}

@property (strong) PutIOAPIFile *putioFile;
@property (assign) float progress;
@property (assign) BOOL progressIsKnown;
@property (assign) PutIODownloadStatus status;
@property (strong) NSString *localizedStatus;
@property (assign) NSTimeInterval estimatedRemainingTime;
@property (assign) BOOL estimatedRemainingTimeIsKnown;
@property (assign) NSUInteger totalSize;
@property (assign) NSUInteger receivedSize;
@property (assign) NSUInteger bytesPerSecond;
@property (unsafe_unretained) SyncInstruction *originatingSyncInstruction;
@property (strong) NSError *downloadError;
@property (strong) NSString *localFile;
@property (assign) BOOL shouldResumeOnAppLaunch;
@end

@implementation PutIODownload

#pragma mark - Manage Download List

static NSMutableArray* allDownloads;
static NSInteger numberOfRunningDownloads = 0;

+ (NSArray*)allDownloads
{
    if(!allDownloads){
        // Load the existing downloads from disk
        allDownloads = [PersistenceManager retrievePersistentObjectForKey:@"downloads"];
        if(allDownloads == nil)
            allDownloads = [NSMutableArray array];
        else{
            for(PutIODownload *download in allDownloads)
                if(download.shouldResumeOnAppLaunch){
                    download.shouldResumeOnAppLaunch = NO;
                    [download startDownload];
                }
        }
    }
    return allDownloads;
}

+ (void)clearDownloadList
{
    for(PutIODownload *download in [allDownloads copy]){
        if(download.status != PutIODownloadStatusDownloading && download.status != PutIODownloadStatusPending){
            [download cancelDownload];
            [allDownloads removeObject:download];
        }
    }
}

+ (BOOL)downloadExistsForFile:(PutIOAPIFile *)file
{
    for(PutIODownload *download in allDownloads)
        if([download.putioFile fileID] == file.fileID)
            return YES;
    return NO;
}

+(void)pauseAndSaveAllDownloads
{
    // Call this before the application terminates
    for(PutIODownload *download in allDownloads)
        [download stopWaitingForOtherDownloads];
    for(PutIODownload *download in allDownloads){
        if(download.status == PutIODownloadStatusDownloading || download.status == PutIODownloadStatusPending){
            [download pauseDownload];
            download.shouldResumeOnAppLaunch = YES;
        }
    }
    [PutIODownload saveDownloads];
}

+ (void)saveDownloads
{
    [PersistenceManager storePersistentObject:allDownloads forKey:@"downloads"];
}

+ (NSInteger)numberOfRunningDownloads
{
    return numberOfRunningDownloads;
}

+ (void)complyWithMaximumParallelDownloads
{
    NSInteger maxParallelDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:@"general_paralleldownloads"];
    while([PutIODownload numberOfRunningDownloads] > maxParallelDownloads){
        for(PutIODownload *download in allDownloads)
            if(download.status == PutIODownloadStatusDownloading){
                [download pauseDownload];
                [download startDownload];
                break;
            }
    }
    for(PutIODownload *download in allDownloads){
        if(download.status == PutIODownloadStatusPending)
            [download startDownload];
    }
}

#pragma mark - Init

- (id)initWithPutIOFile:(PutIOAPIFile*)file
              localPath:(NSString*)path
       subdirectoryPath:(NSString*)subPath
originatingSyncInstruction:(SyncInstruction*)syncInstruction;
{
    self = [super init];
    if (self) {
        self.putioFile = file;
        localPath = path;
        subdirectoryPath = [subPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        self.localFile = nil;
        self.progress = 0.0f;
        self.progressIsKnown = NO;
        self.estimatedRemainingTime = 0;
        self.estimatedRemainingTimeIsKnown = NO;
        self.originatingSyncInstruction = syncInstruction;
        self.totalSize = 0;
        self.shouldResumeOnAppLaunch = NO;
        numberOfRetries = 0;
        [self changeStatus:PutIODownloadStatusPending];
        [allDownloads addObject:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:PutIODownloadAddedNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    [self stopWaitingForOtherDownloads];
}

#pragma mark - Coding

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self){
        self.putioFile = [decoder decodeObjectForKey:@"putioFile"];
        self.localFile = [decoder decodeObjectForKey:@"localFile"];
        localPath = [decoder decodeObjectForKey:@"localPath"];
        subdirectoryPath = [decoder decodeObjectForKey:@"subdirectoryPath"];
        self.progress = [decoder decodeFloatForKey:@"progress"];
        self.progressIsKnown = [decoder decodeBoolForKey:@"progressIsKnown"];
        self.estimatedRemainingTime = [decoder decodeIntegerForKey:@"estimatedRemainingTime"];
        self.estimatedRemainingTimeIsKnown = [decoder decodeBoolForKey:@"estimatedRemainingTimeIsKnown"];
        NSInteger uniqueID = [decoder decodeIntegerForKey:@"originatingSyncInstruction.uniqueID"];
        for(SyncInstruction *instruction in [SyncInstruction allSyncInstructions])
            if(instruction.uniqueID == uniqueID)
                self.originatingSyncInstruction = instruction;
        self.totalSize = [decoder decodeIntegerForKey:@"totalSize"];
        self.receivedSize = [decoder decodeIntegerForKey:@"receivedSize"];
        localFileTemporary = [decoder decodeObjectForKey:@"localFileTemporary"];
        self.shouldResumeOnAppLaunch = [decoder decodeBoolForKey:@"shouldResumeOnAppLaunch"];
        self.status = [decoder decodeIntForKey:@"status"];
        [self changeStatus:self.status andDeliverNotification:NO];
        numberOfRetries = 0;

        [allDownloads addObject:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:PutIODownloadAddedNotification object:nil];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.putioFile forKey:@"putioFile"];
    [coder encodeObject:self.localFile forKey:@"localFile"];
    [coder encodeObject:localPath forKey:@"localPath"];
    [coder encodeObject:subdirectoryPath forKey:@"subdirectoryPath"];
    [coder encodeFloat:self.progress forKey:@"progress"];
    [coder encodeBool:self.progressIsKnown forKey:@"progressIsKnown"];
    [coder encodeInteger:self.estimatedRemainingTime forKey:@"estimatedRemainingTime"];
    [coder encodeBool:self.estimatedRemainingTimeIsKnown forKey:@"estimatedRemainingTimeIsKnown"];
    [coder encodeInteger:self.originatingSyncInstruction.uniqueID forKey:@"originatingSyncInstruction.uniqueID"];
    [coder encodeInteger:self.totalSize forKey:@"totalSize"];
    [coder encodeInteger:self.receivedSize forKey:@"receivedSize"];
    [coder encodeObject:localFileTemporary forKey:@"localFileTemporary"];
    [coder encodeInt:(int)self.status forKey:@"status"];
    [coder encodeBool:self.shouldResumeOnAppLaunch forKey:@"shouldResumeOnAppLaunch"];
}

#pragma mark - Controlling the download

-(void)startDownload
{
    if(connection != nil || self.status == PutIODownloadStatusFinished || self.status == PutIODownloadStatusCancelled)
        return;
    if(![[PutIOAPI api] isAuthenticated])
        return;
    
    [self changeStatus:PutIODownloadStatusPending];
    [self stopWaitingForOtherDownloads];
    
    NSInteger maxParallelDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:@"general_paralleldownloads"];
    if(maxParallelDownloads != 0 && [PutIODownload numberOfRunningDownloads] >= maxParallelDownloads){
        // The maximum number of downloads is already runnung, wait for another
        [self startWaitingForOtherDownloads];
        return;
    }
    
    self.estimatedRemainingTimeIsKnown = NO;
    self.bytesPerSecond = 0;
    self.progressIsKnown = NO;
    currentSessionStartTime = 0.0f;
    receivedBytesSinceLastProgressUpdate = 0;
    receivedBytesInCurrentSession = 0;
    self.localFile = nil;
    
    NSString *requestURLString = [NSString stringWithFormat:PUTIO_API_DOWNLOAD_ENDPOINT, [self.putioFile fileID], [[PutIOAPI api]oAuthAccessToken]];
    NSURL *requestURL = [NSURL URLWithString:requestURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60.0f];
    
    if([self canResume]){
        // Resume the download
        [request setValue:[NSString stringWithFormat:@"bytes=%li-", self.receivedSize] forHTTPHeaderField:@"Range"];
        NSLog(@"%@ resuming download from byte %li", self, self.receivedSize);
    }else{
        [self deleteTemporaryDataFile];
        // Download from beginning
        self.totalSize = 0;
        self.receivedSize = 0;
        localFileTemporary = nil;
        NSLog(@"%@ starting download from beginning", self);
    }
    
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [self changeStatus:PutIODownloadStatusDownloading];
}

- (void)pauseDownload
{
    [self stopWaitingForOtherDownloads];
    if(connection){
        [self cancelConnection];
        self.receivedSize += receivedBytesSinceLastProgressUpdate;
    }
    //NSLog(@"%@ paused download after receiving %li bytes", self, self.receivedSize);
    [self changeStatus:PutIODownloadStatusPaused];
}

- (void)cancelDownload
{
    if(connection)
        [self cancelConnection];
    [self deleteTemporaryDataFile];
    [self stopWaitingForOtherDownloads];
    [self changeStatus:PutIODownloadStatusCancelled];
}

- (void)cancelConnection
{
    if(connection){
        [connection cancel];
        connection = nil;
    }
    if(fileHandle){
        [fileHandle closeFile];
        fileHandle = nil;
    }
}

#pragma mark - Manage temporary file

- (void)createAndOpenTemporaryDataFile
{
    if(localFileTemporary == nil){
        localFileTemporary = [NSString stringWithFormat:@"%@/.%@.part", localPath, self.putioFile.name];
        localFileTemporary = [self resolveNamingConflictForFileAtPath:localFileTemporary];
        if(![[NSFileManager defaultManager] createFileAtPath:localFileTemporary contents:nil attributes:nil]){
            [self failWithLocalizedErrorDescription:NSLocalizedString(@"Unable to create file on disk", nil)];
        }
    }
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:localFileTemporary];
}

- (void)deleteTemporaryDataFile
{
    if(localFileTemporary != nil && [[NSFileManager defaultManager] fileExistsAtPath:localFileTemporary]){
        NSError *error;
        if(![[NSFileManager defaultManager] removeItemAtPath:localFileTemporary error:&error]){
            NSLog(@"%@: Unable to remove temporary data file: %@", self, error.localizedDescription);
        }
    }
}

- (BOOL)moveTemporaryDataFileToFinalLocation
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
    if(![[NSFileManager defaultManager] moveItemAtPath:localFileTemporary toPath:self.localFile error:&error]){
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
        filePath = [NSString stringWithFormat:@"%@/%@-%li.%@", [filePath stringByDeletingLastPathComponent],
                    [[filePath lastPathComponent] stringByDeletingPathExtension], ++number, [filePath pathExtension]];
    return filePath;
}

#pragma mark - Resuming downloads

- (BOOL)canResume
{
    // We can only resume if the temporary file is still there and has the expected size
    if(self.receivedSize <= 0)
        return NO;
    if(localFileTemporary != nil && [[NSFileManager defaultManager] fileExistsAtPath:localFileTemporary]){
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:localFileTemporary error:nil];
        if([attributes fileSize] == self.receivedSize)
            return YES;
        else
            NSLog(@"%@: Unable to resume: Temporary file has invalid size", self);
    }
    NSLog(@"%@: Unable to resume: Temporary file not present", self);
    return NO;
}

#pragma mark - Verifying downloaded files

- (BOOL)verifyDownload
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:localFileTemporary error:nil];
    if((self.receivedSize == self.totalSize)
       && (self.totalSize == [attributes fileSize])
       && (self.totalSize == self.putioFile.size)){
        // File size == HTTP Content-Length == PutIO API file size == Received size => it worked!
        return YES;
    }else{
        NSLog(@"%@ downloaded file has not expected size:\nBytes received = %li\nContent-length = %li\nPutIO file size = %li\nActual file size = %lli", self, self.receivedSize, self.totalSize, self.putioFile.size, [attributes fileSize]);
        //[self failWithError:nil];
        [self startDownload];
    }
    return NO;
}

- (void)unlinkFromOriginatingSyncInstruction
{
    // Call this when the sync instruction has been edited and the download should not add a known item to the
    // edited instruction when finished anymore
    self.originatingSyncInstruction = nil;
}

#pragma mark - URL connection delegate

-(void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSDictionary *responseHeaders = [httpResponse allHeaderFields];
    // NSLog(@"PutIO download response headers: %@", responseHeaders);
    NSInteger httpStatus = [httpResponse statusCode];
    if((httpStatus >= 200 && httpStatus < 300) && responseHeaders[@"Content-Length"] != nil){
        if(self.receivedSize == 0)
            self.totalSize = [responseHeaders[@"Content-Length"] integerValue];
    }else{
        [self failWithLocalizedErrorDescription:[NSHTTPURLResponse localizedStringForStatusCode:httpStatus]];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(fileHandle == nil)
        [self createAndOpenTemporaryDataFile];
    if(fileHandle == nil)
        [self failWithLocalizedErrorDescription:NSLocalizedString(@"Unable to write to file on disk", nil)];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    
    // Don't update the progress too often
    receivedBytesSinceLastProgressUpdate += [data length];
    if(([NSDate timeIntervalSinceReferenceDate] - lastProgressUpdate) > 0.2f){
        [self updateProgress];
        
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSInteger c = [error code];
    if(c == NSURLErrorNetworkConnectionLost|| c == NSURLErrorNotConnectedToInternet){
        [self pauseDownload];
        return;
    }
    
    BOOL shouldRetry = (c == NSURLErrorTimedOut
                     || c == NSURLErrorCannotConnectToHost);
    
    if(shouldRetry && numberOfRetries < 5){
        // PutIO servers are wonky, so retry a few times
        numberOfRetries++;
        NSLog(@"%@ failed: %@ but trying again, retry number %li", self, error.localizedDescription, numberOfRetries);
        [self cancelConnection];
        [self startDownload];
    }else{
        numberOfRetries = 0;
        [self failWithError:error];
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    self.receivedSize += receivedBytesSinceLastProgressUpdate;
    if(fileHandle){
        [fileHandle closeFile];
        fileHandle = nil;
    }
    if(![self verifyDownload])
        return;
    if(![self moveTemporaryDataFileToFinalLocation])
        return;
    
    self.progressIsKnown = YES;
    self.progress = 1.0f;
    self.estimatedRemainingTimeIsKnown = YES;
    self.estimatedRemainingTime = 0;
    connection = nil;
    [self changeStatus:PutIODownloadStatusFinished];
    NSLog(@"%@: Download finished", self);
    if(self.originatingSyncInstruction != nil){
        [self.originatingSyncInstruction addKnownItemWithID:self.putioFile.fileID];
        if(self.originatingSyncInstruction.deleteRemoteFilesAfterSync){
            PutIOAPIFileDeletionRequest *request = [PutIOAPIFileDeletionRequest requestDeletionOfFileWithID:self.putioFile.fileID
                                                                                                 completion:nil];
            [[PutIOAPI api] performRequest:request];
        }
    }
}

#pragma mark - Progress and remaining time calulations

-(void)updateProgress
{
    NSUInteger length = receivedBytesSinceLastProgressUpdate;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if(currentSessionStartTime == 0.0f)
        currentSessionStartTime = now;
    else{
        self.bytesPerSecond = (int)round((double)length / (now - lastProgressUpdate));
        NSUInteger averageBytesPerSecond = (int)round((double)receivedBytesInCurrentSession / (now - currentSessionStartTime));
        self.estimatedRemainingTime = ((double)(self.totalSize - self.receivedSize) / (double)averageBytesPerSecond);
        self.estimatedRemainingTimeIsKnown = (now - currentSessionStartTime) >= 5.0f;
    }
    self.receivedSize += length;
    receivedBytesInCurrentSession += length;
    if(self.totalSize > 0){
        self.progress = ((float)self.receivedSize / (float)self.totalSize);
        self.progressIsKnown = YES;
    }
    lastProgressUpdate = now;
    receivedBytesSinceLastProgressUpdate = 0;
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
    [self cancelConnection];
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
    if(newStatus == PutIODownloadStatusDownloading)
        numberOfRunningDownloads++;
    else if(self.status == PutIODownloadStatusDownloading)
        numberOfRunningDownloads--;
    self.localizedStatus = localizedStatusDescriptions[@((int)newStatus)];
    self.status = newStatus;
    NSString *notificationName = notificationNames[@((int)newStatus)];
    if(notificationName != nil)
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    if(deliverNotification)
        [self deliverUserNotification];
    [PutIODownload saveDownloads];
}

#pragma mark - User Notifications

- (void)deliverUserNotification
{
    NSString *identifier = nil;
    NSString *message = self.putioFile.name;
    if(self.status == PutIODownloadStatusFinished){
        identifier = @"downloadfinished";
    }
    if(self.status == self.status == PutIODownloadStatusFailed){
        identifier = @"downloadfailed";
        message = [message stringByAppendingFormat:NSLocalizedString(@" failed: %@",nil), self.downloadError.localizedDescription];
    }
    if(identifier == nil)
        return;
    [(ApplicationDelegate*)[NSApp delegate] deliverUserNotificationWithIdentifier:identifier message:message];
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
        if(maxParallelDownloads == 0 || [PutIODownload numberOfRunningDownloads] < maxParallelDownloads){
            [self startDownload];
        }
    }
}

@end
