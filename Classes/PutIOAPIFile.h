
#import "PutIOAPIObject.h"

@interface PutIOAPIFile : PutIOAPIObject
{
    
}

@property (assign) NSInteger fileID;
@property (assign) NSInteger parentFileID;
@property (strong) NSString *name;
@property (strong) NSDate *dateCreated;
@property (strong) NSString *contentType;
@property (strong) NSURL *iconURL;
@property (strong) NSURL *screenshotURL;
@property (assign) NSInteger size;
@property (assign) BOOL isShared;
@property (assign) BOOL mp4VersionAvailable;
@property (readonly) BOOL isFolder;
@property (readonly) BOOL isRootFolder;
@property (strong) NSArray *subfolders;

@end
