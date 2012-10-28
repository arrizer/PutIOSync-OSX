
#import "PutIOAPIObject.h"

@implementation PutIOAPIObject

- (id)initWithRawData:(id)data
{
    self = [super init];
    if (self) {
        rawData = data;
    }
    return self;
}

-(id)rawData
{
    return rawData;
}

+ (NSDate*)dateFromRawDataString:(NSString*)dateString
{
    NSString *format = @"yyyy-MM-dd'T'HH:mm:ss";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO];
    return [dateFormatter dateFromString:dateString];
}

@end
