//
//  FacebookAPIAppDelegate.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "FacebookAPIAppDelegate.h"

#import "JSFacebook.h"

@implementation FacebookAPIAppDelegate

@synthesize window=_window;
@synthesize navigationController=_navigationController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	// Add the navigation controller's view to the window and display.
	self.window.rootViewController = self.navigationController;
	[self.window makeKeyAndVisible];
	
	// Permissions
	// Reference: http://developers.facebook.com/docs/authentication/permissions/
	
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
		// Hide the window
		[self.window.rootViewController dismissModalViewControllerAnimated:YES];
	} onError:^(NSError *error) {
		DLog(@"Error while logging in: %@", [error localizedDescription]);
		// There was an error
		[[NSNotificationCenter defaultCenter] postNotificationName:kFacebookDidNotLoginNotification object:nil];
		// Hide the window
		[self.window.rootViewController dismissModalViewControllerAnimated:YES];
	}];
	
    return YES;
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
////	return [[[JSFacebook sharedInstance] facebook] handleOpenURL:url];
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

- (void)dealloc
{
	[_window release];
	[_navigationController release];
    [super dealloc];
}

@end
