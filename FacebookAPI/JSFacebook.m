//
//  JSFacebook.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JSFacebook.h"

#import <libkern/OSAtomic.h>

@implementation JSFacebook

#pragma mark - Singleton

static void * volatile sharedInstance = nil;

+ (JSFacebook *)sharedInstance {
	while (!sharedInstance) {
		JSFacebook *temp = [[self alloc] init];
		if(!OSAtomicCompareAndSwapPtrBarrier(0x0, temp, &sharedInstance)) {
			[temp release];
		}
	}
	return sharedInstance;
}

#pragma mark - Properties

@synthesize facebook=facebook_;

#pragma mark - Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		facebook_ = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID];
	}
	return self;
}

- (void)dealloc {
	[facebook_ release];
	[super dealloc];
}

#pragma mark - Methods
#pragma mark - Authentication

- (void)login {
	// Permissions
	NSArray *permissions = [NSArray arrayWithObjects:
							  @"read_stream",
							  @"read_mailbox",
							  @"read_friendlists",
							  @"user_about_me",
							  @"user_activities",
							  @"user_birthday",
							  @"user_education_history",
							  @"user_events",
							  @"user_groups",
							  @"user_hometown",
							  @"user_interests",
							  @"user_likes",
							  @"user_location",
							  @"user_notes",
							  @"user_online_presence",
							  @"user_photo_video_tags",
							  @"user_photos",
							  @"user_relationships",
							  @"user_relationship_details",
							  @"user_religion_politics",
							  @"user_status",
							  @"user_videos",
							  @"user_website",
							  @"user_website",
							  @"user_work_history",
							  @"email",
							  @"friends_about_me",
							  @"friends_activities",
							  @"friends_birthday",
							  @"friends_education_history",
							  @"friends_events",
							  @"friends_groups",
							  @"friends_hometown",
							  @"friends_interests",
							  @"friends_likes",
							  @"friends_location",
							  @"friends_notes",
							  @"friends_online_presence",
							  @"friends_photo_video_tags",
							  @"friends_photos",
							  @"friends_relationships",
							  @"friends_relationship_details",
							  @"friends_religion_politics",
							  @"friends_status",
							  @"friends_videos",
							  @"friends_website",
							  @"friends_website",
							  @"friends_work_history",
							  // Publishing
							  @"publish_stream",
							  @"create_event",
							  @"rsvp_event",
							  nil];
	// Authenticate
	[self.facebook authorize:permissions delegate:self];
}

- (void)logout {
	// Log out from Facebook
	[self.facebook logout:self];
}

#pragma mark - FBSessionDelegate

- (void)fbDidLogin {
	DLog(@"Logged in!");
}

- (void)fbDidLogout {
	DLog(@"Logged out!");
}

- (void)fbDidNotLogin:(BOOL)cancelled {
	DLog(@"Not logged in! Was cancelled? %@", cancelled ? @"YES" : @"NO");
}

@end
