//
//  AppConfig.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import Foundation

struct AppConfig {
    
    static var isDragApp: Bool {
        
        #if IS_DRAG_APP
            return true
        #endif
        
        return false
        
    }
    
}
