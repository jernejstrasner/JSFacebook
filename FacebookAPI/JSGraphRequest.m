//
//  JSGraphRequest.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JSGraphRequest.h"


@implementation JSGraphRequest

#pragma mark - Properties

@synthesize graphPath=graphPath_;
@synthesize httpMethod=httpMethod_;
@synthesize parameters=params_;

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

- (id)init {
	self = [super init];
	if (self) {
		httpMethod_ = [[NSString alloc] initWithString:@"GET"];
	}
	return self;
}

- (id)initWithGraphPath:(NSString *)graphPath {
	self = [super init];
	if (self) {
		graphPath_ = [graphPath retain];
		httpMethod_ = [[NSString alloc] initWithString:@"GET"];
	}
	return self;
}

- (void)dealloc {
	[graphPath_ release];
	[httpMethod_ release];
	[params_ release];
	[super dealloc];
}

#pragma mark - Class methods

+ (id)requestWithGraphPath:(NSString *)graphPath {
	return [[[JSGraphRequest alloc] initWithGraphPath:graphPath] autorelease];
}

@end
