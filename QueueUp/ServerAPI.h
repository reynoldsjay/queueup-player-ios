//
//  ServerAPI.h
//  QueueUp
//
//  Created by Jay Reynolds on 5/24/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerAPI : NSObject <NSURLConnectionDataDelegate>

@property id idAndToken;
@property id currentPlaylist;
@property BOOL hosting;

+ (ServerAPI*) getInstance;

- (NSString*)postData:(id)postJson toURL:(NSString*)url;
- (NSString*)getDataFromURL:(NSString*)url;

- (NSData*)parseJson:(NSString*)jsonString;

- (NSString*)jsonToString:(id)jsonObj;

@end