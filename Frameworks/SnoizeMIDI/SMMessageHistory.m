/*
 Copyright (c) 2001-2004, Kurt Revis.  All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "SMMessageHistory.h"


@interface SMMessageHistory (Private)

- (void)limitSavedMessages;
- (void)historyHasChangedWithNewMessages:(BOOL)wereNewMessages;

@end


@implementation SMMessageHistory

NSString *SMMessageHistoryChangedNotification = @"SMMessageHistoryChangedNotification";
NSString *SMMessageHistoryWereMessagesAdded = @"SMMessageHistoryWereMessagesAdded";


+ (unsigned int)defaultHistorySize;
{
    return 1000;
}


- (id)init;
{
    if (!(self = [super init]))
        return nil;

    savedMessages = [[NSMutableArray alloc] init];
    savedMessagesLock = [[NSLock alloc] init];
    historySize = [[self class] defaultHistorySize];

    return self;
}

- (void)dealloc;
{
    [savedMessages release];
    savedMessages = nil;
    [savedMessagesLock release];
    savedMessagesLock = nil;
    
    [super dealloc];
}

- (NSArray *)savedMessages;
{
    NSArray *messages;

    [savedMessagesLock lock];
    messages = [NSArray arrayWithArray:savedMessages];
    [savedMessagesLock unlock];
    
    return messages;
}

- (void)clearSavedMessages;
{
    BOOL wereMessages = NO;

    [savedMessagesLock lock];
    if ([savedMessages count] > 0) {
        wereMessages = YES;
        [savedMessages removeAllObjects];
    }
    [savedMessagesLock unlock];
    
    if (wereMessages)
        [self historyHasChangedWithNewMessages:NO];
}

- (unsigned int)historySize;
{
    return historySize;
}

- (void)setHistorySize:(unsigned int)newHistorySize;
{
    unsigned int oldMessageCount, newMessageCount;

    [savedMessagesLock lock];

    historySize = newHistorySize;
    
    oldMessageCount = [savedMessages count];
    [self limitSavedMessages];
    newMessageCount = [savedMessages count];

    [savedMessagesLock unlock];

    if (oldMessageCount != newMessageCount)
        [self historyHasChangedWithNewMessages:NO];
}

- (void)takeMIDIMessages:(NSArray *)messages;
{
    [savedMessagesLock lock];
    [savedMessages addObjectsFromArray:messages];
    [self limitSavedMessages];
    [savedMessagesLock unlock];
    
    [self historyHasChangedWithNewMessages:YES];
}

@end


@implementation SMMessageHistory (Private)

- (void)limitSavedMessages;
{
    // NOTE We assume that this thread has taken the savedMessagesLock
    unsigned int messageCount;

    messageCount = [savedMessages count];
    if (messageCount > historySize) {
        NSRange deleteRange;
        
        deleteRange = NSMakeRange(0, messageCount - historySize);
        [savedMessages removeObjectsInRange:deleteRange];
    }
}

- (void)historyHasChangedWithNewMessages:(BOOL)wereNewMessages;
{
    NSDictionary *userInfo;

    userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:wereNewMessages] forKey:SMMessageHistoryWereMessagesAdded];

    [[NSNotificationCenter defaultCenter] postNotificationName:SMMessageHistoryChangedNotification object:self userInfo:userInfo];
}

@end
