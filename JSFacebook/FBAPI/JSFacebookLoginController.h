//
//  JSFacebookLoginController.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 4/2/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^JSFBLoginSuccessBlock)(void);
typedef void(^JSFBLoginErrorBlock)(NSError *error);

@interface JSFacebookLoginController : UIViewController <UIWebViewDelegate>

// Returns an autoreleased login controller
// It will automatically load the login page and perform the passed blocks
+ (JSFacebookLoginController *)loginControllerWithPermissions:(NSArray *)permissions
													onSuccess:(JSFBLoginSuccessBlock)successBlock
													  onError:(JSFBLoginErrorBlock)errorBlock;

- (id)initWithPermissions:(NSArray *)permissions
			 successBlock:(JSFBLoginSuccessBlock)successBlock
			   errorBlock:(JSFBLoginErrorBlock)errorBlock;

@end
