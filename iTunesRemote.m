/* Copyright (c) 2002 - 2003 by iThink Software. All Rights Reserved. */

#import "iTunesRemote.h"


@implementation iTunesRemote

+ (id)remote {
    return [[[iTunesRemote alloc] init] autorelease];
}

- (id)valueOfProperty:(ITMTRemoteProperty)property {
    // Get from Info.plist
    return nil;
}

- (NSDictionary *)propertiesAndValues {
    // Get from Info.plist
    return nil;
}

- (ITMTPlayerStyle)playerStyle {
    return ITMTSinglePlayerStyle;
}

- (BOOL)activate {
    if ( !_activated ) {
        if ( [self iTunesIsRunning] ) {
            _currentPSN = [self iTunesPSN];
        } else {
            if ( [self launchiTunes] ) {
                _currentPSN = [self iTunesPSN];
            } else {
                return NO;
            }
        }
        if ( ( _player = [iTunesPlayer sharedPlayerForRemote:self] ) ) {
            _activated = YES;
            return YES;
        }
    } else {
        return NO;
    }
}

- (BOOL)deactivate {
    if ( _activated ) {
        _currentPSN = kNoProcess;
        _player = nil;
        _activated = NO;
        return YES;
    } else {
        return NO;
    }
}

- (ITMTPlayer *)currentPlayer {
    if (_activated) {
        return _player;
    } else {
        return nil;
    }
}

- (NSArray *)players {
    if (_activated) {
        return [NSArray arrayWithObject:_player];
    } else {
        return nil;
    }
}

#pragma mark -
#pragma mark INTERNAL METHODS
#pragma mark -

- (BOOL)launchiTunes {
    return NO;
}

- (BOOL)iTunesIsRunning {
    return NO;
}

- (ProcessSerialNumber)iTunesPSN
{
    ProcessSerialNumber number;
    number.highLongOfPSN = kNoProcess;
    number.lowLongOfPSN = 0;
    
    while ( (GetNextProcess(&number) == noErr) ) 
    {
        CFStringRef name;
        if ( (CopyProcessName(&number, &name) == noErr) )
        {
            if ([(NSString *)name isEqualToString:@"iTunes"])
            {
                return number;
            }
            [(NSString *)name release];
        }
    }
    return number;
}

@end
