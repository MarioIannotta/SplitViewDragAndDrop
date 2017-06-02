//
//  SplitViewDragAndDrop+Utils.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

extension UIView {
    
    func getSnapshot() -> UIImage? {
        
        var image: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        
        if let graphicCurrentContext = UIGraphicsGetCurrentContext() {
            
            layer.render(in: graphicCurrentContext)
            image = UIGraphicsGetImageFromCurrentImageContext()
            
        }
        
        UIGraphicsEndImageContext()
        
        return image
        
    }
    
    var windowRelativeFrame: CGRect {
        return self.convert(self.bounds, to: nil)
    }
    
}

extension CGRect {
    
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
}

extension UIWindow {
    
    static var width: CGFloat {
        return UIApplication.shared.delegate?.window??.frame.size.width ?? 0
    }
    
}
