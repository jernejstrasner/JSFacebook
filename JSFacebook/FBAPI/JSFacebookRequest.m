//
//  JSGraphRequest.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/28/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebookRequest.h"


@implementation JSFacebookRequest {
	NSMutableDictionary *params_;
}

#pragma mark - Properties

@synthesize graphPath=graphPath_;
@synthesize httpMethod=httpMethod_;

@synthesize parameters=_parameters;

- (NSDictionary *)parameters
{
	return [NSDictionary dictionaryWithDictionary:params_];
}

@synthesize name=name_;
@synthesize omitResponseOnSuccess=omitResponseOnSuccess_;
@synthesize authenticate=_authenticate;

- (void)addParameter:(NSString *)key withValue:(id)value {
	// Create the parameters dictionary if it doesn't exist
	if (!params_) params_ = [[NSMutableDictionary alloc] init];
	// Add the parameter
	[params_ setValue:value forKey:key];
}

- (void)removeParameter:(NSString *)key {
	// Remove the desired parameter
	[params_ removeObjectForKey:key];
}

#pragma mark - Lifecycle

- (id)initWithGraphPath:(NSString *)graphPath {
	self = [super init];
	if (self) {
		graphPath_ = [graphPath retain];
		httpMethod_ = [[NSString alloc] initWithString:@"GET"];
		omitResponseOnSuccess_ = YES;
		params_ = [[NSMutableDictionary alloc] init];
		_authenticate = YES;
	}
	return self;
}

- (id)init {
	return [self initWithGraphPath:nil];
}

- (void)dealloc {
	[graphPath_ release];
	[httpMethod_ release];
	[params_ release];
	[_parameters release];
	[name_ release];
	[super dealloc];
}

#pragma mark - Class methods

+ (id)requestWithGraphPath:(NSString *)graphPath {
	return [[[JSFacebookRequest alloc] initWithGraphPath:graphPath] autorelease];
}

@end
