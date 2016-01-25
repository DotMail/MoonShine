//
//  MSHHTTPRequestOperation.h
//  MoonShine
//
//  Created by Robert Widmann on 1/24/16.
//  Copyright © 2016 CodaFi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSHHTTPRequestOperation : NSOperation

- (instancetype)initWithRequest:(NSURLRequest *)request toOutputStream:(NSOutputStream *)stream;

@end
