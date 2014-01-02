//
//  SUUnarchiver.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/16/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#ifndef SUUNARCHIVER_H
#define SUUNARCHIVER_H

@class SUHost;

typedef void(^SUUnarchiverCompletionBlock)(BOOL success);

@interface SUUnarchiver : NSObject {
	id delegate;
	NSString *archivePath;
	SUHost *updateHost;
	SUUnarchiverCompletionBlock _completionBlock;
	dispatch_queue_t callbackQueue;
}

+ (SUUnarchiver *)unarchiverForPath:(NSString *)path updatingHost:(SUHost *)host;
- (void)setCompletion:(SUUnarchiverCompletionBlock)completion callbackQueue:(dispatch_queue_t)queue;
- (void)setDelegate:delegate;

- (void)start;

- (SUUnarchiverCompletionBlock)completionBlock;
- (void)setCompletionBlock:(SUUnarchiverCompletionBlock)completion;

@end

@interface NSObject (SUUnarchiverDelegate)
- (void)unarchiver:(SUUnarchiver *)unarchiver extractedLength:(unsigned long)length;
- (void)unarchiverDidFinish:(SUUnarchiver *)unarchiver;
- (void)unarchiverDidFail:(SUUnarchiver *)unarchiver;
- (void)unarchiver:(SUUnarchiver *)unarchiver requiresPasswordReturnedViaInvocation:(NSInvocation *)invocation;
@end

#endif
