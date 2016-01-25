//
//  MSHHTTPRequestOperation.m
//  MoonShine
//
//  Created by Robert Widmann on 1/24/16.
//  Copyright © 2016 CodaFi. All rights reserved.
//

#import "MSHHTTPRequestOperation.h"

@interface MSHHTTPRequestOperation ()
@property (nonatomic, strong) NSURLRequest *request;
@property (nonnull, strong) NSOutputStream *outputStream;
@end

@implementation MSHHTTPRequestOperation

- (instancetype)initWithRequest:(NSURLRequest *)request toOutputStream:(NSOutputStream *)stream {
	self = [super init];
	
	self.request = request;
	self.outputStream = stream;
	
	return self;
}



@end
