
#define MenubarControllerStatusItemWidth 24.0

@interface MenubarController : NSObject

@property (nonatomic) BOOL hasActiveIcon;
@property (nonatomic, strong, readonly) NSStatusItem *statusItem;

@end
