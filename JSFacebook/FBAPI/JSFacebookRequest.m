//
//  JSGraphRequest.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/28/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSFacebookRequest.h"

@interface JSFacebookRequest ()

@property (nonatomic, strong) NSMutableDictionary *internalParameters;
@property (nonatomic, strong, readwrite) NSDictionary *parameters;

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
	return [self.internalParameters copy];
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
		graphPath_ = graphPath;
		httpMethod_ = @"GET";
		omitResponseOnSuccess_ = YES;
		_authenticate = YES;
	}
	return self;
}

- (id)init {
	return [self initWithGraphPath:nil];
}

#pragma mark - Class methods

+ (id)requestWithGraphPath:(NSString *)graphPath {
	return [[JSFacebookRequest alloc] initWithGraphPath:graphPath];
}

@end
