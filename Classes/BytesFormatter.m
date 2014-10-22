
#import "BytesFormatter.h"

@implementation BytesFormatter

static const char units[] = {'\0', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'};
static const int precisions[] = {0, 0, 1, 2, 2, 4, 4, 4, 4};
static NSNumberFormatter* formatter;

-(NSString *)stringFromBytes:(double)bytes
{
    int multiplier = 1024;
    int exponent = 0;
    
    while(bytes >= multiplier && exponent < (sizeof units - 1)){
        bytes /= multiplier;
        exponent++;
    }
    
    if(formatter == nil){
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    formatter.maximumFractionDigits = precisions[exponent];
    formatter.minimumFractionDigits = precisions[exponent];
    
    // Beware of reusing this format string. -[NSString stringWithFormat] ignores \0, *printf does not.
    return [NSString stringWithFormat:@"%@ %cB", [formatter stringFromNumber:[NSNumber numberWithDouble: bytes]], units[exponent]];
}

@end
