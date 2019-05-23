//
//  AdnuntiusAdView.swift
//  AdnuntiusSDK
//
//  Created by Mateusz Grzywa on 27/08/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//

import UIKit

@IBDesignable public class AdnuntiusAdView: UIView {
    var imageView : UIImageView
    var tapAction : String = ""
    @IBInspectable var adViewName = ""
    override public init(frame: CGRect) {
        self.imageView = UIImageView()
        super.init(frame: frame)
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.bounds.size.height))
        addBehavior()
    }
    
    convenience public init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.imageView = UIImageView()
        super.init(coder: aDecoder)
        self.layoutIfNeeded()
        addBehavior()
    }
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        imageView.frame = rect

        
    }
    open func adView () -> AdnuntiusAdView {
        return self
    }
    @objc func adTap(_ sender:UITapGestureRecognizer){
        if let url = URL(string: self.tapAction) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    open func addBehavior() {
        self.imageView.contentMode = .scaleToFill
        
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.adTap (_:)))
        self.addGestureRecognizer(gesture)


    }
}
