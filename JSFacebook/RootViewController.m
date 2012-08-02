//
//  RootViewController.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "RootViewController.h"

#import "JSFacebook.h"

@implementation RootViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Listen for the login successful notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookDidLogin:) name:kFacebookDidLoginNotification object:nil];
	
	self.title = @"Facebook API";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return YES;
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Facebook tests

- (void)facebookDidLogin:(NSNotification *)notification {
	/*
	 * Test the Facebook API
	 */
	
	NSLog(@"Testing the API...");
	
	JSFacebook *facebook = [JSFacebook sharedInstance];
	
	// Test the token extension
	[facebook extendAccessTokenExpirationWithCompletionHandler:^(NSError *error) {
		if (error) {
			DLog(@"Token extension error: %@", [error localizedDescription]);
		} else {
			DLog(@"Succesfully extended token!");
		}
	}];

	// Just make some random requests to test the queuing feature
	[facebook requestWithGraphPath:@"/me/home" onSuccess:^(id responseObject) {
		DLog(@"Response 1 received!");
	} onError:^(NSError *error) {
		DLog(@"Error 1: %@", [error localizedDescription]);
	}];
	[facebook requestWithGraphPath:@"/me/inbox" onSuccess:^(id responseObject) {
		DLog(@"Response 2 received!");
	} onError:^(NSError *error) {
		DLog(@"Error 2: %@", [error localizedDescription]);
	}];
	[facebook requestWithGraphPath:@"/me/feed" onSuccess:^(id responseObject) {
		DLog(@"Response 3 received!");
	} onError:^(NSError *error) {
		DLog(@"Error 3: %@", [error localizedDescription]);
	}];

	// Test posting to the Graph API
	/*
	JSFacebookRequest *graphRequest = [JSFacebookRequest requestWithGraphPath:@"/me/feed"];
	[graphRequest setHttpMethod:@"POST"];
	[graphRequest addParameter:@"message" withValue:@"Just testing :)"];
	[facebook fetchRequest:graphRequest onSuccess:^(id responseObject) {
		DLog(@"Posted to the wall!");
	} onError:^(NSError *error) {
		DLog(@"Error posting: %@", [error localizedDescription]);
	}];
	 */
	
	// Test the batch Graph API calls
	JSFacebookRequest *request1 = [JSFacebookRequest requestWithGraphPath:@"me/friends?limit=5"];
	[request1 setName:@"get-friends"];
	JSFacebookRequest *request2 = [JSFacebookRequest requestWithGraphPath:@"?ids={result=get-friends:$.data..id}"];
	[facebook fetchRequests:@[request1, request2] onSuccess:^(NSArray *responseObjects) {
		DLog(@"Responses:\n%@", responseObjects);
	} onError:^(NSError *error) {
		DLog(@"Error: %@", [error localizedDescription]);
	}];	
}

@end
