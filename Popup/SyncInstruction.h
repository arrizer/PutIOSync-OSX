
#import <Foundation/Foundation.h>

@interface SyncInstruction : NSObject
<NSCoding, NSCopying>
{

}

@property (assign) NSInteger originFolderID;
@property (strong) NSString *originFolderName;
@property (strong) NSURL *localDestination;
@property (assign) BOOL deleteRemoteFilesAfterSync;

@property (assign) BOOL localDestinationIsStale;
@property (readonly) NSError *bookmarkResolveError;

@end
