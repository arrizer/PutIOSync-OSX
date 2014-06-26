
#import "PutIODownloadManager.h"

@interface PutIODownloadManager()
{
    NSMutableArray* allDownloads;
}
@end

@implementation PutIODownloadManager

+(instancetype)manager
{
    static PutIODownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PutIODownloadManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        allDownloads = [NSMutableArray array];
    }
    return self;
}

-(void)loadDownloads
{
    NSFetchRequest *request = [[Persistency manager].model fetchRequestTemplateForName:@"AllDownloads"];
    allDownloads = [[[Persistency manager].context executeFetchRequest:request error:nil] mutableCopy];
    for(Download *download in allDownloads){
        if(download.shouldResumeOnAppLaunch){
            download.shouldResumeOnAppLaunch = NO;
            [download startDownload];
        }
    }
}

-(void)addDownload:(Download *)download
{
    [allDownloads addObject:download];
    
}

- (NSArray*)allDownloads
{
    return allDownloads;
}

- (void)clearDownloadList
{
    for(Download *download in [allDownloads copy]){
        if(download.status != PutIODownloadStatusDownloading && download.status != PutIODownloadStatusPending){
            [download cancelDownload];
            [allDownloads removeObject:download];
            [download.managedObjectContext deleteObject:download];
        }
    }
}

- (BOOL)downloadExistsForFile:(PutIOAPIFile *)file
{
    for(Download *download in allDownloads)
        if([download.putioFile fileID] == file.fileID)
            return YES;
    return NO;
}

- (void)pauseAndSaveAllDownloads
{
    // Call this before the application terminates
    for(Download *download in allDownloads)
        [download stopWaitingForOtherDownloads];
    for(Download *download in allDownloads){
        if(download.status == PutIODownloadStatusDownloading || download.status == PutIODownloadStatusPending){
            [download pauseDownload];
            download.shouldResumeOnAppLaunch = YES;
        }
    }
    [[Persistency manager].context save:nil];
}

- (void)saveDownloads
{
    //[PersistenceManager storePersistentObject:allDownloads forKey:@"downloads"];
}

- (NSInteger)numberOfRunningDownloads
{
    NSInteger count = 0;
    for(Download *download in allDownloads){
        if(download.status == PutIODownloadStatusDownloading){
            count++;
        }
    }
    return count;
}

- (void)complyWithMaximumParallelDownloads
{
    NSInteger maxParallelDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:@"general_paralleldownloads"];
    while([self numberOfRunningDownloads] > maxParallelDownloads){
        for(Download *download in allDownloads){
            if(download.status == PutIODownloadStatusDownloading){
                [download pauseDownload];
                [download startDownload];
                break;
            }
        }
    }
    for(Download *download in allDownloads){
        if(download.status == PutIODownloadStatusPending)
            [download startDownload];
    }
}

@end
