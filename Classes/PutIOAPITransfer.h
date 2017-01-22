
#import "PutIOAPIObject.h"

typedef NS_ENUM(NSInteger, PutIOAPITransferStatus) {
    PutIOAPITransferStatusUnknown = 0,
    PutIOAPITransferStatusInQueue = 1,
    PutIOAPITransferStatusDownloading = 2,
    PutIOAPITransferStatusSeeding = 3,
    PutIOAPITransferStatusCompleted = 4,
    PutIOAPITransferStatusFailed = 5
};

@interface PutIOAPITransfer : PutIOAPIObject
{
    
}

@property (assign) NSInteger transferID;
@property (assign) NSInteger fileID;
@property (assign) NSInteger destinationFolderID;
@property (assign) NSInteger originatingSubscriptionID;
@property (assign) NSTimeInterval estimatedTimeRemaining;
@property (strong) NSString *filename;
@property (assign) float progress;
@property (assign) PutIOAPITransferStatus status;
@property (assign) NSInteger seedingToPeersCount;
@property (assign) NSInteger leechingFromPeersCount;
@property (assign) NSInteger connectedPeersCount;
@property (assign) float torrentRatio;
@property (assign) NSInteger size;
@property (assign) NSInteger sizeUploaded;
@property (assign) NSInteger uploadSpeed;
@property (assign) NSInteger sizeDownloaded;
@property (assign) NSInteger downloadSpeed;
@property (assign) BOOL willExtractWhenFinished;
@property (assign) BOOL isSeeding;
@property (strong) NSString *trackerMessage;
@property (strong) NSString *errorMessage;
@property (strong) NSURL *sourceURL;
@property (strong) NSDate *startTime;

@end
