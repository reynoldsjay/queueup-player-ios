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

    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    loginButton.center = self.view.center;
    [self.view addSubview:loginButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

}


- (void)appDidBecomeActive:(NSNotification *)notification {
    if ([FBSDKAccessToken currentAccessToken]) {
        
        NSLog(@"User logged in.");
        NSString* accessString = [[NSString alloc] initWithFormat:@"{\"facebook_access_token\" : \"%@\"}", [FBSDKAccessToken currentAccessToken].tokenString];
        // NSLog(@"%@", accessString);
        ServerAPI *api = [ServerAPI getInstance];
        id json = [api parseJson:accessString];
        NSString *client = [api postData:json toURL:(@hostDomain @"/api/auth/login")];
        NSString *theID = ((NSDictionary*)[api parseJson:client])[@"client_id"];
        

        // store email
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error) {
                 NSString *email = result[@"email"];
                 NSString *combine = [[NSString alloc] initWithFormat:@"{\"client_id\":\"%@\", \"email\":\"%@\"}", theID, email];
                 api.idAndEmail = [api parseJson:combine];
                 [self performSegueWithIdentifier:@"login" sender:self];
             }
         }];
        
        
        //
    }
    
}

@end
