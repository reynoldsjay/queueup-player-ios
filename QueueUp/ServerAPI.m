//
//  ServerAPI.m
//  QueueUp
//
//  Created by Jay Reynolds on 5/24/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerAPI.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "Config.h"

@implementation ServerAPI

@synthesize idAndToken = _idAndToken;
@synthesize currentPlaylist = _currentPlaylist;
@synthesize hosting = _hosting;

static ServerAPI *singletonInstance;

+ (ServerAPI*)getInstance {
    if (singletonInstance == nil) {
        singletonInstance = [[super alloc] init];
    }
    return singletonInstance;
}


// returns string of json object response
- (NSString*)postData:(id)postJson toURL:(NSString*)url {
    
    NSLog(@"TRYING POST");
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postJson options:0 error:&error];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *toURL = [NSString stringWithFormat:@"%@%@", @hostDomain, url];
    [request setURL:[NSURL URLWithString:toURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (self.idAndToken) {
        NSLog(@"extra header");
        [request setValue:[self getDate] forHTTPHeaderField:@"Date"];
        [request setValue:[self hashAuthForMethod:@"POST" andRoute:url] forHTTPHeaderField:@"Authorization"];
    }
    
    [request setHTTPBody:postData];
    
    NSData* responseData = nil;
    NSURLResponse* response;
    responseData = [NSMutableData data];
    error = nil;
    responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    //NSLog(@"Response from server:%@",responseString);
    return responseString;
}

// returns string of json object response
- (NSString*)getDataFromURL:(NSString*)url {
    
    NSLog(@"TRYING GET");
    NSError *error;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:([NSString stringWithFormat:@"%@%@", @hostDomain, url])]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (self.idAndToken) {
        NSLog(@"extra header");
        [request setValue:[self getDate] forHTTPHeaderField:@"Date"];
        [request setValue:[self hashAuthForMethod:@"GET" andRoute:url] forHTTPHeaderField:@"Authorization"];
    }
    
    
    NSData* responseData = nil;
    NSURLResponse* response;
    responseData = [NSMutableData data];
    error = nil;
    responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    //NSLog(@"Response from server:%@",responseString);
    return responseString;
}

- (id)parseJson:(NSString*)jsonString {
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return json;
}


- (NSString *) jsonToString:(id)jsonObj {
    return [[NSString alloc] initWithData:jsonObj encoding:NSUTF8StringEncoding];
}


- (NSString *) hashAuthForMethod: (NSString *) method andRoute: (NSString *) route {
    
    NSString *unixSeconds = [NSString stringWithFormat:@"%ld", (long) NSDate.date.timeIntervalSince1970];

    NSString *host = @"localhost";
    
    NSString *key = ((NSDictionary*)self.idAndToken)[@"client_token"];
    NSString *usrID = ((NSDictionary*)self.idAndToken)[@"user_id"];

    
    NSString *toHash = [NSString stringWithFormat:@"%@+%@+%@+%@", method, host, route, unixSeconds];
    
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [toHash cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSString *hash;
    
    NSMutableString* output = [NSMutableString   stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", cHMAC[i]];
    hash = output;
    
    NSString *combine = [NSString stringWithFormat:@"%@:%@", usrID, hash];
    
    NSData *plainData = [combine dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    
    return [NSString stringWithFormat:@"Basic %@", base64String];

    
}

- (NSString *) getDate {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
    return [formatter stringFromDate:date];
}


@end