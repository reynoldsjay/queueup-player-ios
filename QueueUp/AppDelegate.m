#import "AppDelegate.h"
#import "Config.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "LoginViewController.h"
#import "ServerAPI.h"


@import UIKit;


@interface AppDelegate ()

@end

@implementation AppDelegate {
    ServerAPI *api;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // facebook set up
    [FBSDKAppEvents activateApp];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    // Set up shared authentication information
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.clientID = @kClientId;
    auth.requestedScopes = @[SPTAuthStreamingScope];
    auth.redirectURL = [NSURL URLWithString:@kCallbackURL];
    #ifdef kTokenSwapServiceURL
    auth.tokenSwapURL = [NSURL URLWithString:@kTokenSwapServiceURL];
    #endif
    #ifdef kTokenRefreshServiceURL
    auth.tokenRefreshURL = [NSURL URLWithString:@kTokenRefreshServiceURL];
    #endif
    auth.sessionUserDefaultsKey = @kSessionUserDefaultsKey;
    
    
    api = [ServerAPI getInstance];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"user_info"] == nil) {
//        NSLog(@"DEFUA");
        NSString *strUniqueIdentifier;
        if ([userDefaults objectForKey:@"uuid"] == nil) {
            strUniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            [userDefaults setObject:strUniqueIdentifier forKey:@"uuid"];
        } else {
            strUniqueIdentifier = [userDefaults objectForKey:@"uuid"];
        }
        NSString *toPost = [[NSString alloc] initWithFormat:@"{\"device\" : {\"id\" : \"%@\"}}", strUniqueIdentifier];
        id json = [api parseJson:toPost];
        NSString *userInfo = [api postData:json toURL:(@"/api/v2/auth/init")];
        NSString *theID = ((NSDictionary*)[api parseJson:userInfo])[@"user_id"];
        NSString *token = ((NSDictionary*)[api parseJson:userInfo])[@"client_token"];
        NSString *combine = [[NSString alloc] initWithFormat:@"{\"user_id\":\"%@\", \"client_token\":\"%@\"}", theID, token];
        id combinedInfo = [api parseJson:combine];
        [userDefaults setObject:combinedInfo forKey:@"user_info"];
        [userDefaults setBool:NO forKey:@"loggedIn"];
        api.idAndToken = combinedInfo;
    } else {
        
        api.idAndToken = [userDefaults objectForKey:@"user_info"];
        api.loggedIn = [userDefaults boolForKey:@"loggedIn"];
        
        
    }
    
    
    
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    SPTAuthCallback authCallback = ^(NSError *error, SPTSession *session) {
        // This is the callback that'll be triggered when auth is completed (or fails).
        
        if (error != nil) {
//            NSLog(@"*** Auth error: %@", error);
            return;
        }
        
        auth.session = session;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sessionUpdated" object:self];
    };
    
    /*
     Handle the callback from the authentication service. -[SPAuth -canHandleURL:]
     helps us filter out URLs that aren't authentication URLs (i.e., URLs you use elsewhere in your application).
     */
    
    if ([auth canHandleURL:url]) {
        [auth handleAuthCallbackWithTriggeredAuthURL:url callback:authCallback];
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    }

    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

@end
