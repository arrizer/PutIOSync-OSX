#import "MenubarController.h"
#import "StatusItemView.h"

@interface MenubarController ()

@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;

@end


@implementation MenubarController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        // Install status item into the menu bar
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:MenubarControllerStatusItemWidth];
        NSImage *image = [NSImage imageNamed:@"Status"];
        image.template = YES;
        self.statusItem.button.image = image;
        self.statusItem.button.target = [NSApplication sharedApplication].delegate;
        self.statusItem.button.action = @selector(togglePanel:);
    }
    return self;
}

- (void)dealloc
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

@end
