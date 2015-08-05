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
#import "Config.h"

@implementation LoginViewController


- (void) viewDidLoad {
    // fb login button
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    loginButton.center = self.view.center;
    [self.view addSubview:loginButton];
    // notify view on callbak
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

}


- (void)appDidBecomeActive:(NSNotification *)notification {
    if ([FBSDKAccessToken currentAccessToken]) {
        
        // send fb access token
        NSLog(@"User logged in.");
        NSString* accessString = [[NSString alloc] initWithFormat:@"{\"facebook_access_token\" : \"%@\"}", [FBSDKAccessToken currentAccessToken].tokenString];
        ServerAPI *api = [ServerAPI getInstance];
        id json = [api parseJson:accessString];
        NSString *client = [api postData:json toURL:(@"/api/v2/auth/login")];
        // store client id
        NSString *theID = ((NSDictionary*)[api parseJson:client])[@"user_id"];
        

         NSString *token = ((NSDictionary*)[api parseJson:client])[@"client_token"];
         NSString *combine = [[NSString alloc] initWithFormat:@"{\"user_id\":\"%@\", \"client_token\":\"%@\"}", theID, token];
         api.idAndToken = [api parseJson:combine];
         [self performSegueWithIdentifier:@"login" sender:self];
        
        
        //
    }
    
}

@end
