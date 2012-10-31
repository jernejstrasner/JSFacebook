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

- (NSMutableDictionary *)internalParameters
{
	if (_internalParameters == nil) {
		_internalParameters = [[NSMutableDictionary alloc] init];
	}
	return _internalParameters;
}

- (NSDictionary *)parameters
{
	return [self.internalParameters copy];
}

- (void)addParameter:(NSString *)key withValue:(id)value
{
	[self.internalParameters setValue:value forKey:key];
}

- (void)removeParameter:(NSString *)key
{
	[self.internalParameters removeObjectForKey:key];
}

#pragma mark - Lifecycle

- (id)initWithGraphPath:(NSString *)graphPath
{
	self = [super init];
	if (self) {
		_graphPath = graphPath;
		_httpMethod = @"GET";
		_omitResponseOnSuccess = YES;
		_authenticate = YES;
	}
	return self;
}

- (id)initWithOpenGraphNamespace:(NSString *)space andAction:(NSString *)action
{
	self = [super init];
	if (self) {
		_graphPath = [NSString stringWithFormat:@"/me/%@:%@", space, action];
		_httpMethod = @"POST";
		_omitResponseOnSuccess = YES;
		_authenticate = YES;
	}
	return self;
}

- (id)initForOpenGraphAction:(JSFacebookOGAction)action
{
	self = [super init];
	if (self) {
		NSMutableString *graphPath = [NSMutableString stringWithString:@"/me/"];
		switch (action) {
			case JSFacebookOGLike:
			default:
				[graphPath appendString:@"og.likes"];
				break;
		}
		_graphPath = [graphPath copy];
		_httpMethod = @"POST";
		_omitResponseOnSuccess = YES;
		_authenticate = YES;
	}
	return self;
}

- (id)init
{
	return [self initWithGraphPath:nil];
}

#pragma mark - Class methods

+ (id)requestWithGraphPath:(NSString *)graphPath
{
	return [[JSFacebookRequest alloc] initWithGraphPath:graphPath];
}

+ (id)requestWithOpenGraphNamespace:(NSString *)space andAction:(NSString *)action
{
	return [[JSFacebookRequest alloc] initWithOpenGraphNamespace:space andAction:action];
}

+ (id)requestForOpenGraphAction:(JSFacebookOGAction)action
{
	return [[JSFacebookRequest alloc] initForOpenGraphAction:action];
}

@end
