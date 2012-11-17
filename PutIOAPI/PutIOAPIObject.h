
#import <Foundation/Foundation.h>

@interface PutIOAPIObject : NSObject
<NSCoding>
{
    id rawData;
}

@property (readonly) id rawData;

- (id)initWithRawData:(id)data;

// Helper functions

+ (NSDate*)dateFromRawDataString:(NSString*)dateString;

@end