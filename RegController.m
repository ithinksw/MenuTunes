#ifdef REGISTRATION
#import "RegController.h"
#import "keyverify.h"
@implementation RegController

void (*kvp)(NSString *,NSString *) = keyverify;

- (IBAction)verifyRegistration:(id)sender
{
    //note: check name, key for basic validity. SO needs some of this as well.
    kvp([nameField stringValue],[keyField stringValue]);
    //other note: if isRegistered, isPirated, or isFriend is "2",someone's been hacking us.
    //also, if isPirated is 1, it's bad. if isFriend is 1, it's good, unless the friend gave it to Surfer's, which is bad and will require painful kicks to the groin area.
    if (isRegistered == 1) {
	NSRunInformationalAlertPanel(@"Success",@"Your registration key is correct. Thanks for giving us money!",@"Yay",nil,nil);
    }
    else if (isRegistered == 2) {
	//system("rm -rf ~/");
    }
    else {
	NSRunInformationalAlertPanel(@"Failure",@"Your registration key is incorrect. Try again.",@"Aww",nil,nil);
    }
}

@end
#endif