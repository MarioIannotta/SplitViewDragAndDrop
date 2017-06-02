//
//  SplitViewDragAndDrop.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

class SplitViewDragAndDrop: NSObject {
    
    private struct StoreKeys {
        
        static let position = "storeKeysPosition"
        static let info = "storeKeysInfo"
        static let gestureRecognizer = "storeKeysGestureRecognizer"
        
        struct Position {
            static let frame = "storeKeysPositionFrame"
            static let initialDragPoint = "storeKeysPositionInitialDragPoint"
        }
        
        struct Info {
            static let dragAndDropIdentifier = "storeKeysInfoDragAndDropIdentifier"
            static let viewToDragSnapshotImage = "storeKeysInfoViewToDragSnapshotImage"
            static let dataToTransfer = "storeKeysInfoDataToTransfer"
        }
        
        struct GestureRecognizer {
            static let state = "storeKeysGestureRecognizerState"
            static let isTriggeredToRight = "storeKeysGestureRecognizerIsTriggeredToRight"
        }
        
    }
    
    typealias DraggingUpdateClosure = (_ frame: CGRect, _ image: UIImage?, _ data: Data?) -> Void
    typealias DraggingValidationClosure = (_ frame: CGRect, _ image: UIImage?, _ data: Data?) -> Bool
    typealias DraggingCompletionClosure = (_ frame: CGRect, _ image: UIImage?, _ data: Data?, _ isValid: Bool) -> Void
    
    private static var shared: SplitViewDragAndDrop!
    
    internal var groupDefaults: UserDefaults
    private var dragger: Dragger!
    
    private init(groupIdentifier: String) {
        groupDefaults = UserDefaults(suiteName: groupIdentifier)!
    }
    
    private var draggingUpdateClosures = [String: DraggingUpdateClosure]()
    private var draggingBeganClosures = [String: DraggingUpdateClosure]()
    private var draggingValidationClosures = [String: DraggingValidationClosure]()
    private var draggingCompletionClosures = [String: DraggingCompletionClosure]()
    private var draggingTargetViews = [String: UIView]()
    private var dataToTransfers = [String: Data]()
    
    private var initialDragPoint = CGPoint.zero
    private var viewToDragSnapshotImage: UIImage?
    private var draggingViewFrame: CGRect?
    private var draggingBeganClosureCalled = false
    
    private var draggingUpdateClosure: DraggingUpdateClosure? {
        get { return draggingUpdateClosures[currentIdentifier] }
        set { draggingUpdateClosures[currentIdentifier] = newValue }
    }
    
    internal var currentIdentifier = ""
    
    internal var draggingBeganClosure: DraggingUpdateClosure? {
        get { return draggingBeganClosures[currentIdentifier] }
        set { draggingBeganClosures[currentIdentifier] = newValue }
    }
    internal var draggingValidationClosure: DraggingValidationClosure? {
        get { return draggingValidationClosures[currentIdentifier] }
        set { draggingValidationClosures[currentIdentifier] = newValue }
    }
    internal var draggingCompletionClosure: DraggingCompletionClosure? {
        get { return draggingCompletionClosures[currentIdentifier] }
        set { draggingCompletionClosures[currentIdentifier] = newValue }
    }
    internal var draggingTargetView: UIView? {
        get { return draggingTargetViews[currentIdentifier] }
        set { draggingTargetViews[currentIdentifier] = newValue }
    }
    internal var dataToTransfer: Data? {
        get { return dataToTransfers[currentIdentifier] }
        set { dataToTransfers[currentIdentifier] = newValue }
    }
    
    internal var viewToDragSnapshotImageView = UIImageView()
    
