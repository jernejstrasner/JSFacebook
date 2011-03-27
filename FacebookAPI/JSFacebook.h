//
//  JSFacebook.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "FBConnect.h"


#define FACEBOOK_APP_ID @"150562561623295"

typedef void (^voidBlock)(void);
typedef void (^successBlock)(id responseObject);
typedef void (^errorBlock)(NSError *error);

@interface JSFacebook : NSObject <FBSessionDelegate> {
	Facebook *facebook_;

	// Grand Central Dispatch
	dispatch_queue_t network_queue;
	
	@private
	// Login blocks
	voidBlock loginSucceededBlock_;
	voidBlock loginFailedBlock_;
}

@property (nonatomic, readonly) Facebook *facebook;

+ (JSFacebook *)sharedInstance;

// Authorization
- (void)loginAndOnSuccess:(voidBlock)succBlock onError:(voidBlock)errBlock;
- (void)logout;

// Graph API requests
- (void)requestWithGraphPath:(NSString *)graphPath
				   andParams:(NSDictionary *)params
			   andHttpMethod:(NSString *)httpMethod
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock;

- (void)requestWithGraphPath:(NSString *)graphPath
				   andParams:(NSDictionary *)params
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock;

- (void)requestWithGraphPath:(NSString *)graphPath
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock;


@end
