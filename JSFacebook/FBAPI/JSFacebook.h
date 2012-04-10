//
//  JSFacebook.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

#import "JSFacebook-NSDictionary.h"
#import "JSFacebook-NSString.h"

#import "JSFacebookRequest.h"
#import "JSFacebookLoginController.h"

// Constants
extern NSString * const kJSFacebookStringBoundary;
extern NSString * const kJSFacebookGraphAPIEndpoint;
extern NSString * const kJSFacebookAccessTokenKey;
extern NSString * const kJSFacebookAccessTokenExpiryDateKey;
extern NSString * const kJSFacebookErrorDomain;

enum {
	JSFacebookErrorCodeOther = 0,
	JSFacebookErrorCodeNetwork = 1,
	JSFacebookErrorCodeAuthentication = 2,
	JSFacebookErrorCodeServer = 3
};

// Typedefs
typedef void (^JSFBVoidBlock)(void);
typedef void (^JSFBSuccessBlock)(id responseObject);
typedef void (^JSFBErrorBlock)(NSError *error);
typedef void (^JSFBBatchSuccessBlock)(NSArray *responseObjects);

@interface JSFacebook : NSObject

@property (nonatomic, retain) NSString *facebookAppID;
@property (nonatomic, retain) NSString *facebookAppSecret;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSDate *accessTokenExpiryDate;

+ (JSFacebook *)sharedInstance;

#pragma mark Authorization

// This is only a convinience method that opens a modal window
// in the root view controller of the key winodow in your app.
// If you want more control over the login window presentation
// check out JSFacebookLoginController.
- (void)loginWithPermissions:(NSArray *)permissions
				   onSuccess:(JSFBLoginSuccessBlock)succBlock
					 onError:(JSFBLoginErrorBlock)errBlock;

// Destroys the current access token and expiry date.
// This method doesn not invalidate the access token on Facebook servers!
- (void)logout;

// Checks if the current login session is stil valid
- (BOOL)isSessionValid;

// Checks if the access token is still valid with the Facebook servers
- (void)validateAccessTokenWithCompletionHandler:(void(^)(BOOL isValid))completionHandler;

// Extends the access token's expiry date for 60 days
- (void)extendAccessTokenExpirationWithCompletionHandler:(void(^)(NSError *))completionHandler;

// Checks if the Facebook app ID was set and it's length is 15
- (BOOL)isFacebookAppIDValid;

// Handles the callback URL for SSO auth
- (void)handleCallbackURL:(NSURL *)url;

#pragma mark Graph API requests

// Fetches a single Graph API request
- (void)fetchRequest:(JSFacebookRequest *)graphRequest
		   onSuccess:(JSFBSuccessBlock)succBlock
			 onError:(JSFBErrorBlock)errBlock;

// Fetches the provieded Graph API path
- (void)requestWithGraphPath:(NSString *)graphPath
				   onSuccess:(JSFBSuccessBlock)succBlock
					 onError:(JSFBErrorBlock)errBlock;

#pragma mark Graph API batch requests

// Fetch multiple Graph API requests in one network request
// https://developers.facebook.com/docs/api/batch/
- (void)fetchRequests:(NSArray *)graphRequests
			onSuccess:(JSFBBatchSuccessBlock)succBlock
			  onError:(JSFBErrorBlock)errBlock;

#pragma mark Preferences

// Upload image quality (default 0.8 aka. 80% JPEG)
@property (nonatomic, assign) CGFloat imageQuality;

// Use SSO for authentication?
// More info: https://developers.facebook.com/docs/mobile/ios/build/#implementsso
@property (nonatomic, assign) BOOL useSSO;

@end
