//
//  JSFacebook.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebook.h"
#import "JSONKit.h"


// Constants
NSString * const kJSFacebookStringBoundary				= @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
NSString * const kJSFacebookGraphAPIEndpoint			= @"https://graph.facebook.com/";
NSString * const kJSFacebookAccessTokenKey				= @"JSFacebookAccessToken";
NSString * const kJSFacebookAccessTokenExpiryDateKey	= @"JSFacebookAccessTokenExpiryDate";
NSString * const kJSFacebookSSOAuthURL                  = @"fbauth://authorize/";
NSString * const kJSFacebookErrorDomain					= @"com.jsfacebook.error";

@interface JSFacebook () {
	dispatch_queue_t network_queue;
}

@property (nonatomic, copy) JSFBLoginSuccessBlock authSuccessBlock;
@property (nonatomic, copy) JSFBLoginErrorBlock authErrorBlock;

@end

@implementation JSFacebook

#pragma mark - Singleton

+ (JSFacebook *)sharedInstance
{
    static JSFacebook *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[JSFacebook alloc] init];
    });
	return sharedInstance;
}

#pragma mark - Properties

@synthesize accessToken=_accessToken;
@synthesize accessTokenExpiryDate=_accessTokenExpiryDate;
@synthesize facebookAppID=_facebookAppID;
@synthesize facebookAppSecret=_facebookAppSecret;

