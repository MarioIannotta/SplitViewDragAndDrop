//
//  DragViewController.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

class DragViewController: UIViewController {
    
    @IBOutlet private var ciaoDraggableView: UIView!
    @IBOutlet private var helloDraggableView: UIView!
    @IBOutlet private var alohaDraggableView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SplitViewDragAndDrop.handleDrag(viewToDrag: ciaoDraggableView, identifier: "ciao_d&d", dataToTransfer: "Ciao!".data(using: .utf8))
        SplitViewDragAndDrop.handleDrag(viewToDrag: helloDraggableView, identifier: "hello_d&d", dataToTransfer: "Hello!".data(using: .utf8))
        SplitViewDragAndDrop.handleDrag(viewToDrag: alohaDraggableView, identifier: "aloha_d&d", dataToTransfer: "Aloha!".data(using: .utf8))
        
    }
    
}
