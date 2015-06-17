//
//  PlayerViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 6/16/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "Config.h"
#import "PlayerViewController.h"
#import <Spotify/SPTDiskCache.h>

@interface PlayerViewController () <SPTAudioStreamingDelegate>

//@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
//@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
//@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
//@property (weak, nonatomic) IBOutlet UIImageView *coverView;
//@property (weak, nonatomic) IBOutlet UIImageView *coverView2;
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, strong) SPTAudioStreamingController *player;

@end

@implementation PlayerViewController

-(void)viewDidLoad {
    [super viewDidLoad];
//    self.titleLabel.text = @"Nothing Playing";
//    self.albumLabel.text = @"";
//    self.artistLabel.text = @"";
}

//- (BOOL)prefersStatusBarHidden {
//    return YES;
//}

#pragma mark - Actions

-(IBAction)rewind:(id)sender {
    [self.player skipPrevious:nil];
}

-(IBAction)playPause:(id)sender {
    [self.player setIsPlaying:!self.player.isPlaying callback:nil];
}

-(IBAction)fastForward:(id)sender {
    [self.player skipNext:nil];
}

- (IBAction)logoutClicked:(id)sender {
    SPTAuth *auth = [SPTAuth defaultInstance];
    if (self.player) {
        [self.player logout:^(NSError *error) {
            auth.session = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Logic


//- (UIImage *)applyBlurOnImage: (UIImage *)imageToBlur
//                   withRadius: (CGFloat)blurRadius {
//    
//    CIImage *originalImage = [CIImage imageWithCGImage: imageToBlur.CGImage];
//    CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"
//                                  keysAndValues: kCIInputImageKey, originalImage,
//                        @"inputRadius", @(blurRadius), nil];
//    
//    CIImage *outputImage = filter.outputImage;
//    CIContext *context = [CIContext contextWithOptions:nil];
//    
//    CGImageRef outImage = [context createCGImage: outputImage
//                                        fromRect: [outputImage extent]];
//    
//    UIImage *ret = [UIImage imageWithCGImage: outImage];
//    
//    CGImageRelease(outImage);
//    
//    return ret;
//}

//-(void)updateUI {
//    SPTAuth *auth = [SPTAuth defaultInstance];
//    
//    if (self.player.currentTrackURI == nil) {
//        self.coverView.image = nil;
//        self.coverView2.image = nil;
//        return;
//    }
//    
//    [self.spinner startAnimating];
//    
//    [SPTTrack trackWithURI:self.player.currentTrackURI
//                   session:auth.session
//                  callback:^(NSError *error, SPTTrack *track) {
//                      
//                      self.titleLabel.text = track.name;
//                      self.albumLabel.text = track.album.name;
//                      
//                      SPTPartialArtist *artist = [track.artists objectAtIndex:0];
//                      self.artistLabel.text = artist.name;
//                      
//                      NSURL *imageURL = track.album.largestCover.imageURL;
//                      if (imageURL == nil) {
//                          NSLog(@"Album %@ doesn't have any images!", track.album);
//                          self.coverView.image = nil;
//                          self.coverView2.image = nil;
//                          return;
//                      }
//                      
//                      // Pop over to a background queue to load the image over the network.
//                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                          NSError *error = nil;
//                          UIImage *image = nil;
//                          NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
//                          
//                          if (imageData != nil) {
//                              image = [UIImage imageWithData:imageData];
//                          }
//                          
//                          
//                          // …and back to the main queue to display the image.
//                          dispatch_async(dispatch_get_main_queue(), ^{
//                              [self.spinner stopAnimating];
//                              self.coverView.image = image;
//                              if (image == nil) {
//                                  NSLog(@"Couldn't load cover image with error: %@", error);
//                                  return;
//                              }
//                          });
//                          
//                          // Also generate a blurry version for the background
//                          UIImage *blurred = [self applyBlurOnImage:image withRadius:10.0f];
//                          dispatch_async(dispatch_get_main_queue(), ^{
//                              self.coverView2.image = blurred;
//                          });
//                      });
//                      
//                  }];
//}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self handleNewSession];
}

-(void)handleNewSession {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.player.playbackDelegate = self;
        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
    [self.player loginWithSession:auth.session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        
        //[self updateUI];
        
        NSURLRequest *playlistReq = [SPTPlaylistSnapshot createRequestForPlaylistWithURI:[NSURL URLWithString:@"spotify:user:cariboutheband:playlist:4Dg0J0ICj9kKTGDyFu0Cv4"]
                                                                             accessToken:auth.session.accessToken
                                                                                   error:nil];
        
        [[SPTRequest sharedHandler] performRequest:playlistReq callback:^(NSError *error, NSURLResponse *response, NSData *data) {
            if (error != nil) {
                NSLog(@"*** Failed to get playlist %@", error);
                return;
            }
            
            SPTPlaylistSnapshot *playlistSnapshot = [SPTPlaylistSnapshot playlistSnapshotFromData:data withResponse:response error:nil];
            
            [self.player playURIs:playlistSnapshot.firstTrackPage.items fromIndex:0 callback:nil];
        }];
    }];
}

#pragma mark - Track Player Delegates

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"track changed = %@", [trackMetadata valueForKey:SPTAudioStreamingMetadataTrackURI]);
    //[self updateUI];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
}

@end