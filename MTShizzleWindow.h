#import <Cocoa/Cocoa.h>

@interface MTShizzleWindow : NSWindow
{
    NSTextField *regMessage, *regBenefits, *enterInfo, *owner, *key;
    NSTextField *ownerEntry, *keyEntry;
    NSView *contentView;
    NSBox *box;
    NSButton *registerButton, *regLater, *verifyKey;
    
    id _sender;
}

+ (id)sharedWindowForSender:(id)sender;
- (NSString *)owner;
- (NSString *)key;

@end