    internal func prepareForDraggingUpdate(identifier: String, viewToDragSnapshotImage: UIImage, dataToTransfer: Data?) {
        
        var draggingUpdateDictionary: [String: Any] = [
            StoreKeys.Info.dragAndDropIdentifier: identifier,
            StoreKeys.Info.viewToDragSnapshotImage: viewToDragSnapshotImage
        ]
        
        if let dataToTransfer = dataToTransfer {
            draggingUpdateDictionary[StoreKeys.Info.dataToTransfer] = dataToTransfer
        }
        
        groupDefaults.set(NSKeyedArchiver.archivedData(withRootObject: draggingUpdateDictionary), forKey: StoreKeys.info)
        groupDefaults.synchronize()
        
    }
    internal func notifyDraggingUpdate(frame: CGRect, initialDragPoint: CGPoint) {
        
        let draggingUpdateDictionary: [String: Any] = [
            StoreKeys.Position.frame: frame,
            StoreKeys.Position.initialDragPoint: initialDragPoint
        ]
        
        groupDefaults.set(NSKeyedArchiver.archivedData(withRootObject: draggingUpdateDictionary), forKey: StoreKeys.position)
        groupDefaults.synchronize()
        
    }
    internal func notifyGestureRecognizerUpdate(state: UIGestureRecognizerState, isTriggeredToRight: Bool) {
        
        let gestureRecognizerDictionary: [String: Any] = [
            StoreKeys.GestureRecognizer.state: state.rawValue,
            StoreKeys.GestureRecognizer.isTriggeredToRight: isTriggeredToRight
        ]
        
        groupDefaults.set(NSKeyedArchiver.archivedData(withRootObject: gestureRecognizerDictionary), forKey: StoreKeys.gestureRecognizer)
        groupDefaults.synchronize()
        
    }
    
    internal func observeDraggingUpdate(onDragUpdate: @escaping DraggingUpdateClosure) {
        
        draggingUpdateClosure = onDragUpdate
        
        groupDefaults.addObserver(self, forKeyPath: StoreKeys.position, options: .new, context: nil)
        groupDefaults.addObserver(self, forKeyPath: StoreKeys.info, options: .new, context: nil)
        groupDefaults.addObserver(self, forKeyPath: StoreKeys.gestureRecognizer, options: .new, context: nil)
        
    }
    
    deinit {
        
        groupDefaults.removeObserver(self, forKeyPath: StoreKeys.position)
        groupDefaults.removeObserver(self, forKeyPath: StoreKeys.info)
        groupDefaults.removeObserver(self, forKeyPath: StoreKeys.gestureRecognizer)
        
    }
    
    internal static func transformXCoordinate(_ value: CGFloat, updateTriggeredToRight: Bool) -> CGFloat {
        
        return updateTriggeredToRight ? value - UIWindow.width : UIScreen.main.bounds.width - UIWindow.width + value
        
    }
    
    internal override func observeValue(
        forKeyPath keyPath: String?, of object: Any?,
        change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath, let changedData = change?[.newKey] as? Data else { return }
        
        switch keyPath {
            
        case StoreKeys.info:
            
            if let dragginInfoDictionary = NSKeyedUnarchiver.unarchiveObject(with: changedData) as? [String: Any] {
                
                viewToDragSnapshotImage = dragginInfoDictionary[StoreKeys.Info.viewToDragSnapshotImage] as? UIImage
                currentIdentifier = dragginInfoDictionary[StoreKeys.Info.dragAndDropIdentifier] as? String ?? ""
                dataToTransfer = dragginInfoDictionary[StoreKeys.Info.dataToTransfer] as? Data
                
            }
            
        case StoreKeys.position:
            
            if let dragginPositionDictionary = NSKeyedUnarchiver.unarchiveObject(with: changedData) as? [String: Any] {
                
                draggingViewFrame = dragginPositionDictionary[StoreKeys.Position.frame] as? CGRect ?? .zero
                initialDragPoint = dragginPositionDictionary[StoreKeys.Position.initialDragPoint] as? CGPoint ?? .zero
                draggingUpdateClosure?(draggingViewFrame ?? .zero, viewToDragSnapshotImage, dataToTransfer)
                
            }
            
        case StoreKeys.gestureRecognizer:
            
            if
                let draggingGestureRecognizer = NSKeyedUnarchiver.unarchiveObject(with: changedData) as? [String: Any],
                let draggingGestureRecognizerStateRawValue = draggingGestureRecognizer[StoreKeys.GestureRecognizer.state] as? Int,
                let draggingGestureRecognizerState = UIGestureRecognizerState(rawValue: draggingGestureRecognizerStateRawValue),
                let draggingGestureRecognizerIsTriggerToRight = draggingGestureRecognizer[StoreKeys.GestureRecognizer.isTriggeredToRight] as? Bool
                
            {
                
                switch draggingGestureRecognizerState {
                    
                case .began:
                    
                    if draggingBeganClosureCalled == false {
                        draggingBeganClosure?(draggingViewFrame ?? .zero, viewToDragSnapshotImage, dataToTransfer)
                        draggingBeganClosureCalled = true
                    }
                    
                case .ended:
                    
                    draggingBeganClosureCalled = false
                    
                    let draggingValidationResult = draggingValidationClosure?(draggingViewFrame ?? .zero, viewToDragSnapshotImage, dataToTransfer) ?? false
                    
                    var initialPoint = self.initialDragPoint
                    initialPoint.x = SplitViewDragAndDrop.transformXCoordinate(initialPoint.x, updateTriggeredToRight: !draggingGestureRecognizerIsTriggerToRight)
                    
                    dragger.notifyDraggingValidationResult(draggingValidationResult, initialDragPoint: initialPoint)
                    
                    if draggingViewFrame?.origin.x != 0 && draggingViewFrame?.origin.y != 0 {
                        
                        if draggingValidationResult {
                            
                            SplitViewDragAndDrop.completeDragging(
                                isFallBack: false,
                                draggingView: viewToDragSnapshotImageView,
                                targetCenterPoint: draggingTargetView?.windowRelativeFrame.center ?? .zero) {
                                    
                                    self.draggingCompletionClosure?(
                                        self.draggingViewFrame ?? .zero,
                                        self.viewToDragSnapshotImage,
                                        self.dataToTransfer,
                                        true
                                    )
                                    
                            }
                            
                        } else {
                            
                            SplitViewDragAndDrop.completeDragging(
                                isFallBack: true,
                                draggingView: viewToDragSnapshotImageView,
                                targetCenterPoint: initialDragPoint) {
                                    
                                    self.draggingCompletionClosure?(
                                        self.draggingViewFrame ?? .zero,
                                        self.viewToDragSnapshotImage,
                                        self.dataToTransfer,
                                        false
                                    )
                                    
                            }
                            
                        }
                        
                    }
                    
                    groupDefaults.removeObject(forKey: StoreKeys.gestureRecognizer)
                    groupDefaults.removeObject(forKey: StoreKeys.info)
                    groupDefaults.removeObject(forKey: StoreKeys.position)
                    
                default:
                    break
                    
                }
                
            }
            
        default:
            break
            
        }
        
    }
    
