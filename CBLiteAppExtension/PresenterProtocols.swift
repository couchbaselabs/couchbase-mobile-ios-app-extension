//
//  PresenterProtocols.swift
//  CBLiteAppExtension
//
//  Created by Priya Rajagopal on 4/22/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation
import UIKit

// MVP pattern
// The View COntroller or view that handles presentation of data must implement this protocol
protocol PresentingViewProtocol: class {
    func dataStartedLoading()
    func dataFinishedLoading()
    func showErrorAlertWithTitle(_ title:String?, message:String)
    func showSuccessAlertWithTitle(_ title:String?, message:String)
}

// All Presenters must implement this protocol
protocol PresenterProtocol: class {
    func attachPresentingView(_ view:PresentingViewProtocol)
    func detachPresentingView(_ view:PresentingViewProtocol)
}

// default implementation of INVPresentingViewProtocol
extension PresentingViewProtocol {
    public func dataStartedLoading() {
        //noop
    }
    public func dataFinishedLoading() {
        //noop
    }
    
}

// implementation of INVPresentingViewProtocol only in cases where the presenting view is a UIViewController
extension PresentingViewProtocol where Self:UIViewController {
    
    func showErrorAlertWithTitle(_ title:String?, message:String) {
        
        let alertController = UIAlertController(title: title ?? "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .default) { (result : UIAlertAction) -> Void in
            
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showSuccessAlertWithTitle(_ title:String?, message:String) {
        
        let alertController = UIAlertController(title: title ?? "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .default) { (result : UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: {
                
            })
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
