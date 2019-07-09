# Adnuntius Mobile SDK

Adnuntius Mobile SDK (AMSDK) is a sdk which allows business partner to embed Adnuntius ads in thier native mobile applications.

# Integration

[logo]: https://i.imgsafe.org/79/799e4a08ca.png
- In your Xcode project add Adnuntius.framework as a Linked Framework
![logo]

- Add UIWebView to your storyboard and create outlet
- Inside UIViewController extend class by: UIWebViewDelegate
- Attach created delegate to Adnuntius View

```swift
self.adView.delegate = self
```

- In your `AppDelegate` file add header and configuration code:
```js
import AdnuntiusSDK
```
```swift
    AdnuntiusSDK.config = ["siteId": "1131763067966473843",
                           "adUnits": [
                            ["auId": "0000000000000fe6", "c": ["sports"]],
                                        ["auId": "0000000000000fe6", "c": ["sports"]]]]
    AdnuntiusSDK.adScript =
    """
        <html>
        <head />
        <body>
        <div id="adn-0000000000000fe6" style="display:none"></div>
        <script type="text/javascript">(function(d, s, e, t) { e = d.createElement(s); e.type = 'text/java' + s; e.async = 'async'; e.src = 'http' + ('https:' === location.protocol ? 's' : '') + '://cdn.adnuntius.com/adn.js'; t = d.getElementsByTagName(s)[0]; t.parentNode.insertBefore(e, t); })(document, 'script');window.adn = window.adn || {}; adn.calls = adn.calls || []; adn.calls.push(function() { adn.request({ adUnits: [ {auId: '0000000000000fe6', auW: 320, auH: 480 } ]}); });</script>
        </body>
        </html>
    """
```
- Integrate it with your view for example:
```js
// Adnuntius injector
    if (indexPath.row % 4 == 0) {
        if let preCell = adCells?[indexPath.row] {
            debugPrint("preCell")
            return preCell
        }
        let cell = UITableViewCell()
        let webView = AdnuntiusAdWebView(frame: CGRect(x: 0, y: 10, width: tableView.frame.width, height: 100))
        webView.delegate = self
        cell.contentView.addSubview(webView)
        cell.contentView.sizeToFit()
        adCells?[indexPath.row] = cell
        return cell
    }
```
- Add delegate methods
```swift
func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
    // Define a behaviour that will happen when an ad is clicked
    guard let url = request.url, navigationType == .linkClicked else { return true }
    if #available(iOS 10.0, *) {
        UIApplication.shared.open(url)
    } else {
        UIApplication.shared.openURL(url)
    }
    return false
}
func webViewDidFinishLoad(_ webView: UIWebView) {
    // Detect if an ad is not present
    let html = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML")
    if let page = html {
        if !page.contains("<iframe") {
            // Ad is not present
            // Do any behaviour that you want to hide an ad
            // Ex. self.adView.isHidden = true
        } else {
            // Fix image url for ads
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let image = webView.stringByEvaluatingJavaScript(from: "document.body.getElementsByTagName('iframe')[0].contentWindow.document.getElementsByTagName('img')[0].getAttribute('src')") {
                    webView.stringByEvaluatingJavaScript(from: "document.body.getElementsByTagName('iframe')[0].contentWindow.document.getElementsByTagName('img')[0].setAttribute('src', 'https:"+image+"')")
                }
            }
        }
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
