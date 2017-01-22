
#import "PutIOAPIFile.h"
#import "Download.h"

@interface PutIODownloadManager : NSObject

@property (nonatomic, readonly) NSInteger numberOfRunningDownloads;
@property (nonatomic, readonly, copy) NSArray *allDownloads;

+ (instancetype)manager;

- (void)addDownload:(Download*)download;
- (void)loadDownloads;
- (void)clearDownloadList;
- (BOOL)downloadExistsForFile:(PutIOAPIFile*)file;
- (void)saveDownloads;
- (void)complyWithMaximumParallelDownloads;

@end
