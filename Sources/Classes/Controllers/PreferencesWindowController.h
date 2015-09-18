/////////////////////////////////////////////////////////////////////////////////
//
//  PreferencesWindowController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file PreferencesWindowController.h

/////////////////////////////////////////////////////////////////////////////////
extern NSString *const kDynamicIPDidChangeNotification;
extern NSString *const kNewIPAddress;

@class LoginItemHelper;

/////////////////////////////////////////////////////////////////////////////////
//! This class represents preferences window controller
@interface PreferencesWindowController : NSWindowController 
{
	@private
        LoginItemHelper *loginItem; //!< helper to operate with system login items
}

//! Value of minimal default update interval
@property (nonatomic, readonly) NSInteger minimalIPUpdateInterval;
//! Indicates if use minutes for IP monitoring service
@property (nonatomic, readonly) BOOL shouldUseMinutes;
//! Indicates if use hours for IP monitoring service
@property (nonatomic, readonly) BOOL shouldUseHours;
//! Indicates if use days for IP monitoring service
@property (nonatomic, readonly) BOOL shouldUseDays;
//! Value of minutes for IP monitoring period
@property (nonatomic, readonly) NSInteger minutes;
//! Value of hours for IP monitoring period
@property (nonatomic, readonly) NSInteger hours;
//! Value of days for IP monitoring period
@property (nonatomic, readonly) NSInteger days;
//! Indicates if add application to system login items
@property (nonatomic, assign) BOOL shouldAddToLoginItems;
//! Indicates if launch application minimized
@property (nonatomic, readonly) BOOL shouldLaunchMinimized;

//! Indicates if start detecting IP automatically 
@property (nonatomic, readonly) BOOL shouldAutodetectIP;
//! A date of last IP update
@property (nonatomic, retain) NSDate *lastIPUpdate;
//! Value of last IP
@property (nonatomic, retain) NSString *lastIP;

//! Stores settings in specified container
- (void)storeToContainer:(NSMutableDictionary *)aContainer;
//! Restores settings from specified container
- (void)restoreFromContainer:(NSDictionary *)aContainer;

@end
