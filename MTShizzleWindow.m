#import "MTShizzleWindow.h"
#import "MainController.h"

@interface MTShizzleWindow (Private)
- (void)setBling:(id)bling;
- (void)buildWindow;
- (void)setTargets;
@end

@implementation MTShizzleWindow

static MTShizzleWindow *_privateSharedWindow = nil;

+ (id)sharedWindowForSender:(id)sender
{
    if( _privateSharedWindow ) {
        [_privateSharedWindow setBling:sender];
        return _privateSharedWindow;
    } else {
        _privateSharedWindow = [[MTShizzleWindow alloc]
                        initWithContentRect:NSMakeRect(0, 0, 385, 353)
                        styleMask:NSTitledWindowMask
                        backing:NSBackingStoreBuffered
                        defer:YES];
        [_privateSharedWindow setBling:sender];
        return _privateSharedWindow;
    }
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
    if ( (self = [super initWithContentRect:contentRect
                        styleMask:styleMask
                        backing:backingType
                        defer:flag]) ) {
        [self buildWindow];
    }
    return self;
}

- (void)makeKeyAndOrderFront:(id)sender {
    if ( ( [[NSDate date] timeIntervalSinceDate:[[MainController sharedController] getBlingTime]] >= 604800 ) && ([[regLater title] isEqualToString:@"Register Later"]) ) {
        [regLater setTitle:@"Quit"];
        [regLater setTarget:[NSApplication sharedApplication]];
        [regLater setAction:@selector(terminate:)];
    }
    [super makeKeyAndOrderFront:sender];
}        

- (void)dealloc
{
    [regMessage release];
    [regBenefits release];
    [enterInfo release];
    [owner release];
    [key release];
    [ownerEntry release];
    [keyEntry release];
    [registerButton release];
    [regLater release];
    [verifyKey release];
    [contentView release];
    [box release];
    [super dealloc];
}

- (void)setBling:(id)bling
{
    _sender = bling;
    [self setTargets];
}

- (void)buildWindow
{
    unichar returnChar = '\r';
    
    [self setReleasedWhenClosed:NO];
    [self setTitle:[NSString stringWithFormat:@"Register %@", @"MenuTunes"]];
    contentView = [self contentView];
    
    regMessage = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 282, 345, 51)];
    [regMessage setStringValue:[NSString stringWithFormat:@"%@ is shareware.  If you find it to be a valuable tool, please click the button below to buy your copy.  Your support is greatly appreciated.", @"MenuTunes"]];
    [regMessage setBordered:NO];
    [regMessage setBezeled:NO];
    [regMessage setEditable:NO];
    [regMessage setSelectable:NO];
    [regMessage setDrawsBackground:NO];
    [contentView addSubview:regMessage];
    
    //Make me gray!
    box = [[NSBox alloc] initWithFrame:NSMakeRect(20, 181, 345, 81)];
    [box setTitlePosition:NSNoTitle];
    [box setBorderType:NSBezelBorder];
    [contentView addSubview:box];
    
    //This isn't tall enough
    registerButton = [[NSButton alloc] initWithFrame:NSMakeRect(24, 13, 115, 49)];
    [registerButton setImage:[NSImage imageNamed:@"esellerate"]];
    [registerButton setButtonType:NSMomentaryPushButton];
    [registerButton setBezelStyle:NSRegularSquareBezelStyle];
    [registerButton setTarget:_sender];
    [registerButton setAction:@selector(goToTheStore:)];
    [[box contentView] addSubview:registerButton];
    
    regBenefits = [[NSTextField alloc] initWithFrame:NSMakeRect(152, 16, 175, 42)];
    [regBenefits setStringValue:[NSString stringWithUTF8String:"• Register instantly and easily.\n• Fast, secure transaction.\n• Major credit cards accepted."]];
    [regBenefits setBordered:NO];
    [regBenefits setBezeled:NO];
    [regBenefits setEditable:NO];
    [regBenefits setSelectable:NO];
    [regBenefits setDrawsBackground:NO];
    [regBenefits setFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
    [[box contentView] addSubview:regBenefits];
    
    enterInfo = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 148, 345, 17)];
    [enterInfo setStringValue:@"Please enter your registration information below."];
    [enterInfo setBordered:NO];
    [enterInfo setBezeled:NO];
    [enterInfo setEditable:NO];
    [enterInfo setSelectable:NO];
    [enterInfo setDrawsBackground:NO];
    [enterInfo setFont:[NSFont fontWithName:@"Lucida Grande" size:13]];
    [contentView addSubview:enterInfo];
    
    owner = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 126, 345, 14)];
    [owner setStringValue:@"License Owner:"];
    [owner setBordered:NO];
    [owner setBezeled:NO];
    [owner setEditable:NO];
    [owner setSelectable:NO];
    [owner setDrawsBackground:NO];
    [owner setFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
    [contentView addSubview:owner];
    
    key = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 82, 345, 14)];
    [key setStringValue:@"License Key:"];
    [key setBordered:NO];
    [key setBezeled:NO];
    [key setEditable:NO];
    [key setSelectable:NO];
    [key setDrawsBackground:NO];
    [key setFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
    [contentView addSubview:key];
    
    ownerEntry = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 104, 345, 22)];
    [ownerEntry setTarget:_sender];
    [ownerEntry setAction:@selector(verifyKey:)];
    [contentView addSubview:ownerEntry];
    
    keyEntry = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 60, 345, 22)];
    [keyEntry setTarget:_sender];
    [keyEntry setAction:@selector(verifyKey:)];
    [contentView addSubview:keyEntry];
    
    regLater = [[NSButton alloc] initWithFrame:NSMakeRect(138, 16, 116, 25)];
    [regLater setTitle:@"Register Later"];
    [regLater setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [regLater setTarget:_sender];
    [regLater setAction:@selector(registerLater:)];
    [regLater setBezelStyle:NSRoundedBezelStyle];
    [contentView addSubview:regLater];
    
    verifyKey = [[NSButton alloc] initWithFrame:NSMakeRect(255, 16, 116, 25)];
    [verifyKey setTitle:@"Verify Key"];
    [verifyKey setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [verifyKey setTarget:_sender];
    [verifyKey setAction:@selector(verifyKey:)];
    [verifyKey setBezelStyle:NSRoundedBezelStyle];
    [verifyKey setKeyEquivalent:[NSString stringWithCharacters:&returnChar length:1]];
    [contentView addSubview:verifyKey];
}

- (void)setTargets
{
    [registerButton setTarget:_sender];
    [ownerEntry setTarget:_sender];
    [keyEntry setTarget:_sender];
    [regLater setTarget:_sender];
    [verifyKey setTarget:_sender];
}

- (NSString *)owner
{
    return [ownerEntry stringValue];
}

- (NSString *)key
{
    return [keyEntry stringValue];
}

@end
