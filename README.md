# Adnuntius iOS SDK

Adnuntius iOS SDK is an ios sdk which allows business partners to embed Adnuntius ads in their native ios applications.

## Building

Use Carthage cli to build the AdnuntiusSDK.framework and import into your project.   Create or modify your Cartfile to include:

github "Adnuntius/ios_sdk" "jp_objective_c"

Run carthage update 

The framework should be added to your project as a linked framework.  Drag and drop the Carthage/Build/iOS/AdnuntiusSDK.framework onto your project.

![Linked Framework](https://i.imgsafe.org/fd/fd36067938.png)

Add a Run Script Build Phase to your project, make sure you fill in the Input File section too:

![Build Phases Run Script](https://i.imgsafe.org/fd/fd1ea7b820.png)

For more information about Carthage, refer to [If you're building for iOS, tvOS, or watchOS](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos)

## Swift Integration

- Add UIWebView to your storyboard and create outlet
- Configure each AdnuntiusAdWebView
- Optionally implement the AdWebViewStateDelegate (WIP)


- In your `ViewController` file add header and add configuration code to the viewDidLoad, then call the doLoad() method to initialise the ad web view
```swift
import AdnuntiusSDK
```
```swift
    override func viewDidLoad() {
        super.viewDidLoad() 
        
        adView.loadFromScript("""
        <html>
        <head />
        <body>
        <div id="adn-0000000000067082" style="display:none"></div>
        <script type="text/javascript">(function(d, s, e, t) { e = d.createElement(s); e.type = 'text/java' + s; e.async = 'async'; e.src = 'https://cdn.adnuntius.com/adn.js'; t = d.getElementsByTagName(s)[0]; t.parentNode.insertBefore(e, t); })(document, 'script');window.adn = window.adn || {}; adn.calls = adn.calls || []; adn.calls.push(function() { adn.request({ adUnits: [ {auId: '0000000000067082', auW: 300, auH: 250, 'c': ['sports'] } ]}); });</script>
        </body>
        </html>
        """)
    }
```
- Integrate it with your view for example:
```swift
// Adnuntius injector
    if (indexPath.row % 4 == 0) {
        if let preCell = adCells?[indexPath.row] {
            debugPrint("preCell")
            return preCell
        }
        let cell = UITableViewCell()
        let webView = AdnuntiusAdWebView(frame: CGRect(x: 0, y: 10, width: tableView.frame.width, height: 100))
        adView1.loadFromApi([
               "adUnits": [
                    ["auId": "0000000000067082", "c": ["sports"]
                ]
            ]
        ])
        cell.contentView.addSubview(webView)
        cell.contentView.sizeToFit()
        adCells?[indexPath.row] = cell
        return cell
    }
```

Its possible to listen to events for loading the ad, by implementing the AdWebViewStateDelegate protocol, and then enable this by calling the setAdWebViewStateDelegate
on the AdnuntiusAdWebView

## Objective C Integration

- Add UIWebView to your storyboard and create outlet
- Declare a @property referencing the AdnuntiusAdWebView declared in the story board
- Optionally implement the AdWebViewStateDelegate

In the ViewController header file import the AdnuntiusSDK swift header:

```swift
#import <AdnuntiusSDK/AdnuntiusSDK-Swift.h>

@property (weak, nonatomic) IBOutlet AdnuntiusAdWebView *adView;
```

In the ViewController m file, implement the viewDidLoad method:

```swift
[super viewDidLoad];

NSString *adScript = @" \
<html> \
<head /> \
<body> \
<div id=\"adn-0000000000067082\" style=\"display:none\"></div> \
<script type=\"text/javascript\">(function(d, s, e, t) { e = d.createElement(s); e.type = 'text/java' + s; e.async = 'async'; e.src =  'https://cdn.adnuntius.com/adn.js'; t = d.getElementsByTagName(s)[0]; t.parentNode.insertBefore(e, t); })(document, 'script');window.adn = window.adn || {}; adn.calls = adn.calls || []; adn.calls.push(function() { adn.request({ adUnits: [ {auId: '0000000000067082', auW: 300, auH: 250 } ]}); });</script> \
</body> \
</html>";

[self.adView loadFromScript:adScript];
```

- Change Info.plist

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

## Examples

Some examples of using the SDK are available from https://github.com/Adnuntius/ios_sdk_examples
