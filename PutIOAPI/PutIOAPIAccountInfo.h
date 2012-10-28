
#import "PutIOAPIObject.h"

@interface PutIOAPIAccountInfo : PutIOAPIObject

@property (readonly) NSString *username;
@property (readonly) NSString *eMailAddress;
@property (readonly) NSString *freeDiskSpace;
@property (readonly) NSInteger usedDiskSpace;
@property (readonly) NSInteger totalDiskSpace;

@end
