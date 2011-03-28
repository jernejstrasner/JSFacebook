//
//  JSFacebook.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JSFacebook.h"

#import <libkern/OSAtomic.h>
#import "JSON.h"

@interface JSFacebook (Private)

- (NSString *)generateGETParameters:(NSDictionary *)params;
- (NSData *)generatePOSTBody:(NSDictionary *)params;

@end

// HTTP POST request generation parameters
static NSString *kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
static float kImageQuality = 0.8;

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
		// Init Facebook
		facebook_ = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID];
		// Init the network queue
		network_queue = dispatch_queue_create("com.jsfacebook.network", NULL);
	}
	return self;
}

- (void)dealloc {
	// Release facebook
	[facebook_ release];
	// Dispatch stuff
	dispatch_release(network_queue);
	// Blocks
	[loginSucceededBlock_ release];
	[loginFailedBlock_ release];
	[logoutSucceededBlock_ release];
	// Super
	[super dealloc];
}

#pragma mark - Methods
#pragma mark - Authentication

- (void)loginAndOnSuccess:(voidBlock)succBlock onError:(voidBlock)errBlock {
	[loginSucceededBlock_ release];
	loginSucceededBlock_ = [succBlock copy];
	[loginFailedBlock_ release];
	loginFailedBlock_ = [errBlock copy];
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

- (void)logoutAndOnSuccess:(voidBlock)succBlock {
	[logoutSucceededBlock_ release];
	logoutSucceededBlock_ = [succBlock copy];
	// Log out from Facebook
	[self.facebook logout:self];
}

#pragma mark - Graph API requests

- (void)requestWithGraphPath:(NSString *)graphPath
				   andParams:(NSDictionary *)params
			   andHttpMethod:(NSString *)httpMethod
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock
{
	if (httpMethod == nil) {
		httpMethod = @"GET";
	}
	
	// Additional parameters
	NSMutableDictionary *params_ = [NSMutableDictionary dictionaryWithDictionary:params];
	[params_ setValue:@"json" forKey:@"format"];
	
	// Request
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:httpMethod];
	
	// URL
	NSMutableString *url = [NSMutableString stringWithString:@"https://graph.facebook.com/"];
	// Remove the slash from the graph path beginning
	NSString *gPath = graphPath;
	while ([gPath hasPrefix:@"/"]) {
		gPath = [gPath substringFromIndex:1];
	}
	[url appendString:gPath];

	// Check how to append, with an ? or &
	char glue;
	if ([gPath rangeOfString:@"?"].location != NSNotFound) glue = '&';
	else glue = '?';
	
	// Different parameters encoding for differet methods
	if ([httpMethod isEqualToString:@"POST"]) {
		// Generate a POST body from the parameters (supports images)
		[request setHTTPBody:[self generatePOSTBody:params_]];
		// Add the access token
		if ([self.facebook isSessionValid]) {
			[url appendFormat:@"%caccess_token=%@", glue, self.facebook.accessToken];
		}
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
	} else {
		// Add the access token
		if ([self.facebook isSessionValid]) {
			[params_ setValue:self.facebook.accessToken forKey:@"access_token"];
		}
		// Generate the GET URL encoded parameters
		NSString *getParameters = [self generateGETParameters:params_];
		// Add to the URL
		[url appendFormat:@"%c%@", glue, getParameters];
	}	
	
	// Set the URL
	[request setURL:[NSURL URLWithString:url]];
	
	// Misc. properties
	[request setTimeoutInterval:20.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	
	dispatch_async(network_queue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// Queue the request
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		NSData *httpData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		// Parse the data into a string (if valid)
		if (error == nil && httpData != nil) {
			NSString *responseString = [[[NSString alloc] initWithData:httpData encoding:NSUTF8StringEncoding] autorelease];
			// It's JSON so parse it
			id jsonObject = [responseString JSONValue];
			// Check for errors
			if ([jsonObject isKindOfClass:[NSDictionary class]] &&
				[jsonObject valueForKey:@"error"] != nil)
			{
				error = [NSError errorWithDomain:[jsonObject valueForKeyPath:@"error.type"] code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[jsonObject valueForKeyPath:@"error.message"], NSLocalizedDescriptionKey, nil]];
				errBlock(error);
			} else {
				// Execute the block
				succBlock(jsonObject);
			}
		} else {
			// We have an error to handle
			errBlock(error);
		}
		[pool drain];
	});
	
	[request release];
}

- (void)requestWithGraphPath:(NSString *)graphPath
				   andParams:(NSDictionary *)params
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock
{
	[self requestWithGraphPath:graphPath andParams:params andHttpMethod:nil onSuccess:succBlock onError:errBlock];
}

- (void)requestWithGraphPath:(NSString *)graphPath
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock
{
	[self requestWithGraphPath:graphPath andParams:nil andHttpMethod:nil onSuccess:succBlock onError:errBlock];
}

#pragma mark - Utility methods

- (NSString *)generateGETParameters:(NSDictionary *)params {
	NSMutableArray *pairs = [NSMutableArray new];
	for (NSString *key in params) {
		// Get the object
		id obj = [params valueForKey:key];
		// Encode arrays and dictionaries in JSON
		if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
			obj = [obj JSONFragment];
		}
		// Escaping
		NSString *escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, /* allocator */
																					  (CFStringRef)obj,
																					  NULL, /* charactersToLeaveUnescaped */
																					  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																					  kCFStringEncodingUTF8);
		// Generate http request parameter pairs
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
		[escaped_value release];
	}
	
	NSString *parameters = [pairs componentsJoinedByString:@"&"];
	[pairs release];
	
	return parameters;
}

- (NSData *)generatePOSTBody:(NSDictionary *)params {
	[params retain];
	
	NSMutableData *body = [NSMutableData data];
	NSString *beginLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", kStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	for (id key in params) {
		id value = [params valueForKey:key];
		if ([value isKindOfClass:[UIImage class]]) {
			UIImage *image = [params objectForKey:key];
			NSData *data = UIImageJPEGRepresentation(image, kImageQuality);
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithFormat:@"Content-Disposition: multipart/form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithFormat:@"Content-Length: %d\r\n", [data length]] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:data];
		} else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray array]]) {
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];        
			[body appendData:[[NSString stringWithFormat:@"Content-Disposition: multipart/form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[value JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
		} else {
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];        
			[body appendData:[[NSString stringWithFormat:@"Content-Disposition: multipart/form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	[params release];
	params = nil;
	
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return body;
}

#pragma mark - FBSessionDelegate

- (void)fbDidLogin {
	DLog(@"Logged in!");
	loginSucceededBlock_();
}

- (void)fbDidLogout {
	DLog(@"Logged out!");
	logoutSucceededBlock_();
}

- (void)fbDidNotLogin:(BOOL)cancelled {
	DLog(@"Not logged in! Was cancelled? %@", cancelled ? @"YES" : @"NO");
	loginFailedBlock_();
}

@end
