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
#warning Enter your Facebook app ID below
NSString * const kJSFacebookAppID = @"your_facebook_app_id"; // Change to your facebook app ID
float const kJSFacebookImageQuality = 0.8; // JPEG compression ration when uploading images

NSString * const kJSFacebookStringBoundary				= @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
NSString * const kJSFacebookGraphAPIEndpoint			= @"https://graph.facebook.com/";
NSString * const kJSFacebookAccessTokenKey				= @"JSFacebookAccessToken";
NSString * const kJSFacebookAccessTokenExpiryDateKey	= @"JSFacebookAccessTokenExpiryDate";

@implementation JSFacebook

#pragma mark - Singleton

/*
 * Singleton pattern by Louis Gerbarg
 * http://stackoverflow.com/questions/145154/what-does-your-objective-c-singleton-look-like/2449664#2449664
 */

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

@synthesize accessToken=_accessToken;
@synthesize accessTokenExpiryDate=_accessTokenExpiryDate;

- (void)setAccessToken:(NSString *)accessToken {
	[_accessToken release];
	_accessToken = [accessToken retain];
	
	[[NSUserDefaults standardUserDefaults] setValue:accessToken forKey:kJSFacebookAccessTokenKey];
}

- (void)setAccessTokenExpiryDate:(NSDate *)accessTokenExpiryDate {
	[_accessTokenExpiryDate release];
	_accessTokenExpiryDate = [accessTokenExpiryDate retain];
	
	[[NSUserDefaults standardUserDefaults] setValue:accessTokenExpiryDate forKey:kJSFacebookAccessTokenExpiryDateKey];
}

#pragma mark - Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		// Init the network queue
		network_queue = dispatch_queue_create("com.jsfacebook.network", NULL);
		// Check if we have an access token saved and it is stil valid
		NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:kJSFacebookAccessTokenKey];
		if ([accessToken length] > 0) {
			NSDate *accessTokenExpiryDate = [[NSUserDefaults standardUserDefaults] valueForKey:kJSFacebookAccessTokenExpiryDateKey];
			if ([accessTokenExpiryDate timeIntervalSinceNow] > 0) {
				// Save to properties
				self.accessToken = accessToken;
				self.accessTokenExpiryDate = accessTokenExpiryDate;
			}
		}
	}
	return self;
}

- (void)dealloc {
	// Properties
	[_accessToken release];
	[_accessTokenExpiryDate release];
	// Dispatch stuff
	dispatch_release(network_queue);
	// Super
	[super dealloc];
}

#pragma mark - Methods
#pragma mark - Authentication

- (void)loginWithPermissions:(NSArray *)permissions
				   onSuccess:(JSFBLoginSuccessBlock)succBlock
					 onError:(JSFBLoginErrorBlock)errBlock
{
	if (![self isSessionValid]) {
		// Open a modal window on the main app view controller
		UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
		JSFacebookLoginController *loginController = [JSFacebookLoginController loginControllerWithPermissions:permissions onSuccess:succBlock onError:errBlock];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			loginController.modalPresentationStyle = UIModalPresentationFormSheet;
			loginController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
		[rootViewController presentModalViewController:loginController animated:YES];
	} else {
		succBlock();
	}
}

- (void)logout {
	// Nil out the properties
	self.accessToken = nil;
	self.accessTokenExpiryDate = nil;
	// Remove any saved login data
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kJSFacebookAccessTokenKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kJSFacebookAccessTokenExpiryDateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isSessionValid {
	if ([self.accessToken length] > 0 && [self.accessTokenExpiryDate timeIntervalSinceNow] > 0) {
		return YES;
	}
	return NO;
}

#pragma mark - Graph API requests

- (void)fetchRequest:(JSFacebookRequest *)graphRequest
		   onSuccess:(JSFBSuccessBlock)succBlock
			 onError:(JSFBErrorBlock)errBlock
{
	// Additional parameters
	NSMutableDictionary *params_ = [NSMutableDictionary dictionaryWithDictionary:graphRequest.parameters];
	[params_ setValue:@"json" forKey:@"format"];

	// Add the access token
	if ([self isSessionValid]) {
		[params_ setValue:self.accessToken forKey:@"access_token"];
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
		[request setHTTPBody:[params_ generatePOSTBodyWithBoundary:kJSFacebookStringBoundary]];
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
				   onSuccess:(JSFBSuccessBlock)succBlock
					 onError:(JSFBErrorBlock)errBlock
{
	JSFacebookRequest *graphRequest = [[[JSFacebookRequest alloc] initWithGraphPath:graphPath] autorelease];
	[self fetchRequest:graphRequest onSuccess:succBlock onError:errBlock];
}

#pragma mark - Graph API batch requests

- (void)fetchRequests:(NSArray *)graphRequests
			onSuccess:(JSFBBatchSuccessBlock)succBlock
			  onError:(JSFBErrorBlock)errBlock
{
	// Additional parameters
	NSMutableDictionary *params_ = [NSMutableDictionary dictionary];
	[params_ setValue:@"json" forKey:@"format"];
	
	// Add the access token
	if ([self isSessionValid]) {
		[params_ setValue:self.accessToken forKey:@"access_token"];
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
			[batchParams setValue:[graphRequest.parameters generatePOSTBodyWithBoundary:kJSFacebookStringBoundary] forKey:@"body"];
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
	[request setHTTPBody:[params_ generatePOSTBodyWithBoundary:kJSFacebookStringBoundary]];
	
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

@end
