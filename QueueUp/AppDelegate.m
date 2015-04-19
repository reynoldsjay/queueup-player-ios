#import "AppDelegate.h"
#import "Playlist.h"
#import "Config.h"

@interface AppDelegate ()

@end

#define kSessionUserDefaultsKey "SpotifySession"

@implementation AppDelegate


@synthesize currentPlaylist = _currentPlaylist;

-(void)enableAudioPlaybackWithSession:(SPTSession *)session {
    NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:session];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sessionData forKey:@kSessionUserDefaultsKey];
    [userDefaults synchronize];
    self.session = session;
}

- (void)openLoginPage {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    NSString *swapUrl = @kTokenSwapServiceURL;
    NSURL *loginURL;
    if (swapUrl == nil || [swapUrl isEqualToString:@""]) {
        // If we don't have a token exchange service, we need to request the token response type.
        loginURL = [auth loginURLForClientId:@kClientId
                         declaredRedirectURL:[NSURL URLWithString:@kCallbackURL]
                                      scopes:@[SPTAuthStreamingScope]
                            withResponseType:@"token"];
    }
    else {
        loginURL = [auth loginURLForClientId:@kClientId
                         declaredRedirectURL:[NSURL URLWithString:@kCallbackURL]
                                      scopes:@[SPTAuthStreamingScope]];
        
    }
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // If you open a URL during application:didFinishLaunchingWithOptions:, you
        // seem to get into a weird state.
        [[UIApplication sharedApplication] openURL:loginURL];
    });
}

- (void)renewTokenAndEnablePlayback {
    id sessionData = [[NSUserDefaults standardUserDefaults] objectForKey:@kSessionUserDefaultsKey];
    SPTSession *session = sessionData ? [NSKeyedUnarchiver unarchiveObjectWithData:sessionData] : nil;
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    [auth renewSession:session withServiceEndpointAtURL:[NSURL URLWithString:@kTokenRefreshServiceURL] callback:^(NSError *error, SPTSession *session) {
        if (error) {
            NSLog(@"*** Error renewing session: %@", error);
            return;
        }
        
        [self enableAudioPlaybackWithSession:session];
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    id sessionData = [[NSUserDefaults standardUserDefaults] objectForKey:@kSessionUserDefaultsKey];
    SPTSession *session = sessionData ? [NSKeyedUnarchiver unarchiveObjectWithData:sessionData] : nil;
    
    NSString *refreshUrl = @kTokenRefreshServiceURL;
    
    if (session) {
        // We have a session stored.
        if ([session isValid]) {
            // It's still valid, enable playback.
            [self enableAudioPlaybackWithSession:session];
        } else {
            // Oh noes, the token has expired.
            
            // If we're not using a backend token service we need to prompt the user to sign in again here.
            if (refreshUrl == nil || [refreshUrl isEqualToString:@""]) {
                [self openLoginPage];
            } else {
                [self renewTokenAndEnablePlayback];
            }
        }
    } else {
        // We don't have an session, prompt the user to sign in.
        [self openLoginPage];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    SPTAuthCallback authCallback = ^(NSError *error, SPTSession *session) {
        // This is the callback that'll be triggered when auth is completed (or fails).
        
        if (error != nil) {
            NSLog(@"*** Auth error: %@", error);
            return;
        }
        
        NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:session];
        [[NSUserDefaults standardUserDefaults] setObject:sessionData
                                                  forKey:@kSessionUserDefaultsKey];
        [self enableAudioPlaybackWithSession:session];
    };
    
    /*
     STEP 2: Handle the callback from the authentication service. -[SPAuth -canHandleURL:withDeclaredRedirectURL:]
     helps us filter out URLs that aren't authentication URLs (i.e., URLs you use elsewhere in your application).
     */
    
    NSString *swapUrl = @kTokenSwapServiceURL;
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:@kCallbackURL]]) {
        if (swapUrl == nil || [swapUrl isEqualToString:@""]) {
            // If we don't have a token exchange service, we'll just handle the implicit token response directly.
            [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url callback:authCallback];
        } else {
            // If we have a token exchange service, we'll call it and get the token.
            [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url
                                                tokenSwapServiceEndpointAtURL:[NSURL URLWithString:swapUrl]
                                                                     callback:authCallback];
        }
        return YES;
    }
    
    return NO;
}

@end
