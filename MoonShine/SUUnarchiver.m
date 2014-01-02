//
//  SUUnarchiver.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/16/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUnarchiver.h"
#import "SUUnarchiver_Private.h"

@implementation SUUnarchiver

+ (SUUnarchiver *)unarchiverForPath:(NSString *)path updatingHost:(SUHost *)host
{
	NSEnumerator *implementationEnumerator = [[self unarchiverImplementations] objectEnumerator];
	id current;
	while ((current = [implementationEnumerator nextObject]))
	{
		if ([current canUnarchivePath:path])
			return [[[current alloc] initWithPath:path host:host] autorelease];
	}
	return nil;
}

- (void)setCompletion:(SUUnarchiverCompletionBlock)completion callbackQueue:(dispatch_queue_t)queue {
	if (callbackQueue != NULL) {
		dispatch_release(callbackQueue);
		callbackQueue = queue;
	}
	callbackQueue = queue;
	if (callbackQueue != NULL) {
		dispatch_retain(callbackQueue);
	}
	self.completionBlock = completion;
}

- (NSString *)description { return [NSString stringWithFormat:@"%@ <%@>", [self class], archivePath]; }

- (void)setDelegate:del
{
	delegate = del;
}

- (SUUnarchiverCompletionBlock)completionBlock {
	return _completionBlock;
}

- (void)setCompletionBlock:(SUUnarchiverCompletionBlock)completion {
	_completionBlock = Block_copy(completion);
}

- (void)start
{
	// No-op
}

@end
