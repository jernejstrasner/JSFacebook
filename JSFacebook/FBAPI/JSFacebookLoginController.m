//
//  JSFacebookLoginController.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 4/2/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebookLoginController.h"

#import "JSFacebook.h"

@interface JSFacebookLoginController ()

@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, copy) JSFBLoginSuccessBlock successHandler;
@property (nonatomic, copy) JSFBLoginErrorBlock errorHandler;

@property (nonatomic, strong) NSArray *permissions;

- (void)close;
- (void)success;
- (void)error:(NSError *)error;
- (void)cancel;

@end

@implementation JSFacebookLoginController

#pragma mark - Properties

@synthesize navigationBar=_navigationBar;
@synthesize activityIndicator=_activityIndicator;
@synthesize webView=_webView;

@synthesize successHandler;
@synthesize errorHandler;

@synthesize permissions=_permissions;

#pragma mark - Class methods

+ (JSFacebookLoginController *)loginControllerWithPermissions:(NSArray *)permissions
													onSuccess:(JSFBLoginSuccessBlock)successBlock
													  onError:(JSFBLoginErrorBlock)errorBlock
{
	return [[self alloc] initWithPermissions:permissions successBlock:successBlock errorBlock:errorBlock];
}

#pragma mark - Lifecycle

- (id)initWithPermissions:(NSArray *)permissions
			 successBlock:(JSFBLoginSuccessBlock)successBlock
			   errorBlock:(JSFBLoginErrorBlock)errorBlock
{
	self = [super init];
	if (self) {
		_permissions = permissions;
		successHandler = [successBlock copy];
		errorHandler = [errorBlock copy];
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Facebook";
	
	// Add the UIWebView
	self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, -2, self.view.bounds.size.width, self.view.bounds.size.height+2)];
	self.webView.delegate = self;
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.webView];
    
    // Navigation bar
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 44.0f)];
    self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.navigationBar];
    
    // Navigation item
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@"Facebook"];
    [self.navigationBar pushNavigationItem:navigationItem animated:YES];
	
	// Add the activity indicator
	self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicator.hidesWhenStopped = YES;
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    // Close button
    navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	
	// Load the login page
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setValue:[[JSFacebook sharedInstance] facebookAppID] forKey:@"client_id"];
	[parameters setValue:@"fbconnect://success" forKey:@"redirect_uri"];
	[parameters setValue:@"touch" forKey:@"display"];
	[parameters setValue:@"token" forKey:@"response_type"];
	if ([_permissions count] > 0) {
		[parameters setValue:[_permissions componentsJoinedByString:@","] forKey:@"scope"];
	}
	NSString *urlString = [NSString stringWithFormat:@"https://www.facebook.com/dialog/oauth?%@", [parameters generateGETParameters]];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.webView = nil;
    self.activityIndicator = nil;
    self.navigationBar = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc
{
    _webView.delegate = nil;
    [_webView stopLoading];
}

#pragma mark - Methods

- (void)close
{
    if ([self respondsToSelector:@selector(presentingViewController)]) {
        [self.presentingViewController dismissModalViewControllerAnimated:YES];
    } else {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (void)success
{
    [self close];
    self.successHandler();
}

- (void)error:(NSError *)error
{
    [self close];
    self.errorHandler(error);
}

- (void)cancel
{
    [self close];
    self.errorHandler([NSError errorWithDomain:@"com.jernejstrasner.jsfacebook" code:1 userInfo:@{NSLocalizedDescriptionKey: @"The user cancelled the login action"}]);
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	
	if ([[url scheme] isEqualToString:@"fbconnect"]) {
		// Check for errors
		NSString *errorString = [[url absoluteString] getQueryValueWithKey:@"error"];
		if (errorString != nil) {
			// We have an error
			NSString *errorDescription = [[url absoluteString] getQueryValueWithKey:@"error_description"];
			NSError *error = [NSError errorWithDomain:errorString code:666 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
			// Error block
			[self error:error];
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
                [self success];
			} else {
				// Oops. We have an error. No valid token found.
				NSError *error = [NSError errorWithDomain:@"invalid_token" code:666 userInfo:@{NSLocalizedDescriptionKey: @"Invalid token"}];
                [self error:error];
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

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[self.activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self.activityIndicator stopAnimating];
    [self error:error];
}

@end
