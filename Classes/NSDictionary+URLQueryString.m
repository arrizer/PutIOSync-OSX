
#import "NSDictionary+URLQueryString.h"

@implementation NSDictionary(URLQueryString)

-(NSString *)URLQueryString
{
    NSMutableArray *parts = [NSMutableArray array];
    for(NSString *key in self){
        NSString *value = [self objectForKey:key];
        NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValue = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

@end
