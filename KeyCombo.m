//
//  KeyCombo.m
//
//  Created by Quentin D. Carnicelli on Tue Jun 18 2002.
//  Copyright (c) 2001 Subband inc.. All rights reserved.
//

#import "KeyCombo.h"

#import <AppKit/NSEvent.h>
#import <Carbon/Carbon.h>

@interface KeyCombo (Private)
    + (NSString*)_stringForModifiers:(long)modifiers;
    + (NSString*)_stringForKeyCode:(short)keyCode;
@end


@implementation KeyCombo

+ (id)keyCombo
{
    return [[[self alloc] init] autorelease];
}

+ (id)clearKeyCombo
{
    return [self keyComboWithKeyCode:-1 andModifiers:-1];
}

+ (id)keyComboWithKeyCode: (short)keycode andModifiers: (long)modifiers
{
    return [[[self alloc] initWithKeyCode:keycode andModifiers:modifiers] autorelease];
}

- (id)initWithKeyCode: (short)keycode andModifiers: (long)modifiers
{
    if ( (self = [super init]) )
    {
        mKeyCode = keycode;
        mModifiers = modifiers;
    }
    return self;
}

- (id)init
{
    return [self initWithKeyCode: -1 andModifiers: -1];
}

- (id)copyWithZone:(NSZone *)zone;
{
    return [self retain];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( (self = [super init]) ) {
        [aDecoder decodeValueOfObjCType: @encode(short) at: &mKeyCode];
        [aDecoder decodeValueOfObjCType: @encode(long) at: &mModifiers];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{	
    [aCoder encodeValueOfObjCType:@encode(short) at:&mKeyCode];
    [aCoder encodeValueOfObjCType:@encode(long) at:&mModifiers];
}

- (BOOL)isEqual:(KeyCombo *)object
{
    return ( ([object isKindOfClass:[KeyCombo class]]) &&
             ([object keyCode] == [self keyCode])      &&
             ([object modifiers] == [self modifiers]) );
}

- (NSString *)description
{
    return [self userDisplayRep];
}

- (short)keyCode
{
    return mKeyCode;
}

- (short)modifiers
{
    return mModifiers;
}

- (BOOL)isValid
{
    return ((mKeyCode >= 0) && (mModifiers >= 0));
}

- (NSString *)userDisplayRep
{
    if ( ! [self isValid] ) {
        return @"None";
    } else {
        return [NSString stringWithFormat: @"%@%@",
            [KeyCombo _stringForModifiers: mModifiers],
            [KeyCombo _stringForKeyCode: mKeyCode]];
    }
}

+ (NSString *)_stringForModifiers: (long)modifiers
{
    static long modToChar[4][2] = {
            { cmdKey, 	0x23180000 },
            { optionKey,	0x23250000 },
            { controlKey,	0x005E0000 },
            { shiftKey,	0x21e70000 }
    };
    
    NSString *str = [NSString string];
    NSString *charStr;
    long i;
    
    for (i = 0; i < 4; i++) {
        if (modifiers & modToChar[i][0]) {
            charStr = [NSString stringWithCharacters:(const unichar *)&modToChar[i][1] length:1];
            str = [str stringByAppendingString:charStr];
        }
    }
    
    return str;
}

+ (NSString *)_stringForKeyCode:(short)keyCode
{
	NSDictionary *dict;
	id key;
	NSString *str;
	
	dict = [self keyCodesDictionary];
	key = [NSString stringWithFormat: @"%d", keyCode];
	str = [dict objectForKey: key];

    if( !str ) {
		str = [NSString stringWithFormat: @"%X", keyCode];
    }
	
	return str;
}

+ (NSDictionary *)keyCodesDictionary
{
    static NSDictionary *keyCodes = nil;
    
    if (keyCodes == nil) {
        NSString *path;
        NSString *contents;
        
        path = [[NSBundle bundleForClass: [KeyCombo class]] pathForResource: @"KeyCodes" ofType: @"plist"];
        
        contents = [NSString stringWithContentsOfFile: path];
        keyCodes = [[contents propertyList] retain];
    }
    
    return keyCodes;
}

@end

@implementation NSUserDefaults (KeyComboAdditions)

- (void)setKeyCombo:(KeyCombo *)combo forKey:(NSString *)key
{
    NSData *data;
    if (combo) {
        data = [NSArchiver archivedDataWithRootObject:combo];
    } else {
        data = nil;
    }
    [self setObject:data forKey:key];
}

- (KeyCombo *)keyComboForKey:(NSString *)key
{
    NSData *data = [self objectForKey:key];
    KeyCombo *combo;
    
    if (data) {
        combo = [[NSUnarchiver unarchiveObjectWithData:data] retain];
    } else {
        combo = nil;
    }
    
    return combo;
}

@end