- (void)setAccessToken:(NSString *)accessToken {
	[_accessToken release];
	_accessToken = [accessToken retain];
	
	[[NSUserDefaults standardUserDefaults] setValue:accessToken forKey:kJSFacebookAccessTokenKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAccessTokenExpiryDate:(NSDate *)accessTokenExpiryDate {
	[_accessTokenExpiryDate release];
	_accessTokenExpiryDate = [accessTokenExpiryDate retain];
	
	[[NSUserDefaults standardUserDefaults] setValue:accessTokenExpiryDate forKey:kJSFacebookAccessTokenExpiryDateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@synthesize authErrorBlock;
@synthesize authSuccessBlock;
@synthesize imageQuality = _imageQuality;
@synthesize useSSO = _useSSO;

#pragma mark - Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		// Default properties
		_useSSO = YES;
		_imageQuality = 0.8f;
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
    [_facebookAppID release];
	[_facebookAppSecret release];
	// Dispatch stuff
	dispatch_release(network_queue);
    // Blocks
    [authSuccessBlock release];
    [authErrorBlock release];
	// Super
	[super dealloc];
}

#pragma mark - Methods
#pragma mark - Authentication

- (void)loginWithPermissions:(NSArray *)permissions
				   onSuccess:(JSFBLoginSuccessBlock)succBlock
					 onError:(JSFBLoginErrorBlock)errBlock
{
    if (![self isFacebookAppIDValid]) {
        NSLog(@"ERROR: You have to set a valid Facebook app ID before you try to authenticate!");
        return;
    }
	if (![self isSessionValid]) {
        // Check for SSO support
        if (self.useSSO && [UIDevice instanceMethodForSelector:@selector(isMultitaskingSupported)] && [[UIDevice currentDevice] isMultitaskingSupported]) {
            // Save the blocks
            self.authSuccessBlock = succBlock;
            self.authErrorBlock = errBlock;
            // Build the parameter string
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params setValue:self.facebookAppID forKey:@"client_id"];
            [params setValue:@"user_agent" forKey:@"type"];
            [params setValue:@"touch" forKey:@"display"];
            [params setValue:@"ios" forKey:@"sdk"];
            [params setValue:@"fbconnect://success" forKey:@"redirect_uri"];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@&scope=%@", kJSFacebookSSOAuthURL, [params generateGETParameters], [permissions componentsJoinedByString:@","]]];
            // Open the SSO URL
            BOOL didOpenApp = [[UIApplication sharedApplication] openURL:url];
            // If it failed open Safari
            if (didOpenApp == NO) {
                [params setValue:[NSString stringWithFormat:@"fb%@://authorize", self.facebookAppID] forKey:@"redirect_uri"];
                url = [NSURL URLWithString:[NSString stringWithFormat:@"https://m.facebook.com/dialog/oauth?%@&scope=%@", [params generateGETParameters], [permissions componentsJoinedByString:@","]]];
                [[UIApplication sharedApplication] openURL:url];
            }
        } else {
            // Open a modal window on the main app view controller
            UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            JSFacebookLoginController *loginController = [JSFacebookLoginController loginControllerWithPermissions:permissions onSuccess:succBlock onError:errBlock];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                loginController.modalPresentationStyle = UIModalPresentationFormSheet;
                loginController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            }
            [rootViewController presentModalViewController:loginController animated:YES];
        }
	} else {
		succBlock();
	}
}

- (void)logout
{
	// Nil out the properties
	self.accessToken = nil;
	self.accessTokenExpiryDate = nil;
	// Remove any saved login data
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kJSFacebookAccessTokenKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kJSFacebookAccessTokenExpiryDateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isSessionValid
{
	if ([self.accessToken length] > 0 && [self.accessTokenExpiryDate timeIntervalSinceNow] > 0) {
		return YES;
	}
	return NO;
}

- (void)validateAccessTokenWithCompletionHandler:(void (^)(BOOL))completionHandler
{
	// First check if we have the token and that it is not expired
	if (![self isSessionValid]) {
		completionHandler(NO);
		return;
	}
	// Create a request to the Facebook servers to see if we have access with the token that we have
	JSFacebookRequest *request = [JSFacebookRequest requestWithGraphPath:@"/me"];
	[request addParameter:@"fields" withValue:@"id"];
	[[JSFacebook sharedInstance] fetchRequest:request onSuccess:^(id responseObject) {
		// Access token is valid
		completionHandler(YES);
	} onError:^(NSError *error) {
		// Not valid
		NSLog(@"Error: %@", [error localizedDescription]);
		completionHandler(NO);
	}];
}

- (void)extendAccessTokenExpirationWithCompletionHandler:(void (^)(NSError *))completionHandler
{
	if (![self isSessionValid]) {
		ALog(@"ERROR: Session invalid");
		NSError *error = [NSError errorWithDomain:kJSFacebookErrorDomain code:JSFacebookErrorCodeAuthentication userInfo:nil];
		if (completionHandler) completionHandler(error);
		return;
	}
	
	// We need the app secret for this
	if (![self.facebookAppSecret length]) {
		ALog(@"ERROR: Missing facebook app secret");
		NSError *error = [NSError errorWithDomain:kJSFacebookErrorDomain code:JSFacebookErrorCodeOther userInfo:nil];
		if (completionHandler) completionHandler(error);
		return;
	}
	
	JSFacebookRequest *request = [JSFacebookRequest requestWithGraphPath:@"/oauth/access_token"];
	[request setAuthenticate:NO];
	[request addParameter:@"fb_exchange_token" withValue:self.accessToken];
	[request addParameter:@"grant_type" withValue:@"fb_exchange_token"];
	[request addParameter:@"client_id" withValue:self.facebookAppID];
	[request addParameter:@"client_secret" withValue:self.facebookAppSecret];
	[[JSFacebook sharedInstance] fetchRequest:request onSuccess:^(id responseObject) {
		// Get the data (it is URL encoded)
		NSString *accessToken = [responseObject getQueryValueWithKey:@"access_token"];
		NSString *expiry = [responseObject getQueryValueWithKey:@"expires"];
		if (!accessToken.length || !expiry.length) {
			DLog(@"ERROR: Access token or expiry date missing!");
			NSError *error = [NSError errorWithDomain:kJSFacebookErrorDomain code:JSFacebookErrorCodeServer userInfo:[NSDictionary dictionaryWithObject:@"Crucial data is missing from the response" forKey:NSLocalizedDescriptionKey]];
			if (completionHandler) completionHandler(error);
		}
		
		// Set the new info
		self.accessToken = accessToken;
		self.accessTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:[expiry doubleValue]];
		
		if (completionHandler) completionHandler(nil);
		
	} onError:^(NSError *error) {
		DLog(@"ERROR: Could not extend the access token!");
		if (completionHandler) completionHandler(error);
	}];
}

- (BOOL)isFacebookAppIDValid
{
    // Check if the Facebook app ID is valid
    return (self.facebookAppID.length == 15);
}

- (void)handleCallbackURL:(NSURL *)url
{
    NSString *urlString = [url absoluteString];
    NSString *queryString = nil;
    @try {
        queryString = [urlString substringFromIndex:[urlString rangeOfString:@"#"].location + 1];
    }
    @catch (NSException *exception) {
        ALog(@"Could not parse the query string: %@", [exception reason]);
        self.authErrorBlock([NSError errorWithDomain:@"com.jernejstrasner.jsfacebook" code:100 userInfo:[NSDictionary dictionaryWithObject:[exception reason] forKey:NSLocalizedDescriptionKey]]);
		return;
    }
    
    // Check for errors
    NSString *errorString = [queryString getQueryValueWithKey:@"error"];
    if (errorString != nil) {
        // We have an error
        NSString *errorDescription = [queryString getQueryValueWithKey:@"error_description"];
        NSError *error = [NSError errorWithDomain:errorString code:666 userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey]];
        // Error block
        self.authErrorBlock(error);
    } else {
        // Request successfull, parse the token
        NSString *token =	[[url absoluteString] getQueryValueWithKey:@"access_token"];
        NSString *expTime =	[[url absoluteString] getQueryValueWithKey:@"expires_in"];
        
        NSDate *expirationDate = nil;
        if (expTime != nil) {
            int expVal = [expTime intValue];
            if (expVal == 0) {
                expirationDate = [NSDate distantFuture];
            } else {
                expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
            }
        }
        
        if ([token length] > 0) {
            // We're done. We have the token.
            [[JSFacebook sharedInstance] setAccessToken:token];
            [[JSFacebook sharedInstance] setAccessTokenExpiryDate:expirationDate];
            // Call the success block
            self.authSuccessBlock();
        } else {
            // Oops. We have an error. No valid token found.
            NSError *error = [NSError errorWithDomain:@"invalid_token" code:666 userInfo:[NSDictionary dictionaryWithObject:@"Invalid token" forKey:NSLocalizedDescriptionKey]];
            self.authErrorBlock(error);
        }
    }
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
	if (graphRequest.authenticate && [self isSessionValid]) {
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
		@autoreleasepool {
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
				if (jsonObject == nil && responseString.length > 0) {
					// Something is in there but isn't JSON
					// Pass it directly
					dispatch_async(dispatch_get_main_queue(), ^(void) {
						succBlock(responseString);
					});
				}
				else if ([jsonObject isKindOfClass:[NSDictionary class]] && [jsonObject valueForKey:@"error"] != nil) {
					// If there is an error object in the response, something went wront at Facebook's servers
					error = [NSError errorWithDomain:[jsonObject valueForKeyPath:@"error.type"] code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[jsonObject valueForKeyPath:@"error.message"], NSLocalizedDescriptionKey, nil]];
					dispatch_async(dispatch_get_main_queue(), ^(void) {
						errBlock(error);
					});
				}
				else {
					// Execute the block
					dispatch_async(dispatch_get_main_queue(), ^(void) {
						succBlock(jsonObject);
					});
				}
			} else {
				// We have an error to handle
				dispatch_async(dispatch_get_main_queue(), ^(void) {
					errBlock(error);
				});
			}
		}
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
		@autoreleasepool {
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
				dispatch_async(dispatch_get_main_queue(), ^(void) {
					succBlock(batchResponses);
				});
			} else {
				// We have an error to handle
				dispatch_async(dispatch_get_main_queue(), ^(void) {
					errBlock(error);
				});
			}
		}
	});
	
	[request release];
}

@end
