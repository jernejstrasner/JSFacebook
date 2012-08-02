//
//  FacebookAPIAppDelegate.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "FacebookAPIAppDelegate.h"

#import "JSFacebook.h"

//#warning If you are using SSO auth, don't forget to register the URL scheme for the app. Details in the comment below.
/**
 If you're using SSO authentication, your app has to register a URL scheme for the callback URL.
 The URL scheme has to be your Facebook app ID prefixed with 'fb'. Eg. fb000000000000000
 */

@implementation FacebookAPIAppDelegate

@synthesize window=_window;
@synthesize navigationController=_navigationController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	// Add the navigation controller's view to the window and display.
	self.window.rootViewController = self.navigationController;
	[self.window makeKeyAndVisible];
    
    // Before you try to athenticate you must set the Facebook app ID
//    #error Enter your Facebook app ID here
    [[JSFacebook sharedInstance] setFacebookAppID:@""];
	[[JSFacebook sharedInstance] setFacebookAppSecret:@""];
	
	// Permissions reference: http://developers.facebook.com/docs/authentication/permissions/
	// Enter the permissions you want in this array
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

	[[JSFacebook sharedInstance] loginWithPermissions:permissions onSuccess:^(void) {
		DLog(@"Sucessfully logged in!");
		// Successfully logged in
		[[NSNotificationCenter defaultCenter] postNotificationName:kFacebookDidLoginNotification object:nil];
	} onError:^(NSError *error) {
		DLog(@"Error while logging in: %@", [error localizedDescription]);
		// There was an error
		[[NSNotificationCenter defaultCenter] postNotificationName:kFacebookDidNotLoginNotification object:nil];
	}];
	
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    DLog(@"Open URL: %@", url);
    [[JSFacebook sharedInstance] handleCallbackURL:url];
    return YES;
}

- (void)dealloc
{
	[_window release];
	[_navigationController release];
    [super dealloc];
}

@end
