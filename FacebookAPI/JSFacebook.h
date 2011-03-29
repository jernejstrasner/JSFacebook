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
#import "JSGraphRequest.h"


#define FACEBOOK_APP_ID @"150562561623295"

typedef void (^voidBlock)(void);
typedef void (^successBlock)(id responseObject);
typedef void (^errorBlock)(NSError *error);
typedef void (^successBlockBatch)(NSArray *responseObjects);

@interface JSFacebook : NSObject <FBSessionDelegate> {
	Facebook *facebook_;

	// Grand Central Dispatch
	dispatch_queue_t network_queue;
	
	@private
	// Login blocks
	voidBlock loginSucceededBlock_;
	voidBlock loginFailedBlock_;
	voidBlock logoutSucceededBlock_;
}

@property (nonatomic, readonly) Facebook *facebook;

+ (JSFacebook *)sharedInstance;

// Authorization
- (void)loginAndOnSuccess:(voidBlock)succBlock onError:(voidBlock)errBlock;
- (void)logoutAndOnSuccess:(voidBlock)succBlock;

// Graph API requests
- (void)fetchRequest:(JSGraphRequest *)graphRequest
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
