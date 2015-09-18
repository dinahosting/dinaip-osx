/////////////////////////////////////////////////////////////////////////////////
//
//  LoginDinaDNS.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import "RPCMethod.h"

//! @file LoginDinaDNS.h

/////////////////////////////////////////////////////////////////////////////////
//! Type of log in performed by a user
enum LoginType
{
	kUserDinahostingLogin = 0, //!< user-type login
    kDomainLogin = 1 //!< domain-type login
};


/////////////////////////////////////////////////////////////////////////////////
//! This class represents RPC login method
@interface LoginDinaDNS : RPCMethod
{
	@private
        NSString *identifier; //!< login identifier
        NSString *password; //!< login password
        BOOL isDomain;
}
//! Login identifier
@property (nonatomic, retain) NSString *identifier;
//! Login password
@property (nonatomic, retain) NSString *password;

//! Creates and initializes new instance of RPC method of user type. Autoreleased.
+ (id)userLogin;
//! Creates and initializes new instance of RPC method of domain type. Autoreleased.
+ (id)domainLogin;

//! Initializes new instance of RPC method of provided type. Autoreleased.
- (id)initWithLoginType:(int)aType;

@end
