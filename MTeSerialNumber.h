/*
 *	MenuTunes
 *  MTeSerialNumber
 *    Object which represents, and operates on,
 *    an eSellerate serial number.
 *
 *  Original Author : Matt Judy <mjudy@ithinksw.com>
 *   Responsibility : Matt Judy <mjudy@ithinksw.com>
 *
 *  Copyright (c) 2003 iThink Software.
 *  All Rights Reserved
 *
 */

#import <Cocoa/Cocoa.h>


typedef enum {
    ITeSerialNumberIsDead    = -1 ,
    ITeSerialNumberIsInvalid =  0 ,
    ITeSerialNumberIsValid   =  1
} MTeSerialNumberValidationResult;

typedef enum {
    ITeSerialNumberWillNotExpire = -1 ,
    ITeSerialNumberHasExpired    =  0 ,
    ITeSerialNumberWillExpire    =  1
} MTeSerialNumberExpirationResult;


@interface MTeSerialNumber : NSObject {
    NSString *_serialNumber;
    NSString *_nameBasedKey;
    NSString *_extraDataKey;
    NSString *_publisherKey;

    NSArray *_deadSerials;
}

/*************************************************************************/
#pragma mark -
#pragma mark INITIALIZATION METHODS
/*************************************************************************/

/*!
    @method initWithSerialNumber:name:extra:publisher:
    @abstract Creates an ITeSerialNumber with the information provided.
    @discussion This is the designated initializer for this class.
    @param serial The eSellerate serial number
    @param name The name-based key for the serial number
    @param extra This is present for future use.  eSellerate does not use this data yet.  Pass nil.
    @param publisher The publisher key, provided by the Serial Number management part of eSellerate.
    @result The newly initialized object.
*/
- (id)initWithSerialNumber:(NSString *)serial
                      name:(NSString *)name
                     extra:(NSString *)extra  // Extra data not used.  Pass nil.
                 publisher:(NSString *)publisher;

/*!
    @method initWithDictionary:
    @abstract Creates an ITeSerialNumber with the information provided in dictionary form
    @discussion Utilizes initWithSerialNumber:name:extra:publisher:
    @param dict Consists of 4 keys, and 4 NSStrings.  The keys must be named 
                "Key", "Owner", "Extra", and "Publisher".
    @result The newly initialized object.
*/
- (id)initWithDictionary:(NSDictionary *)dict;

/*!
    @method initWithContentsOfFile:extra:publisher:
    @abstract Creates an ITeSerialNumber from the combination of a plist, and arguments.
    @discussion Only the serial (Key) and name (Owner) should ever be stored in the plist,
                for security.  This method will ignore any other data present in the file.
    @param path Path to the file on disk.  This file must be a plist containing one dictionary.
    @param extra eSellerate extra data.  Currently unused by eSellerate.  Pass nil.
    @param publisher The publisher key, provided by the Serial Number management part of eSellerate.
    @result The newly initialized object.
*/
- (id)initWithContentsOfFile:(NSString *)path
                       extra:(NSString *)extra
                   publisher:(NSString *)publisher;


/*************************************************************************/
#pragma mark -
#pragma mark ACCESSOR METHODS
/*************************************************************************/

- (NSString *)serialNumber;
- (void)setSerialNumber:(NSString *)newSerial;

- (NSString *)nameBasedKey;
- (void)setNameBasedKey:(NSString *)newName;

- (NSString *)extraDataKey;
- (void)setExtraDataKey:(NSString *)newData;

- (NSString *)publisherKey;
- (void)setPublisherKey:(NSString *)newPublisher;

- (NSArray *)deadSerials;
- (void)setDeadSerials:(NSArray *)newList;


/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

/*!
    @method isValid
    @abstract Checks the current serial for validity.
    @result ITeSerialNumberValidationResult, based on the current serial's validity.
*/
- (MTeSerialNumberValidationResult)isValid;

/*!
    @method isExpired
    @abstract Tests for validity, and returns whether or not the
              serial is expired, or will expire.
    @result YES if the serial will expire, NO if it will not.
*/
- (MTeSerialNumberExpirationResult)isExpired;

- (NSDate *)storedDate;

- (NSTimeInterval)secondsRemaining;

- (NSDictionary *)infoDictionary;

@end
