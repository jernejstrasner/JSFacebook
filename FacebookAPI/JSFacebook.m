//
//  JSFacebook.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebook.h"

#import <libkern/OSAtomic.h>
#import "JSONKit.h"

// Constants
NSString * const kJSFacebookAppID = @"150562561623295"; // Change to your facebook app ID
float const kJSFacebookImageQuality = 0.8; // JPEG compression ration when uploading images

NSString * const kJSFacebookStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
NSString * const kJSFacebookGraphAPIEndpoint = @"https://graph.facebook.com/";

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
		facebook_ = [[Facebook alloc] initWithAppId:kJSFacebookAppID];
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

- (void)loginWithPermissions:(NSArray *)permissions
				   onSuccess:(voidBlock)succBlock
					 onError:(voidBlock)errBlock
{
	[loginSucceededBlock_ release];
	loginSucceededBlock_ = [succBlock copy];
	[loginFailedBlock_ release];
	loginFailedBlock_ = [errBlock copy];
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

- (void)fetchRequest:(JSFacebookRequest *)graphRequest
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
	NSMutableString *url = [NSMutableString stringWithString:kJSFacebookGraphAPIEndpoint];
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
		[request setHTTPBody:[params_ generatePOSTBody]];
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kJSFacebookStringBoundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
	} else {
		// Generate the GET URL encoded parameters
		NSString *getParameters = [params_ generateGETParameters];
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
			id jsonObject = [responseString objectFromJSONString];
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
	JSFacebookRequest *graphRequest = [[[JSFacebookRequest alloc] initWithGraphPath:graphPath] autorelease];
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

	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kJSFacebookStringBoundary];
	[request setValue:contentType forHTTPHeaderField:@"Content-Type"];

	NSMutableArray *batchData = [[NSMutableArray alloc] init];
	// Iterate trough the separate batch requests
	for (JSFacebookRequest *graphRequest in graphRequests) {
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
			[batchParams setValue:[graphRequest.parameters generatePOSTBody] forKey:@"body"];
		} else {
			// Check how to append, with an ? or &
			char glue;
			if ([gPath rangeOfString:@"?"].location != NSNotFound) glue = '&';
			else glue = '?';
			if ([graphRequest.parameters count] > 0) {
				// Generate the GET URL encoded parameters
				NSString *getParameters = [graphRequest.parameters generateGETParameters];
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
	[request setHTTPBody:[params_ generatePOSTBody]];
	
	// Set the URL
	[request setURL:[NSURL URLWithString:kJSFacebookGraphAPIEndpoint]];
	
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
			NSArray *jsonObject = [responseString objectFromJSONString];
			// Parse the different batch requests
			NSMutableArray *batchResponses = [NSMutableArray array];
			for (id responseObject in jsonObject) {
				if (![responseObject isKindOfClass:[NSDictionary class]]) {
					[batchResponses addObject:[NSNull null]];
					continue;
				}
				// Check for errors
				int response_code = [[responseObject valueForKey:@"code"] intValue];
				NSDictionary *data = [[responseObject valueForKey:@"body"] objectFromJSONString];
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

#pragma mark - FBSessionDelegate

- (void)fbDidLogin {
	loginSucceededBlock_();
}

- (void)fbDidLogout {
	logoutSucceededBlock_();
}

- (void)fbDidNotLogin:(BOOL)cancelled {
	loginFailedBlock_();
}

@end
