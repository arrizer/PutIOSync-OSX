
#import <Foundation/Foundation.h>
#import "PutIOAPI.h"
#import "SyncInstruction.h"

#define PutIODownloadAddedNotification @"PutIODownloadAddedNotification"
#define PutIODownloadFinishedNotification @"PutIODownloadFinishedNotification"
#define PutIODownloadPausedNotification @"PutIODownloadPausedNotification"
#define PutIODownloadStartedNotification @"PutIODownloadStartedNotification"
#define PutIODownloadCancelledNotification @"PutIODownloadCancelledNotification"
#define PutIODownloadFailedNotification @"PutIODownloadFailedNotification"

typedef enum{
    PutIODownloadStatusPending,
    PutIODownloadStatusDownloading,
    PutIODownloadStatusPaused,
    PutIODownloadStatusFinished,
    PutIODownloadStatusCancelled,
    PutIODownloadStatusFailed
} PutIODownloadStatus;

@interface PutIODownload : NSObject
<NSURLConnectionDataDelegate, NSCoding>
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

+ (NSArray*)allDownloads;
+ (void)clearDownloadList;
+ (BOOL)downloadExistsForFile:(PutIOAPIFile*)file;
+ (void)pauseAndSaveAllDownloads;
+ (void)saveDownloads;
+ (void)complyWithMaximumParallelDownloads;

- (id)initWithPutIOFile:(PutIOAPIFile*)file localPath:(NSString*)path subdirectoryPath:(NSString*)subdirectoryPath originatingSyncInstruction:(SyncInstruction*)syncInstruction;

@property (readonly,strong) PutIOAPIFile *putioFile;
@property (readonly) float progress;
@property (readonly) BOOL progressIsKnown;
@property (readonly) PutIODownloadStatus status;
@property (readonly,strong) NSString *localizedStatus;
@property (readonly) NSTimeInterval estimatedRemainingTime;
@property (readonly) BOOL estimatedRemainingTimeIsKnown;
@property (readonly) NSUInteger totalSize;
@property (readonly) NSUInteger receivedSize;
@property (readonly) NSUInteger bytesPerSecond;
@property (readonly,unsafe_unretained) SyncInstruction *originatingSyncInstruction;
@property (readonly,strong) NSError *downloadError;
@property (readonly,strong) NSString *localFile;

- (void)startDownload;
- (void)pauseDownload;
- (void)cancelDownload;
- (void)unlinkFromOriginatingSyncInstruction;

@end
