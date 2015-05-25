//
//  ServerAPI.h
//  QueueUp
//
//  Created by Jay Reynolds on 5/24/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerAPI : NSObject <NSURLConnectionDataDelegate>

@property NSURLConnection *connection;
@property NSMutableData *receivedData;



//+ (ServerAPI*) getInstance;

+ (void)postData:(id)postJson toURL:(NSString*)url;

+ (NSData*)parseJson:(NSString*)jsonString;

@end