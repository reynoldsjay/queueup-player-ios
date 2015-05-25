//
//  ServerAPI.m
//  QueueUp
//
//  Created by Jay Reynolds on 5/24/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerAPI.h"

@implementation ServerAPI

@synthesize idAndEmail = _idAndEmail;

static ServerAPI *singletonInstance;

+ (ServerAPI*)getInstance {
    if (singletonInstance == nil) {
        singletonInstance = [[super alloc] init];
    }
    return singletonInstance;
}


- (NSString*)postData:(id)postJson toURL:(NSString*)url {
                         
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postJson options:0 error:&error];
    NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSData* responseData = nil;
    NSURLResponse* response;
    responseData = [NSMutableData data];
    error = nil;
    responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"Response from server:%@",responseString);
    return responseString;
}

- (id)parseJson:(NSString*)jsonString {
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return json;
}

@end