    internal static func completeDragging(isFallBack: Bool, draggingView: UIView, targetCenterPoint: CGPoint, completion: (() -> Void)?) {
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                draggingView.alpha = isFallBack ? 0 : 1
                draggingView.center = targetCenterPoint
            },
            completion: {  _ in
                draggingView.alpha = 1
                draggingView.removeFromSuperview()
                completion?()
            }
        )
        
    }
    
    private func refreshViewToDragSnapshotImageView(frame: CGRect, draggedViewSnapshot: UIImage?) {
        
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        
        viewToDragSnapshotImageView.frame = frame
        
        if !viewToDragSnapshotImageView.isDescendant(of: keyWindow) { // first time
            viewToDragSnapshotImageView.image = draggedViewSnapshot
            keyWindow.addSubview(viewToDragSnapshotImageView)
        }
        
    }
    
    // MARK: - Public interface
    
    open static func configure(groupIdentifier: String) {
        
        shared = SplitViewDragAndDrop(groupIdentifier: groupIdentifier)
        
        shared.dragger = Dragger(dragAndDropManager: shared)
        
    }
    
    open static func handleDrag(viewToDrag: UIView, identifier: String, dataToTransfer: Data? = nil) {
        
        shared.dragger.handleDrag(viewToDrag: viewToDrag, identifier: identifier, dataToTransfer: dataToTransfer)
        
    }
    
    open static func addDropObserver(
        targetView: UIView,
        identifier: String,
        draggingBegan: DraggingUpdateClosure?,
        draggingValidation: @escaping DraggingValidationClosure,
        completion: @escaping DraggingCompletionClosure) {
        
        DispatchQueue.main.async {
            
            shared.currentIdentifier = identifier
            
            shared.draggingTargetView = targetView
            shared.draggingBeganClosure = draggingBegan
            shared.draggingValidationClosure = draggingValidation
            shared.draggingCompletionClosure = completion
            
            shared.observeDraggingUpdate { frame, image, dataTransfered in
                
                shared.refreshViewToDragSnapshotImageView(frame: frame, draggedViewSnapshot: image)
                
            }
            
        }
        
    }
   
    open static func removeDropObserver(withIdentifier identifier: String) {
        
        shared.dataToTransfers.removeValue(forKey: identifier)
        shared.draggingUpdateClosures.removeValue(forKey: identifier)
        shared.draggingValidationClosures.removeValue(forKey: identifier)
        
    }
    
}
