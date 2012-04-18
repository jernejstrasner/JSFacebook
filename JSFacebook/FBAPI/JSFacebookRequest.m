//
//  JSGraphRequest.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/28/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebookRequest.h"

@interface JSFacebookRequest ()

@property (nonatomic, retain) NSMutableDictionary *internalParameters;

@end

@implementation JSFacebookRequest

#pragma mark - Properties

@synthesize graphPath=graphPath_;
@synthesize httpMethod=httpMethod_;
@synthesize internalParameters;

- (NSMutableDictionary *)internalParameters
{
	if (internalParameters == nil) {
		internalParameters = [[NSMutableDictionary alloc] init];
	}
	return internalParameters;
}

@synthesize parameters=_parameters;

- (NSDictionary *)parameters
{
	return [[self.internalParameters copy] autorelease];
}

@synthesize name=name_;
@synthesize omitResponseOnSuccess=omitResponseOnSuccess_;
@synthesize authenticate=_authenticate;

- (void)addParameter:(NSString *)key withValue:(id)value
{
	[self.internalParameters setValue:value forKey:key];
}

- (void)removeParameter:(NSString *)key
{
	[self.internalParameters removeObjectForKey:key];
}

#pragma mark - Lifecycle

- (id)initWithGraphPath:(NSString *)graphPath {
	self = [super init];
	if (self) {
		graphPath_ = [graphPath retain];
		httpMethod_ = [[NSString alloc] initWithString:@"GET"];
		omitResponseOnSuccess_ = YES;
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
	[internalParameters release];
	[_parameters release];
	[name_ release];
	[super dealloc];
}

#pragma mark - Class methods

+ (id)requestWithGraphPath:(NSString *)graphPath {
	return [[[JSFacebookRequest alloc] initWithGraphPath:graphPath] autorelease];
}

@end
