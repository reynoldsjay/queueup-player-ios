#import "AppDelegate.h"
#import "Playlist.h"

// Constants
static NSString * const kClientId = @"8f3024630b4b41c1b4205ff79a13d7a7";
static NSString * const kCallbackURL = @"playlists-login://callback";
static NSString * const kTokenSwapURL = @"https://fierce-taiga-2685.herokuapp.com/swap";

@interface AppDelegate ()



@end


@implementation AppDelegate


@synthesize currentPlaylist = _currentPlaylist;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    [self startAuthentication];
    return YES;
    
}



// start auth
- (void)startAuthentication {
    // Create SPTAuth instance; create login URL and open it
    SPTAuth *auth = [SPTAuth defaultInstance];
    NSURL *loginURL = [auth loginURLForClientId:kClientId
                            declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                                         scopes:@[SPTAuthStreamingScope]];
    
    // Opening a URL in Safari close to application launch may trigger
    // an iOS bug, so we wait a bit before doing so.
    [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                            withObject:loginURL afterDelay:0.1];
}



// Handle auth callback
-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation {
    
    // Ask SPTAuth if the URL given is a Spotify authentication callback
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kCallbackURL]]) {
        
        // Call the token swap service to get a logged in session
        [[SPTAuth defaultInstance]
         handleAuthCallbackWithTriggeredAuthURL:url
         tokenSwapServiceEndpointAtURL:[NSURL URLWithString:kTokenSwapURL]
         callback:^(NSError *error, SPTSession *session) {
             
             if (error != nil) {
                 NSLog(@"*** Auth error: %@", error);
                 return;
             }
             
             // Call the -playUsingSession: method to play a track
             self.session = session;
         }];
        return YES;
    }
    
    return NO;
}

//-(void) playSong:(NSString*)trackURI {
//    
//    // Create a new player if needed
//    if (self.player == nil) {
//        self.player = [[SPTAudioStreamingController alloc] initWithClientId:kClientId];
//    }
//    
//    [self.player loginWithSession:self.session callback:^(NSError *error) {
//        
//        if (error != nil) {
//            NSLog(@"*** Enabling playback got error: %@", error);
//            return;
//        }
//        
//        [SPTRequest requestItemAtURI:[NSURL URLWithString:trackURI]
//                         withSession:nil
//                            callback:^(NSError *error, SPTTrack *track) {
//                                
//                                if (error != nil) {
//                                    NSLog(@"*** Album lookup got error %@", error);
//                                    return;
//                                }
//                                [self.player playTrackProvider:track callback:nil];
//                                
//                            }];
//    }];
//    
//}
//
//- (void) play {
//    [self.player setIsPlaying:YES callback:^(NSError *error) {
//        
//        if (error != nil) {
//            NSLog(@"*** Play error: %@", error);
//            return;
//        }
//    }];
//}
//
//
//- (void) pause {
//    [self.player setIsPlaying:NO callback:^(NSError *error) {
//        
//        if (error != nil) {
//            NSLog(@"*** Pause error: %@", error);
//            return;
//        }
//    }];
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
