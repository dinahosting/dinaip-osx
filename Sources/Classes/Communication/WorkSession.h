/////////////////////////////////////////////////////////////////////////////////
//
//  WorkSession.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file WorkSession.h

/////////////////////////////////////////////////////////////////////////////////
@protocol RPCExecutorDelegate;

/////////////////////////////////////////////////////////////////////////////////
//! This class represents work session for application after login
@interface WorkSession : NSObject 
{
	@private
        NSString *identifier; //!< Identifier of session
        NSString *password; //!< Password of session
        NSInteger loginType; //!< Login type of session
        NSArray *domains; //!< Retrived domains
        NSMutableArray *monitoredDomains; //!< Monitored domains 
        NSMutableDictionary *zones; //!< Zones of monitored domains
        NSString *sessionIP; //!< The IP in session
        NSMutableSet *pendingMethods; //!< Executing method
}

//! Monitored domains
@property (nonatomic, readonly) NSArray *monitoredDomains;
//! All available domains
@property (nonatomic, readonly) NSArray *domains;
//! Session identifier
@property (nonatomic, readonly) NSString *identifier;
//! Session password
@property (nonatomic, readonly) NSString *password;
//! Session login type
@property (nonatomic, readonly) NSInteger loginType;

//! Creates and initializes work session. Autorelease.
+ (id)sessionWithType:(NSInteger)aLoginType identifier:(NSString *)anID 
	password:(NSString *)aPassword domains:(NSArray *)aDomains;

//! Initializes work session.
- (id)initWithType:(NSInteger)aLoginType identifier:(NSString *)anID 
	password:(NSString *)aPassword domains:(NSArray *)aDomains;

//! Adds domain to monitored
- (void)addDomain:(NSString *)aDomain;
//! Removed domain from monitored
- (void)removeDomain:(NSString *)aDomain;

//! Performs update of zones for specified domain
- (void)updateZones:(NSArray *)aZones forDomain:(NSString *)aDomain 
	delegate:(id<RPCExecutorDelegate>)anObject;
//! Stores zones for specified domain
- (void)storeZones:(NSArray *)aZones forDomain:(NSString *)aDomain;

//! Stores session in persistent store
- (void)storeSession;
//! Restores session in persistent store
- (void)restoreSession;

//! Stores session in specified container
- (void)storeToContainer:(NSMutableDictionary *)aContainer;
//! Restores session from specified container
- (void)restoreFromContainer:(NSDictionary *)aContainer;

//! Provides monitored zones for specified domain
- (NSArray *)zonesForDomain:(NSString *)aDomain;
@end
