//
//  TaskPresenter.swift
//  CBLiteAppExtension
//
//  Created by Priya Rajagopal on 4/22/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation


enum DocumentUserProperties:String {
    case name = "name"
    case isCompleted = "isCompleted"
    case createdOn = "createdOn"
}

class TaskPresenter {
    
    fileprivate var _docsEnumerator:CBLQueryEnumerator?
    
    fileprivate var _attachedView:PresentingViewProtocol?
    
    fileprivate var _dbManager:DatabaseManager = DatabaseManager.shared
    
    
    init() {
 
    }
    
    deinit {
    }
    
}

// MARK: TaskPresenterProtocol

extension TaskPresenter:TaskPresenterProtocol {
    
    var databaseManager:DatabaseManager {
        get {
            return _dbManager
        }
    }


    var docsEnumerator:CBLQueryEnumerator? {
        get {
            return _docsEnumerator
        }
    
    }

     
    // Fetches all documents in Database
    func getAllDocumentsInDatabase(handler:@escaping (_ error:Error?)->Void) {
        do {
            
            // 1. Create Query to fetch all documents. You can set a number of properties on the query object
            guard let query = self._dbManager.db?.createAllDocumentsQuery() else {
                handler( NSError(domain: "", code: 1001, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("Task Presenter Not Initialized", comment: "")]))
                return
            }
            
            
            // 2: You can optionally set a number of properties on the query object.
            // Explore other properties on the query object
            query.limit = UInt(UINT32_MAX) // All documents 
            let keyPath = "document.userProperties.\(DocumentUserProperties.createdOn.rawValue)"
            query.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: false)]
            
            //   query.postFilter =
            
            
            // 5: Run the query to fetch documents asynchronously
            query.runAsync({ (enumerator, error) in
                switch error {
                case nil:
                    // 6: The "enumerator" is of type CBLQueryEnumerator and is an enumerator for the results
                    self._docsEnumerator = enumerator
                    handler(nil)
                    
                default:
                    print("Failed to fetch documents \( error.localizedDescription)")
                    handler(error)
                }
            })
        }
        catch {
            print("Failed to fetch documents \(error.localizedDescription)")
            handler( error)
        }
    }
    
    
   
    
    // Creates a Document in database
    func createDocumentWithProperties(_ properties:[String:Any], handler:@escaping (_ error:Error?)->Void){
        do {
            // 1: Create Document with unique Id
            let name = properties[DocumentUserProperties.name.rawValue] ?? ""
            let isCompleted = properties[DocumentUserProperties.isCompleted.rawValue] ?? false
            
            let doc = self.databaseManager.db?.createDocument()
            
            // 2: Construct user properties Object
            let userProps = [DocumentUserProperties.name.rawValue:name,DocumentUserProperties.isCompleted.rawValue:isCompleted,DocumentUserProperties.createdOn.rawValue:Date.init().timeIntervalSince1970]
            
            // 3: Add a new revision with specified user properties
            let _ = try doc?.putProperties(userProps)
            
            handler(nil)
            
        }
        catch  {
            handler( error)
            
        }
    }
      
    func updateDocumentAtIndex(_ index:Int, properties:[String:Any], handler:@escaping (_ error:Error?)->Void) {
        do {
            // 1. Get the CBLQueryRow object at specified index
            let queryRow = self._docsEnumerator?.row(at: UInt(index))
            
            
            // 2: Get the document associated with the row
            guard let doc = queryRow?.document else{
                handler( NSError(domain: "", code: 1002, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("Document Not Available At Index", comment: "")]))
                return
            }
            
            // 3: Create a mutable copy of user properties
            var userProps = properties
            
            
            // 4: If a previous revision of document exists, make sure to specify that. SInce its an update, it should exist!
            if let revId = doc.currentRevisionID  {
                
                userProps["_rev"] = revId
            }
            

            // 5: Add a new revision with specified user properties
            let _ = try doc.putProperties(userProps )

            handler(nil)
        }
        catch  {
            handler (error)
            
        }
        
        
        
    }
    func deleteDocumentAtIndex(_ index:Int, handler:@escaping (_ error:Error?)->Void) {
        do {
            // 1. Get the CBLQueryRow object at specified index
            let queryRow = self._docsEnumerator?.row(at: UInt(index))
            
            
            // 2: Get the document associated with the row
            let doc = queryRow?.document
            
            // 3: Delete the document
            try doc?.delete()
            
            handler(nil)
        }
        catch  {
            handler (error)
            
        }
    }

}


extension TaskPresenter:PresenterProtocol {
    func attachPresentingView(_ view:PresentingViewProtocol) {
        self._attachedView = view
    }
    func detachPresentingView(_ view:PresentingViewProtocol) {
        self._attachedView = nil
    }

}


