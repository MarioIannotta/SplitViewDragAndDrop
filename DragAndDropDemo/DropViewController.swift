//
//  DropViewController.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

class DropViewController: UIViewController {
    
    @IBOutlet private weak var ciaoTargetImageView: UIImageView!
    @IBOutlet private weak var helloTargetImageView: UIImageView!
    @IBOutlet private weak var alohaTargetImageView: UIImageView!
    
    private func presentAlertController(withMessage message: String) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    private func draggingBeganAnimation(for view: UIView) {
        
        UIView.animate(withDuration: 0.3) {
            
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            
        }
        
    }
    
    private func draggingEndedAnimation(for view: UIView) {
        
        UIView.animate(withDuration: 0.3) {
            
            view.transform = CGAffineTransform.identity
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SplitViewDragAndDrop.addDropObserver(
            targetView: ciaoTargetImageView,
            identifier: "ciao_d&d",
            draggingBegan: { frame, draggedViewSnapshotImage, dataTransfered in
                
                self.draggingBeganAnimation(for: self.ciaoTargetImageView)
                
            },
            draggingValidation: { frame, draggedViewSnapshotImage, dataTransfered in
                
                self.draggingEndedAnimation(for: self.ciaoTargetImageView)
                
                return self.ciaoTargetImageView.windowRelativeFrame.contains(frame)
                
            },
            completion: { frame, draggedViewSnapshotImage, dataTransfered, isValid in
                
                if isValid {
                    self.ciaoTargetImageView.image = draggedViewSnapshotImage
                }
                
            }
        )
        
        SplitViewDragAndDrop.addDropObserver(
            targetView: helloTargetImageView,
            identifier: "hello_d&d",
            draggingBegan: { frame, draggedViewSnapshotImage, dataTransfered in
                
                self.draggingBeganAnimation(for: self.helloTargetImageView)
                
            },
            draggingValidation: { frame, draggedViewSnapshotImage, dataTransfered in
                
                self.draggingEndedAnimation(for: self.helloTargetImageView)
                return self.helloTargetImageView.windowRelativeFrame.contains(frame)
                
            },
            completion: { frame, draggedViewSnapshotImage, dataTransfered, isValid in
                
                if isValid {
                    self.helloTargetImageView.image = draggedViewSnapshotImage
                }
                
            }
        )
        
        SplitViewDragAndDrop.addDropObserver(
            targetView: alohaTargetImageView,
            identifier: "aloha_d&d",
            draggingBegan: { frame, draggedViewSnapshotImage, dataTransfered in
                
                self.draggingBeganAnimation(for: self.alohaTargetImageView)
                
            },
            draggingValidation: { frame, draggedViewSnapshotImage, dataTransfered in
                
                self.draggingEndedAnimation(for: self.alohaTargetImageView)
                return self.alohaTargetImageView.windowRelativeFrame.contains(frame)
                
            },
            completion: { frame, draggedViewSnapshotImage, dataTransfered, isValid in
                
                if isValid {
                    self.alohaTargetImageView.image = draggedViewSnapshotImage
                }
                
            }
        )
        
    }
    
}
