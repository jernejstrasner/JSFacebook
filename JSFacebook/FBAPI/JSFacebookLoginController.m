//
//  JSFacebookLoginController.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 4/2/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebookLoginController.h"

#import "JSFacebook.h"

@implementation JSFacebookLoginController

#pragma mark - Class methods

+ (JSFacebookLoginController *)loginControllerWithPermissions:(NSArray *)permissions
													onSuccess:(JSFBLoginSuccessBlock)successBlock
													  onError:(JSFBLoginErrorBlock)errorBlock
{
	return [[[self alloc] initWithPermissions:permissions successBlock:successBlock errorBlock:errorBlock] autorelease];
}

#pragma mark - Properties

@synthesize webView=_webView;
@synthesize activityIndicator=_activityIndicator;

#pragma mark - Object lifecycle

- (id)initWithPermissions:(NSArray *)permissions
			 successBlock:(JSFBLoginSuccessBlock)successBlock
			   errorBlock:(JSFBLoginErrorBlock)errorBlock
{
	self = [super init];
	if (self) {
		_permissions = [permissions retain];
		_successBlock = [successBlock copy];
		_errorBlock = [errorBlock copy];
	}
	return self;
}

- (void)dealloc
{
	[_webView release];
	[_activityIndicator release];
	[_permissions release];
	// Blocks
	[_successBlock release];
	[_errorBlock release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Facebook Login";
	
	// Add the UIWebView
	_webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	_webView.delegate = self;
	_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_webView];
	
	// Add the activity indicator
	_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	_activityIndicator.center = _webView.center;
	_activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
	_activityIndicator.hidesWhenStopped = YES;
	[self.view addSubview:_activityIndicator];
	
	// Load the login page
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setValue:kJSFacebookAppID forKey:@"client_id"];
	[parameters setValue:@"fbconnect://success" forKey:@"redirect_uri"];
	[parameters setValue:@"touch" forKey:@"display"];
	[parameters setValue:@"token" forKey:@"response_type"];
	if ([_permissions count] > 0) {
		[parameters setValue:[_permissions componentsJoinedByString:@","] forKey:@"scope"];
	}
	NSString *urlString = [NSString stringWithFormat:@"https://www.facebook.com/dialog/oauth?%@", [parameters generateGETParameters]];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
	[self.activityIndicator startAnimating];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[_webView release], _webView = nil;
	[_activityIndicator release], _activityIndicator = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	
	if ([[url scheme] isEqualToString:@"fbconnect"]) {
		// Check for errors
		NSString *errorString = [[url absoluteString] getQueryValueWithKey:@"error"];
		if (errorString != nil) {
			// We have an error
			NSString *errorDescription = [[url absoluteString] getQueryValueWithKey:@"error_description"];
			NSError *error = [NSError errorWithDomain:errorString code:666 userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey]];
			// Error block
			_errorBlock(error);
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
				_successBlock();
			} else {
				// Oops. We have an error. No valid token found.
				NSError *error = [NSError errorWithDomain:@"invalid_token" code:666 userInfo:[NSDictionary dictionaryWithObject:@"Invalid token" forKey:NSLocalizedDescriptionKey]];
				_errorBlock(error);
			}
		}
		return NO;
	} else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		// Open the URL in Safari
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	} else {
		return YES;
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (self.activityIndicator) {
		[self.activityIndicator stopAnimating];
		[self.activityIndicator removeFromSuperview];
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if (self.activityIndicator) {
		[self.activityIndicator stopAnimating];
		[self.activityIndicator removeFromSuperview];
	}
	_errorBlock(error);
}

@end
