/* MenuTunes */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class MenuTunesView, PreferencesController, StatusWindowController;

@interface MenuTunes : NSObject
{
    NSStatusItem *statusItem;
    NSMenu *menu;
    MenuTunesView *view;
    
    //Used in updating the menu automatically
    NSTimer *refreshTimer;
    int curTrackIndex;
    int trackInfoIndex;
    
    ProcessSerialNumber iTunesPSN;
    bool didHaveAlbumName; //Helper variable for creating the menu
    
    //For upcoming songs
    NSMenuItem *upcomingSongsItem;
    NSMenu *upcomingSongsMenu;
    
    //For playlist selection
    NSMenuItem *playlistItem;
    NSMenu *playlistMenu;
    
    //For EQ sets
    NSMenuItem *eqItem;
    NSMenu *eqMenu;
    
    NSMenuItem *playPauseMenuItem; //Toggle between 'Play' and 'Pause'
    
    PreferencesController *prefsController;
    StatusWindowController *statusController; //Shows track info and upcoming songs.
}

- (void)rebuildMenu;
- (void)updateMenu;
- (void)rebuildUpcomingSongsMenu;
- (void)rebuildPlaylistMenu;
- (void)rebuildEQPresetsMenu;

- (void)clearHotKeys;
- (void)setupHotKeys;

- (NSString *)runScriptAndReturnResult:(NSString *)script;
- (void)timerUpdate;

- (ProcessSerialNumber)iTunesPSN;

- (void)sendAEWithEventClass:(AEEventClass)eventClass andEventID:(AEEventID)eventID;

- (void)closePreferences;

@end
