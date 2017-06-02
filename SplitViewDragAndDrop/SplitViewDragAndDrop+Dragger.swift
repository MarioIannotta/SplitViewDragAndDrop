//
//  SplitViewDragAndDrop+Dragger.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

extension SplitViewDragAndDrop {
    
    internal class Dragger: NSObject {
        
        private struct StoreKeys {
            
            static let draggingValidation = "storeKeysDraggingValidation"
            
            struct DraggingValidation {
                
                static let result = "storeKeysDraggingValidationResult"
                static let initialDragPoint = "storeKeysDraggingValidationInitialDragPoint"
                
            }
            
        }
        
        private var dragAndDropManager: SplitViewDragAndDrop
        
        private var initialDragPoint: CGPoint!
        private var viewToDragSnapshotImageView = UIImageView(frame: CGRect.zero)
        private var updateTriggered = false
        private var updateTriggeredToRight = false
        
        private var dataToTransfers = [UIView: Data]()
        private var identifiers = [UIView: String]()
        
        internal var draggingEndedClosure: ((_ isValid: Bool) -> Void)?
        
        internal init(dragAndDropManager: SplitViewDragAndDrop) {
            self.dragAndDropManager = dragAndDropManager
            
            super.init()
            dragAndDropManager.groupDefaults.addObserver(self, forKeyPath: StoreKeys.draggingValidation, options: .new, context: nil)
        }
        
        func notifyDraggingValidationResult(_ result: Bool, initialDragPoint: CGPoint) {
            
            let draggingValidationDictionary: [String: Any] = [
                StoreKeys.DraggingValidation.result: result,
                StoreKeys.DraggingValidation.initialDragPoint: initialDragPoint
            ]
            dragAndDropManager.groupDefaults.set(NSKeyedArchiver.archivedData(withRootObject: draggingValidationDictionary), forKey: StoreKeys.draggingValidation)
            dragAndDropManager.groupDefaults.synchronize()
            
        }
        
        deinit {
            
            dragAndDropManager.groupDefaults.removeObserver(self, forKeyPath: StoreKeys.draggingValidation)
            
        }
        
        private func setupViewToDragSnapshotImageView(from view: UIView, centerPoint: CGPoint) {
            
            let image = view.getSnapshot()
            
            viewToDragSnapshotImageView.frame = view.frame
            viewToDragSnapshotImageView.center = centerPoint
            viewToDragSnapshotImageView.image = image
            
            UIApplication.shared.keyWindow?.addSubview(viewToDragSnapshotImageView)
            
        }
        
        internal func handleDrag(viewToDrag: UIView, identifier: String, dataToTransfer: Data? = nil) {
            
            viewToDrag.addGestureRecognizer(
                UIPanGestureRecognizer(target: self, action: #selector(handleGestureRecognizer(_:)))
            )
            
            self.dataToTransfers[viewToDrag] = dataToTransfer
            self.identifiers[viewToDrag] = identifier
            
        }
        
        @objc private func handleGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
            
            guard
                let draggedView = gestureRecognizer.view,
                let keyWindow = UIApplication.shared.keyWindow
                else { return }
            
            let dragPoint = gestureRecognizer.location(in: keyWindow)
            
            switch gestureRecognizer.state {
                
            case .began:
                
                initialDragPoint = dragPoint
                updateTriggered = false
                updateTriggeredToRight = false
                
                setupViewToDragSnapshotImageView(from: draggedView, centerPoint: dragPoint)
                
                if let viewToDragSnapshotImage = viewToDragSnapshotImageView.image {
                    
                    dragAndDropManager.prepareForDraggingUpdate(
                        identifier: identifiers[draggedView] ?? "",
                        viewToDragSnapshotImage: viewToDragSnapshotImage,
                        dataToTransfer: dataToTransfers[draggedView]
                    )
                    
                }
                
                dragAndDropManager.notifyGestureRecognizerUpdate(state: .began, isTriggeredToRight: updateTriggeredToRight)
                
            case .ended:
                
                if !updateTriggered {
                    SplitViewDragAndDrop.completeDragging(isFallBack: true, draggingView: self.viewToDragSnapshotImageView, targetCenterPoint: self.initialDragPoint, completion: nil)
                }
                
                dragAndDropManager.notifyGestureRecognizerUpdate(state: .ended, isTriggeredToRight: updateTriggeredToRight)
                
            default:
                
                let isToRight = gestureRecognizer.velocity(in: keyWindow).x > 0
                viewToDragSnapshotImageView.center = dragPoint
                
                let shouldTriggerUpdate = isToRight ?
                    viewToDragSnapshotImageView.frame.origin.x + viewToDragSnapshotImageView.frame.size.width >= UIWindow.width :
                    viewToDragSnapshotImageView.frame.origin.x <= 0
                
                if updateTriggered || shouldTriggerUpdate {
                    
                    if updateTriggered == false {
                        updateTriggeredToRight = isToRight
                    }
                    
                    updateTriggered = true
                    
                    let frame = CGRect(
                        x: SplitViewDragAndDrop.transformXCoordinate(viewToDragSnapshotImageView.frame.origin.x, updateTriggeredToRight: updateTriggeredToRight),
                        y: viewToDragSnapshotImageView.frame.origin.y,
                        width: viewToDragSnapshotImageView.frame.size.width,
                        height: viewToDragSnapshotImageView.frame.size.height
                    )
                    
                    var initialDragPoint = self.initialDragPoint ?? .zero
                    initialDragPoint.x = SplitViewDragAndDrop.transformXCoordinate(initialDragPoint.x, updateTriggeredToRight: updateTriggeredToRight)
                    
                    dragAndDropManager.notifyDraggingUpdate(frame: frame, initialDragPoint: initialDragPoint)
                    
                }
                
                dragAndDropManager.notifyGestureRecognizerUpdate(state: .changed, isTriggeredToRight: updateTriggeredToRight)
                
            }
            
        }
        
        internal override func observeValue(
            forKeyPath keyPath: String?, of object: Any?,
            change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
            guard let keyPath = keyPath, let changedData = change?[.newKey] as? Data else { return }
            
            switch keyPath {
                
            case StoreKeys.draggingValidation:
                
                if
                    let draggingValidation = NSKeyedUnarchiver.unarchiveObject(with: changedData) as? [String: Any],
                    let validationResult = draggingValidation[StoreKeys.DraggingValidation.result] as? Bool, validationResult == false,
                    let initialDragPoint = draggingValidation[StoreKeys.DraggingValidation.initialDragPoint] as? CGPoint, initialDragPoint.x > 0, initialDragPoint.x < UIWindow.width
                {
                    
                    SplitViewDragAndDrop.completeDragging(isFallBack: true, draggingView: self.viewToDragSnapshotImageView, targetCenterPoint: initialDragPoint, completion: nil)
                    
                    dragAndDropManager.groupDefaults.removeObject(forKey: StoreKeys.draggingValidation)
                    
                }
                
            default:
                break
                
            }
            
        }
    
    }
    
}
