
#import "PutIOAPIFile.h"
#import "Download.h"

@interface PutIODownloadManager : NSObject

+ (instancetype)manager;

- (void)addDownload:(Download*)download;
- (void)loadDownloads;
@property (nonatomic, readonly) NSInteger numberOfRunningDownloads;
@property (nonatomic, readonly, copy) NSArray *allDownloads;
- (void)clearDownloadList;
- (BOOL)downloadExistsForFile:(PutIOAPIFile*)file;
- (void)saveDownloads;
- (void)complyWithMaximumParallelDownloads;

@end
