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
#import "SWRevealViewController.h"

@interface LoginViewController ()

@property IBOutlet UITextField *emailField;
@property IBOutlet UITextField *passwordField;
@property IBOutlet UITextField *nameField;
@property IBOutlet UIView *outView;


@end

@implementation LoginViewController {
    ServerAPI *api;
}


- (void) viewDidLoad {
    // fb login button
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    loginButton.center = CGPointMake(self.view.center.x, 145);
    [self.view addSubview:loginButton];
    // notify view on callbak
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    api = [ServerAPI getInstance];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.outView addGestureRecognizer:tap];

}

-(void)dismissKeyboard {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.nameField resignFirstResponder];
}


- (void)appDidBecomeActive:(NSNotification *)notification {
    if ([FBSDKAccessToken currentAccessToken]) {
        
        // send fb access token
        NSLog(@"User logged in.");
        NSString* accessString = [[NSString alloc] initWithFormat:@"{\"facebook_access_token\" : \"%@\"}", [FBSDKAccessToken currentAccessToken].tokenString];

        id json = [api parseJson:accessString];
        NSString *client = [api postData:json toURL:(@"/api/v2/auth/login")];
        // store client id
        NSLog(@"login: %@", client);
        NSString *theID = ((NSDictionary*)[api parseJson:client])[@"user_id"];


        NSString *token = ((NSDictionary*)[api parseJson:client])[@"client_token"];
        NSString *combine = [[NSString alloc] initWithFormat:@"{\"user_id\":\"%@\", \"client_token\":\"%@\"}", theID, token];
        api.idAndToken = [api parseJson:combine];
        api.loggedIn = YES;

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:api.idAndToken forKey:@"user_info"];
        [userDefaults setBool:YES forKey:@"loggedIn"];

//        NSLog(@"%hd", api.loggedIn);
        [self.revealViewController.rearViewController viewDidLoad];
        [self performSegueWithIdentifier:@"login" sender:self];
        
        
        //
    }
    
}

- (IBAction)registerClick:(id)sender {
    if ( [self.emailField.text length] == 0 || [self.nameField.text length] == 0 || [self.passwordField.text length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"All need to be filled to register."
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        ///  the text field is not empty
        NSString *userId = ((NSDictionary*)api.idAndToken)[@"user_id"];
        NSString *cToken = ((NSDictionary*)api.idAndToken)[@"client_token"];
        
        NSString* regString = [[NSString alloc] initWithFormat:@"{\"email\" : \"%@\", \"name\" : \"%@\", \"password\" : \"%@\", \"user_id\" : \"%@\", \"client_token\" : \"%@\"}", self.emailField.text, self.nameField.text, self.passwordField.text, userId, cToken];
        
        id json = [api parseJson:regString];
        NSString *client = [api postData:json toURL:(@"/api/v2/auth/register")];
        // store client id
        NSString *theID = ((NSDictionary*)[api parseJson:client])[@"user_id"];
        NSString *token = ((NSDictionary*)[api parseJson:client])[@"client_token"];
        NSString *combine = [[NSString alloc] initWithFormat:@"{\"user_id\":\"%@\", \"client_token\":\"%@\"}", theID, token];
        api.idAndToken = [api parseJson:combine];
        api.loggedIn = YES;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        api.idAndToken = [userDefaults objectForKey:@"user_info"];
        api.loggedIn = [userDefaults boolForKey:@"loggedIn"];
        [self.revealViewController.rearViewController viewDidLoad];
        [self performSegueWithIdentifier:@"login" sender:self];
    }
    
}

- (IBAction)loginClick:(id)sender {
    NSString* logString = [[NSString alloc] initWithFormat:@"{\"email\" : \"%@\", \"password\" : \"%@\"}", self.emailField.text, self.passwordField.text];
//    NSLog(logString);
    id json = [api parseJson:logString];
    NSString *client = [api postData:json toURL:(@"/api/v2/auth/login")];
    if (((NSDictionary*)[api parseJson:client])[@"user_id"]) {
        // store client id
        NSString *theID = ((NSDictionary*)[api parseJson:client])[@"user_id"];
        
        
        NSString *token = ((NSDictionary*)[api parseJson:client])[@"client_token"];
        NSString *combine = [[NSString alloc] initWithFormat:@"{\"user_id\":\"%@\", \"client_token\":\"%@\"}", theID, token];
        api.idAndToken = [api parseJson:combine];
        [self performSegueWithIdentifier:@"login" sender:self];
    } else {
        NSLog(@"wrong password");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wrong email/password combination."
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

@end
