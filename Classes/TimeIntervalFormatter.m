
#import "TimeIntervalFormatter.h"

@implementation TimeIntervalFormatter

static const double multipliers[] = {1.0f, 60.0f, 60.0f * 60.0f, 60.0f * 60.0f * 24.0f};
static NSArray *unitsSingular;
static NSArray *unitsPlural;

- (instancetype)init
{
    self = [super init];
    if (self) {
        if(!unitsSingular){
            unitsSingular = @[
                NSLocalizedString(@"second", nil),
                NSLocalizedString(@"minute", nil),
                NSLocalizedString(@"hour", nil),
                NSLocalizedString(@"day", nil)
            ];
            unitsPlural = @[
                NSLocalizedString(@"seconds", nil),
                NSLocalizedString(@"minutes", nil),
                NSLocalizedString(@"hours", nil),
                NSLocalizedString(@"days", nil)
            ];
        }
    }
    return self;
}

-(NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    long seconds = fabs(interval);
    NSString *result = @"";
    for(int i = 3; i >= 0; i--){
        int value = (int)floor((double)seconds / multipliers[i]);
        if(value > 0){
            seconds = seconds % (long)multipliers[i];
            result = [result stringByAppendingFormat:@"%i %@ ", value, (value == 1 ? unitsSingular[i] : unitsPlural[i])];
            if(i == 1){
                // Hide seconds when we already have minutes
                break;
            }
        }
    }
    return result;
}

@end
