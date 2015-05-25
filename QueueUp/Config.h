//
//  Config.h
//

#ifndef Simple_Track_Playback_Config_h
#define Simple_Track_Playback_Config_h

// #warning Please update these values to match the settings for your own application as these example values could change at any time.
// For an in-depth auth demo, see the "Basic Auth" demo project supplied with the SDK.
// Don't forget to add your callback URL's prefix to the URL Types section in the target's Info pane!

#define kClientId "8f3024630b4b41c1b4205ff79a13d7a7"
#define kCallbackURL "playlists-login://callback"

#define kTokenSwapServiceURL "https://fierce-taiga-2685.herokuapp.com/swap"

#define hostDomain "http://localhost:3004"


// If you don't provide a token swap service url the login will use implicit grant tokens, which
// means that your user will need to sign in again every time the token expires.

#define kTokenRefreshServiceURL "https://fierce-taiga-2685.herokuapp.com/refresh"


// If you don't provide a token refresh service url, the user will need to sign in again every
// time their token expires.


#endif
