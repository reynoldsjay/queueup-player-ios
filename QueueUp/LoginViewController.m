//
//  LoginViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 5/24/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "LoginViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "ServerAPI.h"

@implementation LoginViewController


- (void) viewDidLoad {

    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.center = self.view.center;
    [self.view addSubview:loginButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //NSString* access_token =[FBSDKAccessToken currentAccessToken].tokenString;
    //NSLog(@"Access Token: %@",access_token);
}


- (void)appDidBecomeActive:(NSNotification *)notification {
    if ([FBSDKAccessToken currentAccessToken]) {
        NSLog(@"User logged in.");
        NSString* accessString = [[NSString alloc] initWithFormat:@"{\"facebook_access_token\" : \"%@\"}", [FBSDKAccessToken currentAccessToken].tokenString];
        // NSLog(@"%@", accessString);

        id json = [ServerAPI parseJson:accessString];
        [ServerAPI postData:json toURL:@"http://localhost:3004/api/auth/login"];
        
        //[self performSegueWithIdentifier:@"login" sender:self];
    }
    
}

@end
