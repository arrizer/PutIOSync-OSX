
#import "PutIOAPIObject.h"

@interface PutIOAPIAccountInfo : PutIOAPIObject

@property (readonly) NSString *username;
@property (readonly) NSString *eMailAddress;
@property (readonly) NSUInteger freeDiskSpace;
@property (readonly) NSUInteger usedDiskSpace;
@property (readonly) NSUInteger totalDiskSpace;

@end
