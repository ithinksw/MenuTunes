#import "MTeSerialNumber.h"
#import "validate.h"
#import <openssl/sha.h>

@interface MTeSerialNumber (Private)
- (short)validate;
- (eSellerate_String)eSellerateStringForString:(NSString *)string;
@end

@implementation MTeSerialNumber

/*************************************************************************/
#pragma mark -
#pragma mark INITIALIZATION METHODS
/*************************************************************************/

- (id)initWithSerialNumber:(NSString *)serial
                      name:(NSString *)name
                     extra:(NSString *)extra
                 publisher:(NSString *)publisher
{
    if ( (self = [super init]) ) {
        _serialNumber = serial;
        _nameBasedKey = name;
        _extraDataKey = nil;       //extra data is currently unused.
        _publisherKey = publisher;
        _deadSerials  = nil;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    return [self initWithSerialNumber:[dict objectForKey:@"Key"]
                                 name:[dict objectForKey:@"Owner"]
                                extra:[dict objectForKey:@"Extra"]
                            publisher:[dict objectForKey:@"Publisher"]];
}

- (id)initWithContentsOfFile:(NSString *)path
                       extra:(NSString *)extra
                   publisher:(NSString *)publisher
{
    NSDictionary *fileDict = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    
    if ( fileDict ) {
        NSMutableDictionary *dict = [[[NSMutableDictionary alloc] initWithCapacity:4] autorelease];

        [dict setObject:[fileDict objectForKey:@"Key"] forKey:@"Key"];
        [dict setObject:[fileDict objectForKey:@"Owner"] forKey:@"Owner"];
        [dict setObject:extra forKey:@"Extra"];
        [dict setObject:publisher forKey:@"Publisher"];

        return [self initWithDictionary:dict];
    } else {
        return nil;
    }
}


/*************************************************************************/
#pragma mark -
#pragma mark ACCESSOR METHODS
/*************************************************************************/

- (NSString *)serialNumber
{
    return _serialNumber;
}

- (void)setSerialNumber:(NSString *)newSerial
{
    [_serialNumber autorelease];
    _serialNumber = [newSerial copy];
}

- (NSString *)nameBasedKey
{
    return _nameBasedKey;
}

- (void)setNameBasedKey:(NSString *)newName
{
    [_nameBasedKey autorelease];
    _nameBasedKey = [newName copy];
}

- (NSString *)extraDataKey
{
    return _extraDataKey;
}

- (void)setExtraDataKey:(NSString *)newData
{
    [_extraDataKey autorelease];
    _extraDataKey = [newData copy];
}

- (NSString *)publisherKey
{
    return _publisherKey;
}

- (void)setPublisherKey:(NSString *)newPublisher
{
    [_publisherKey autorelease];
    _publisherKey = [newPublisher copy];
}

- (NSArray *)deadSerials
{
    return _deadSerials;
}

- (void)setDeadSerials:(NSArray *)newList
{
    [_deadSerials autorelease];
    _deadSerials = [newList copy];
}


/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

- (MTeSerialNumberValidationResult)isValid
{
    if ( _serialNumber ) {

        BOOL dead = NO;
        unsigned char *result = SHA1([[_serialNumber stringByAppendingString:@"-h4x0r"] UTF8String], [_serialNumber length] + 5, NULL);
		if ([[[NSData dataWithBytes:result length:strlen(result)] description] isEqualToString:@"<db7ea71c 2919ff4b 520b6491 8d6813db b70647>"]) {
			dead = YES;
		}
		
        if ( [_deadSerials count] )  {
            NSEnumerator *deadEnum = [_deadSerials objectEnumerator];
            id            aDeadSerial;
            
            while ( (aDeadSerial = [deadEnum nextObject]) ) {
                if ( [aDeadSerial isEqualToString:_serialNumber] ) {
                    dead = YES;
            	}
            }
        }

        if ( dead ) {
            return ITeSerialNumberIsDead;
        } else {
            return ( ( [self validate] > 0 ) ? ITeSerialNumberIsValid : ITeSerialNumberIsInvalid );
        }
    } else {
        return nil;
    }
}

- (MTeSerialNumberExpirationResult)isExpired;
{
    return ( ! [self secondsRemaining] > 0 );
}

- (NSDate *)storedDate
{
    NSCalendarDate *refDate = [NSCalendarDate dateWithYear:2000 month:1 day:1
                                                      hour:0 minute:0 second:0
                                                  timeZone:[NSTimeZone systemTimeZone]];

    NSTimeInterval secondsFromRefToExp = ([self validate] * 86400);

    return [[[NSDate alloc] initWithTimeInterval:secondsFromRefToExp
                                       sinceDate:refDate] autorelease];
}

- (NSTimeInterval)secondsRemaining
{
    return [[self storedDate] timeIntervalSinceDate:[NSDate date]];
}

- (NSDictionary *)infoDictionary
{
    NSString *prefix        = [[_serialNumber componentsSeparatedByString:@"-"] objectAtIndex:0];
    NSString *appIdentifier = nil;
    NSString *version       = nil;
    NSString *typeCode      = nil;
    NSString *quantity      = nil;
    
    if ( ( [prefix length] == 10 ) || ( [prefix length] == 7 ) ) {
        appIdentifier = [_serialNumber substringWithRange:NSMakeRange(0,2)];
        version       = [_serialNumber substringWithRange:NSMakeRange(2,3)];
        typeCode      = [_serialNumber substringWithRange:NSMakeRange(5,2)];
    } else {
        return nil;
    }

    if ( [prefix length] == 10 ) {
        quantity = [_serialNumber substringWithRange:NSMakeRange(7,3)];
    }

    return [NSDictionary dictionaryWithObjectsAndKeys:
        appIdentifier, @"appIdentifier",
        version,       @"version",
        typeCode,      @"typeCode",
        quantity,      @"quantity",   nil];
}


/*************************************************************************/
#pragma mark -
#pragma mark PRIVATE IMPLEMENTATIONS
/*************************************************************************/

- (short)validate
{
    eSellerate_String pSerial    = [self eSellerateStringForString:_serialNumber];
    eSellerate_String pName      = [self eSellerateStringForString:_nameBasedKey];
    eSellerate_String pExtraData = [self eSellerateStringForString:_extraDataKey];
    eSellerate_String pPublisher = [self eSellerateStringForString:_publisherKey];
    
    return eSellerate_ValidateSerialNumber(pSerial,
                                           pName,
                                           pExtraData,
                                           pPublisher);
}

- (eSellerate_String)eSellerateStringForString:(NSString *)string
{
    if ( string ) {
        NSMutableData *buffer = [[[NSMutableData alloc] initWithCapacity:256] autorelease];
        
        CFStringGetPascalString( (CFStringRef)string,
                                 [buffer mutableBytes],
                                 256,
                                 CFStringGetSystemEncoding());
                                 
        return (eSellerate_String)[buffer bytes];
    } else {
        return nil;
    }
}


@end
