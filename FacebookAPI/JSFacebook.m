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
static NSString *kGraphAPIEndpoint = @"https://graph.facebook.com/";

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

- (void)fetchRequest:(JSGraphRequest *)graphRequest
		   onSuccess:(successBlock)succBlock
			 onError:(errorBlock)errBlock
{
	// Additional parameters
	NSMutableDictionary *params_ = [NSMutableDictionary dictionaryWithDictionary:graphRequest.parameters];
	[params_ setValue:@"json" forKey:@"format"];

	// Add the access token
	if ([self.facebook isSessionValid]) {
		[params_ setValue:self.facebook.accessToken forKey:@"access_token"];
	}
	
	// Request
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:graphRequest.httpMethod];
	
	// URL
	NSMutableString *url = [NSMutableString stringWithString:kGraphAPIEndpoint];
	// Remove the slash from the graph path beginning
	NSString *gPath = graphRequest.graphPath;
	while ([gPath hasPrefix:@"/"]) {
		gPath = [gPath substringFromIndex:1];
	}
	[url appendString:gPath];

	// Check how to append, with an ? or &
	char glue;
	if ([gPath rangeOfString:@"?"].location != NSNotFound) glue = '&';
	else glue = '?';
	
	// Different parameters encoding for differet methods
	if ([graphRequest.httpMethod isEqualToString:@"POST"]) {
		// Generate a POST body from the parameters (supports images)
		[request setHTTPBody:[self generatePOSTBody:params_]];
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
	} else {
		// Generate the GET URL encoded parameters
		NSString *getParameters = [self generateGETParameters:params_];
		// Add to the URL
		[url appendFormat:@"%c%@", glue, getParameters];
	}	
	
	// Set the URL
	[request setURL:[NSURL URLWithString:url]];
	
	// Misc. properties
	[request setTimeoutInterval:20.0];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	
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
				   onSuccess:(successBlock)succBlock
					 onError:(errorBlock)errBlock
{
	JSGraphRequest *graphRequest = [[[JSGraphRequest alloc] initWithGraphPath:graphPath] autorelease];
	[self fetchRequest:graphRequest onSuccess:succBlock onError:errBlock];
}

#pragma mark - Graph API batch requests

- (void)fetchRequests:(NSArray *)graphRequests
			onSuccess:(successBlockBatch)succBlock
			  onError:(errorBlock)errBlock
{
	// Additional parameters
	NSMutableDictionary *params_ = [NSMutableDictionary dictionary];
	[params_ setValue:@"json" forKey:@"format"];
	
	// Add the access token
	if ([self.facebook isSessionValid]) {
		[params_ setValue:self.facebook.accessToken forKey:@"access_token"];
	}
	
	// Request
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:@"POST"];

	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
	[request setValue:contentType forHTTPHeaderField:@"Content-Type"];

	NSMutableArray *batchData = [[NSMutableArray alloc] init];
	// Iterate trough the separate batch requests
	for (JSGraphRequest *graphRequest in graphRequests) {
		// Dictionary for single request parameters
		NSMutableDictionary *batchParams = [NSMutableDictionary dictionary];
		// Remove the slash from the graph path beginning
		NSString *gPath = graphRequest.graphPath;
		while ([gPath hasPrefix:@"/"]) {
			gPath = [gPath substringFromIndex:1];
		}
		
		// Add the method
		[batchParams setValue:graphRequest.httpMethod forKey:@"method"];
		
		// Add the request name
		if ([graphRequest.name length] > 0) {
			[batchParams setValue:graphRequest.name forKey:@"name"];
		}
		
		// Omit the result form the parent's response
		// (in the case of depedencies between batch calls)
		if (!graphRequest.omitResponseOnSuccess) {
			[batchParams setValue:[NSNumber numberWithBool:NO] forKey:@"omit_response_on_success"];
		}
		
		// Different parameters encoding for differet methods
		if ([graphRequest.httpMethod isEqualToString:@"POST"]) {
			// Add the url
			[batchParams setValue:gPath forKey:@"relative_url"];
			// Generate a POST body from the parameters (supports images)
			[batchParams setValue:[self generateGETParameters:graphRequest.parameters] forKey:@"body"];
		} else {
			// Check how to append, with an ? or &
			char glue;
			if ([gPath rangeOfString:@"?"].location != NSNotFound) glue = '&';
			else glue = '?';
			if ([graphRequest.parameters count] > 0) {
				// Generate the GET URL encoded parameters
				NSString *getParameters = [self generateGETParameters:graphRequest.parameters];
				// Add to the dictionary
				[batchParams setValue:[NSString stringWithFormat:@"%@%c%@", gPath, glue, getParameters] forKey:@"relative_url"];
			} else {
				[batchParams setValue:gPath forKey:@"relative_url"];
			}
		}
		[batchData addObject:batchParams];
	}
	
	// Add the batch requests to the main request
	[params_ setValue:batchData forKey:@"batch"];
	[batchData release];
	
	// Add the POST body
	[request setHTTPBody:[self generatePOSTBody:params_]];
	
	// Set the URL
	[request setURL:[NSURL URLWithString:kGraphAPIEndpoint]];
	
	// Misc. properties
	[request setTimeoutInterval:20.0];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	
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
			NSArray *jsonObject = [responseString JSONValue];
			// Parse the different batch requests
			NSMutableArray *batchResponses = [NSMutableArray array];
			for (id responseObject in jsonObject) {
				if (![responseObject isKindOfClass:[NSDictionary class]]) {
					[batchResponses addObject:[NSNull null]];
					continue;
				}
				// Check for errors
				int response_code = [[responseObject valueForKey:@"code"] intValue];
				NSDictionary *data = [[responseObject valueForKey:@"body"] JSONValue];
				if (response_code != 200) {
					// We have an error
					error = [NSError errorWithDomain:[data valueForKeyPath:@"error.type"] code:response_code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[data valueForKeyPath:@"error.message"], NSLocalizedDescriptionKey, nil]];
					[batchResponses addObject:error];
				} else {
					[batchResponses addObject:data];
				}
			}
			// Execute the block
			succBlock(batchResponses);
		} else {
			// We have an error to handle
			errBlock(error);
		}
		[pool drain];
	});
	
	[request release];
}

#pragma mark - Utility methods

- (NSString *)generateGETParameters:(NSDictionary *)params {
	NSMutableArray *pairs = [NSMutableArray new];
	for (NSString *key in params) {
		// Get the object
		id obj = [params valueForKey:key];
		// Encode arrays and dictionaries in JSON
		if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
			obj = [obj JSONRepresentation];
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
		} else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
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
