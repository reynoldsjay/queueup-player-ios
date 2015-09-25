//
//  Config.h
//

#ifndef Simple_Track_Playback_Config_h
#define Simple_Track_Playback_Config_h


#define kClientId "8f3024630b4b41c1b4205ff79a13d7a7"
#define kCallbackURL "playlists-login://callback"

#define kTokenSwapServiceURL "https://fierce-taiga-2685.herokuapp.com/swap"

// If you don't provide a token swap service url the login will use implicit grant tokens, which
// means that your user will need to sign in again every time the token expires.

#define kTokenRefreshServiceURL "https://fierce-taiga-2685.herokuapp.com/refresh"


// If you don't provide a token refresh service url, the user will need to sign in again every
// time their token expires.


#define kSessionUserDefaultsKey "SpotifySession"

// Qup Server

#define hostDomain "http://queueup.io"
#define hashDomain "queueup.io"


#endif