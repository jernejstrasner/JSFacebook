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

#import "FBConnect.h"
#import "JSFacebookRequest.h"
#import "JSFacebookLoginController.h"

// Constants
extern NSString * const kJSFacebookStringBoundary;
extern float const kJSFacebookImageQuality;
extern NSString * const kJSFacebookGraphAPIEndpoint;
extern NSString * const kJSFacebookAppID;

// Typedefs
typedef void (^voidBlock)(void);
typedef void (^successBlock)(id responseObject);
typedef void (^errorBlock)(NSError *error);
typedef void (^successBlockBatch)(NSArray *responseObjects);

@interface JSFacebook : NSObject <FBSessionDelegate> {
	Facebook *facebook_;

	@private
	// Grand Central Dispatch
	dispatch_queue_t network_queue;	
	// Login blocks
	voidBlock loginSucceededBlock_;
	voidBlock loginFailedBlock_;
	voidBlock logoutSucceededBlock_;
	// Access token
	NSString *_accessToken;
}

@property (nonatomic, readonly) Facebook *facebook;

@property (nonatomic, retain) NSString *accessToken;

+ (JSFacebook *)sharedInstance;

// Authorization
- (void)loginWithPermissions:(NSArray *)permissions
				   onSuccess:(voidBlock)succBlock
					 onError:(voidBlock)errBlock;
- (void)logoutAndOnSuccess:(voidBlock)succBlock;

// Graph API requests
- (void)fetchRequest:(JSFacebookRequest *)graphRequest
		   onSuccess:(successBlock)succBlock
			 onError:(errorBlock)errBlock;

- (void)requestWithGraphPath:(NSString *)graphPath
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock;

// Graph API batch requests
- (void)fetchRequests:(NSArray *)graphRequests
			onSuccess:(successBlockBatch)succBlock
			  onError:(errorBlock)errBlock;

@end
