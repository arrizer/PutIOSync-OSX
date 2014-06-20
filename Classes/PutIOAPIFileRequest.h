
#import "PutIOAPIRequest.h"
#import "PutIOAPIFile.h"

@interface PutIOAPIFileRequest : PutIOAPIRequest

@property PutIOAPIFile *parentFolder;
@property NSArray *files;

+ (instancetype)requestFilesInRootFolderWithCompletion:(PutIOAPIRequestCompletion)completion;
+ (instancetype)requestFilesInFolderWithID:(NSInteger)folderID completion:(PutIOAPIRequestCompletion)completion;

@end
