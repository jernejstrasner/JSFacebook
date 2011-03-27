//
//  JSFacebook.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

#define FACEBOOK_APP_ID @"150562561623295"

@interface JSFacebook : NSObject <FBSessionDelegate> {
	Facebook *facebook_;
}

@property (nonatomic, readonly) Facebook *facebook;

+ (JSFacebook *)sharedInstance;

// Authorization
- (void)login;
- (void)logout;



@end
