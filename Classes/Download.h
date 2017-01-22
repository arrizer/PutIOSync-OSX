
@import Foundation;
#import "PutIOAPI.h"
#import "PutIOAPIFile.h"
#import "SyncInstruction.h"

#define PutIODownloadAddedNotification @"PutIODownloadAddedNotification"
#define PutIODownloadFinishedNotification @"PutIODownloadFinishedNotification"
#define PutIODownloadPausedNotification @"PutIODownloadPausedNotification"
#define PutIODownloadStartedNotification @"PutIODownloadStartedNotification"
#define PutIODownloadCancelledNotification @"PutIODownloadCancelledNotification"
#define PutIODownloadFailedNotification @"PutIODownloadFailedNotification"

typedef enum PutIODownloadStatusEnum : int16_t{
    PutIODownloadStatusPending = 0,
    PutIODownloadStatusDownloading = 1,
    PutIODownloadStatusPaused = 2,
    PutIODownloadStatusFinished = 3,
    PutIODownloadStatusCancelled = 4,
    PutIODownloadStatusFailed = 5
} PutIODownloadStatus;

@interface Download : NSManagedObject

@property (nonatomic, strong) NSData *putIOFileArchive;
@property (nonatomic, strong) NSString *localFile;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *subdirectoryPath;
@property (nonatomic) float progress;
@property (nonatomic) BOOL progressIsKnown;
@property (nonatomic) double estimatedRemainingTime;
@property (nonatomic) BOOL estimatedRemainingTimeIsKnown;
@property (nonatomic, readonly) int64_t totalSize;
@property (nonatomic, readonly) int64_t receivedSize;
@property (nonatomic, strong) NSString *localFileTemporary;
@property (nonatomic) PutIODownloadStatus status;
@property (nonatomic) BOOL shouldResumeOnAppLaunch;
@property (nonatomic, retain) SyncInstruction *originatingSyncInstruction;

@property (nonatomic, strong) PutIOAPIFile *putioFile;
@property (nonatomic, strong) NSString *localizedStatus;
@property (nonatomic) NSUInteger bytesPerSecond;
@property (nonatomic, strong) NSError *downloadError;

- (instancetype)initWithPutIOFile:(PutIOAPIFile*)file
              localPath:(NSString*)path
       subdirectoryPath:(NSString*)subdirectoryPath
originatingSyncInstruction:(SyncInstruction*)syncInstruction;

- (void)startDownload;
- (void)pauseDownload;
- (void)cancelDownload;
- (void)unlinkFromOriginatingSyncInstruction;
- (void)stopWaitingForOtherDownloads;

@end
