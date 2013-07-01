
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

-(id)initWithCoder:(NSCoder *)decoder
{
    rawData = [decoder decodeObjectForKey:@"rawData"];
    self = [self initWithRawData:rawData];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:rawData forKey:@"rawData"];
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
