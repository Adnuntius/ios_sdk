# Adnuntius iOS SDK

Adnuntius iOS SDK is an ios sdk which allows business partners to embed Adnuntius ads in their native ios applications.

## Building

Use Carthage cli to build the AdnuntiusSDK.framework and import into your project.   Create or modify your Cartfile to include:

```
github "Adnuntius/ios_sdk" == 1.4.2
```

Run `carthage update`

### XCode 12 Workaround

Carthage has some issues handling XCode 12, for the time being you can work around this by creating a carthage.sh as documented at
https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md

And then run the `./carthage.sh update` command.   If you have complaints about XCode compatibility, run the `Product -> Clean Build Folder` to refresh the
Carthage generated artifacts.

### Add to your Project

After carthage update is completed, the framework must be added to your project as a linked framework.  Drag and drop the Carthage/Build/iOS/AdnuntiusSDK.framework onto your project.

![Linked Framework](images/linked-framework.png)

Add a Run Script Build Phase to your project, make sure you fill in the Input File section too:

![Build Phases Run Script](images/run-script.png)

For more information about Carthage, refer to [If you're building for iOS, tvOS, or watchOS](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos)

### Objective C Only

![Always Embed Swift Standard Libraries](images/swift-libraries.png)

Because the SDK is Swift based, if you are including it as a framework into your objective c application, the Swift libraries must also be included, they are not by default.

## Integrating

### loadFromConfig format

Currently, only a single adUnit can be specified in the adUnits array structure, but otherwise you can pass in any of the configuration allowed by adn.js

https://docs.adnuntius.com/adnuntius-advertising/requesting-ads/intro/adn-request

### Swift

- Add WkWebView to your storyboard and create outlet
- Configure each AdnuntiusAdWebView
- Load the ad into the view via the loadFromScript, loadFromConfig or loadFromApi
- Implement the completionHandler to react to a missing ad


- In your `ViewController` file add header and implement the viewDidLoad method:

```swift
import AdnuntiusSDK
```

Reference the AdnuntiusAdWebView:

```swift
@IBOutlet weak var adView: AdnuntiusAdWebView!
```

And then load the ad of your choice using loadFromConfig:

```swift
    override func viewDidLoad() {
        super.viewDidLoad() 
        
        let configResult = adView.loadFromConfig([
              "adUnits": [
                    ["auId": "000000000006f450", "auW": 200, "kv": [["version": "6s"]]
                ]
              ]
            ], completionHandler: self)
        if !configResult {
            print("Config is wrong, check the log")
        }
    }
    
    func onNoAdResponse(_ view: AdnuntiusAdWebView) {
        print("No Ad Found!")
        self.adView.isHidden = true
    }
    
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String) {
	self.adView.isHidden = true
    }
    
    func onAdResponse(_ view: AdnuntiusAdWebView, _ width: Int, _ height: Int) {
        print("onAdResponse: width: \(width), height: \(height)")
	var frame = self.adView.frame
        if (height > 0) {
            frame.size.height = CGFloat(height)
        }
        self.adView.frame = frame
    }
```

The onComplete / onFailure AdWebViewStateDelegate protocol methods are where you can add logic to react to various outcomes of trying to load an an ad.  For instance if there are no matched ads, the onComplete will return an adCount of 0, and you could hide the ad view for instance.

### Objective C

- Add WkWebView to your storyboard and create outlet
- Declare a @property referencing the AdnuntiusAdWebView declared in the story board
- Load the ad into the view via the loadFromScript, loadFromConfig or loadFromApi
- Implement the completionHandler to react to a missing ad

In the ViewController header file import the AdnuntiusSDK swift header:

```swift
    #import <AdnuntiusSDK/AdnuntiusSDK-Swift.h>

    @property (weak, nonatomic) IBOutlet AdnuntiusAdWebView *adView;
```

In the ViewController m file, implement the viewDidLoad method:

```swift
    [super viewDidLoad];

    NSString* adId = @"000000000006f450";

    NSDictionary* config = @{
        @"adUnits" : @[
                @{
                    @"auId":adId, @"auH":@200, @"kv": @[@{@"version" : @"X"}]
                }
        ]
    };

    [self.adView loadFromConfig:config completionHandler:self];

- (void)onNoAdResponse:(AdnuntiusAdWebView * _Nonnull)view {
    NSLog(@"No add found");
    self.adView.hidden = true;
}

- (void)onFailure:(AdnuntiusAdWebView * _Nonnull)view :(NSString * _Nonnull)message {
    NSLog(@"Failure: %@", message);
    self.adView.hidden = true;
}

- (void)onAdResponse:(AdnuntiusAdWebView * _Nonnull)view :(NSInteger)width :(NSInteger)height {    
    if (height > 0) {
        CGRect frame = self.adView.frame;
        frame.size.height = height;
        self.adView.frame = frame;
    }
}
```

- Change Info.plist

```xml
    <key>NSAppTransportSecurity</key>
    <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
    </dict>
```

## Upgrading to 1.2.X to 1.4.X

Unfortunately between 1.2.X and 1.4.X we have made some breaking api changes that were unavoidable in order to provide an improved experience and a more consistent use of the SDK

### Removed Api Calls

 We are removing support for the loadFromScript and the old simple loadFromConfig functions.     The reason why, is in order to ensure a consistent experience we need more control over
 what features and parameters that are used and we can't do that if we accept a html block.

In their place is a single loadFromConfig which uses the same json format as loadFromApi already does, and this is supported for both Swift and Objective-C.   The existing loadFromApi support remains
unchanged except for the completion handler methods have been changed.

### Updated Completion Handler

Between 1.3.0 and 1.4.X we made some changes to the completion handlers that are not backwards compatible.

The onFailure handler remains the same
The onComplete get replaces with two new functions:

- onNoAdResponse (which used to be onComplete with adCount == 0)
- onAdResponse

The reason for this, is we have added new arguments to the onAdResponse, including the calculated width and height that are used by the rendered div, so you can use that to
control any resizing of your uiviews.   We will revisit trying to do a better job of this with wkWebView, but this change seemed like a good idea anyway.

### Updating from UIWebView to WKWebView

Version 1.4.0 of the SDK is based on WkWebView instead of the deprecated UiWebView.    If you want to use the SDK with interface builder, your target iOS version must be 11, otherwise you will receive the 
dreaded `WKWebView before iOS 11.0 (NSCoding support was broken in previous versions)` error message.   If you are constructing an instance of the AdnuntiusWebView programmatically this should not be an issue.

### Updating your storyboards.    

If you have a fairly simple story board for your ad view, you can replace the `<webview>` with `<wkWebView>` and make sure to add a `<wkWebViewConfiguration>` section as a sub element, like so:

```xml
    <wkWebViewConfiguration key="configuration">
        <audiovisualMediaTypes key="mediaTypesRequiringUserActionForPlayback" none="YES"/>
        <wkPreferences key="preferences"/>
    </wkWebViewConfiguration>
```

## Upgrading from 1.1.4 and 1.1.5

Unfortunately 1.2.0 is not API compatible with 1.1.4 and 1.1.5.  Version 1.2.0 was released with fairly significant upgrades to allow it to work with Objective-C and to enable applications to configure more than one ad configuration in their application.  Before because the configuration was static this was pretty much impossible.

Unfortunately this does mean you will need to make changes to your app to use the new version.  Please refer to the Samples project to figure out what needs to be changed. 

If you want to keep compiling your application with the earlier version of the SDK (1.1.4 or 1.1.5) you should adjust your cartfile as follows:

```
github "Adnuntius/ios_sdk" == 1.1.5
```

# Examples

Some examples of using the SDK are available from https://github.com/Adnuntius/ios_sdk_examples

## Bugs, Issues and Support

This SDK is a work in progress and will be given attention when necessary based on feed back.  You
can raise issues on github or via zen desk at https://admin.adnuntius.com

# License

This project uses the Apache 2 License.  Refer to the LICENSE file.

