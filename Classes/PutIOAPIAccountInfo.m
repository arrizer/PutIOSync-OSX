
#import "PutIOAPIAccountInfo.h"

@implementation PutIOAPIAccountInfo

-(id)initWithRawData:(id)data
{
    self = [super initWithRawData:data];
    if(self){
        NSDictionary *info = rawData[@"info"];
        _username = info[@"username"];
        _eMailAddress = info[@"mail"];
        _freeDiskSpace = [info[@"disk"][@"avail"] integerValue];
        _usedDiskSpace = [info[@"disk"][@"used"] integerValue];
        _totalDiskSpace = [info[@"disk"][@"size"] integerValue];
    }
    return self;
}

@end
