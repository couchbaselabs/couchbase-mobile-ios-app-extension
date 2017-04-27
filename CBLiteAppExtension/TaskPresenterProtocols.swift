//
//  TaskPresenterProtocols.swift
//  CBLiteAppExtension
//
//  Created by Priya Rajagopal on 4/22/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation

//  Task  Presenters must implement this protocol
protocol TaskPresenterProtocol:PresenterProtocol {
    
    var databaseManager:DatabaseManager {get }
    
    var docsEnumerator:CBLQueryEnumerator? {get}
    
    // Retrieve all documents in the database
    func getAllDocumentsInDatabase(handler:@escaping (_ error:Error?)->Void)
    
    // Create a document with specified user properties
    func createDocumentWithProperties(_ properties:[String:Any], handler:@escaping (_ error:Error?)->Void)
    
    // Update a document at index with updated user properties. Existing user properties will be replaced with specified ones.Index corresponds to a row of objects returned by CBLQuery
    func updateDocumentAtIndex(_ index:Int, properties:[String:Any], handler:@escaping (_ error:Error?)->Void)
    
    // Delete Document at specified index. Index corresponds to a row of objects returned by CBLQuery
    func deleteDocumentAtIndex(_ index:Int, handler:@escaping (_ error:Error?)->Void)
    
    
}


