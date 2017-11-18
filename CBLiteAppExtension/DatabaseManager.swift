//
//  DatabaseManager.swift
//  CBLiteAppExtension
//
//  Created by Priya Rajagopal on 4/27/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation

// View/view controller  associated with presenter must implement this protocol
protocol DatabaseManagerProtocol {
    
    func onDatabaseUpdated()
    func onReplicationStatusUpdated(status:CBLReplicationStatus)
}

class DatabaseManager {
    
    // public
    var db:CBLDatabase? {
        get {
            return _db
        }
    }
    
    // fileprivate
    fileprivate let kDBName:String = "demo"
    
    // This is the remote URL of the Sync Gateway (public Port)
    fileprivate let kRemoteSyncUrl = "http://localhost:4984"
    
    fileprivate var _cbManager:CBLManager?
    
    fileprivate var _db:CBLDatabase?
    
    fileprivate var _pullRepl:CBLReplication?
    
    fileprivate var _pushRepl:CBLReplication?
    
    fileprivate var _dbListeners:[NSValue:DatabaseManagerProtocol] = [:]
    
    
    static let shared:DatabaseManager = {
        let instance = DatabaseManager()
        instance.initialize()
        return instance
    }()
    
    func initialize() {
        if self.configureCBManagerForSharedData() == true {
            if self.openOrCreateDatabaseInSharedContainer() == true {
                // start observing database changes
                self.addDatabaseChangesObserver()
            }
            
        }
    }
    // Don't allow instantiation . Enforce singleton
    private init() {
      
    }
    
    deinit {
        // Stop observing changes to the database that affect the query
        do {
            try self._db?.close()
        }
        catch  {
            
        }
        self.removeDatabaseObserver()
        self.removeReplicationChangeObserver()
    }
    
    
}

// MARK: Public
extension DatabaseManager {
    // Sets up observer for notifying presenting view of changes
    func startObservingDatabaseChanges(_ listener:DatabaseManagerProtocol) {
        self._dbListeners[NSValue.init(nonretainedObject:listener)] = listener
    }
    
    // Removes databse changes observer
    func endObservingDatabaseChanges(_ listener:DatabaseManagerProtocol) {
        self._dbListeners.removeValue(forKey: NSValue.init(nonretainedObject:listener))
    }
    
    func startPushAndPullReplication() {
        self.startPushReplication()
        self.startPullReplication()
    }
    
    // Sets database sync/replication
    func startPushReplication() {
        // 1. Create a Pull replication to start pushing to remote source
        self.startDBPushReplication()
        
        // 2. Add Observer for push replicator changes
        if let _pushRepl = _pushRepl {
            self.addReplicationChangeObserverForReplicator(_pushRepl)
        }
        
    }
    
    // Sets database sync/replication
    func startPullReplication() {
        // 1. Create a Pull replication to start pulling from remote source
        self.startDBPullReplication()
        
        // 2. Add Observer for pull replicator changes
        if let _pullRepl = _pullRepl {
            self.addReplicationChangeObserverForReplicator(_pullRepl)
        }

    }

    
    // Stops database sync/replication
    func stopAllReplications() {
        stopPullReplication()
        stopPushReplication()
    }

    // stop Push Replication
    func stopPushReplication() {
         _pushRepl?.stop()
    }
    
    // stop Pull Replication
    func stopPullReplication() {
         _pullRepl?.stop()
    }
    
}

extension DatabaseManager {
    
    fileprivate func configureCBManagerForSharedData() -> Bool {
        do {
            // 1. Set the file protection mode for the Couchbase Lite database folder
            let options = CBLManagerOptions(readOnly: false, fileProtection: Data.WritingOptions.completeFileProtectionUnlessOpen)
            let cblpoptions = UnsafeMutablePointer<CBLManagerOptions>.allocate(capacity: 1)
            cblpoptions.initialize(to: options)
            
            if let url = self.appGroupContainerURL() {
                // 2. Initialize the CBLManager with the directory of the shared container
                _cbManager = try CBLManager.init(directory: url.relativePath, options: cblpoptions)
                //self.enableCrazyLevelLogging()
            }
            
            return true
        }
        catch {
            return false
            
        }
    }
    
    
    
    // Creates a DB in local store if it does not exist
    fileprivate func openOrCreateDatabaseInSharedContainer()-> Bool {
        
        do {
            // 1: Set Database Options
            let options = CBLDatabaseOptions()
            options.storageType  = kCBLSQLiteStorage
            options.create = true
            
            // 2: Create a DB for logged in user if it does not exist else return handle to existing one
            _db  = try _cbManager?.openDatabaseNamed(kDBName.lowercased(), with: options)
            
            return true
        }
        catch  {
            return false
            
        }
    }
    
    private func enableCrazyLevelLogging() {
        CBLManager.enableLogging("Reachability")
        CBLManager.enableLogging("SyncVerbose")
        CBLManager.enableLogging("CBLDatabase")
        CBLManager.enableLogging("ChangeTrackerVerbose")
        CBLManager.enableLogging("RemoteRequest")

    }
    
}



// MARK: Internal
extension DatabaseManager {
    fileprivate  func appGroupContainerURL() -> URL? {
        // 1. Get URL to shared group container
        let fileManager = FileManager.default
        guard let groupURL = fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.CBLiteSharedData") else {
                return nil
        }
        
        let storagePathUrl = groupURL.appendingPathComponent("CBLite")
        let storagePath = storagePathUrl.path
        
        // 2: Create a folder in the shared container location with name"CBLite"
        if !fileManager.fileExists(atPath: storagePath) {
            do {
                try fileManager.createDirectory(atPath: storagePath,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
            } catch let error {
                print("error creating filepath: \(error)")
                return nil
            }
        }
        
        return storagePathUrl
    }
       
    
    fileprivate func addDatabaseChangesObserver() {
        
        // 1. iOS Specific. Add observer to the NOtification Center to observe db changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name.cblDatabaseChange, object: nil, queue: nil) {
            [weak self] (notification) in
            print(#function)
            for (_,v) in (self?._dbListeners)! {
                v.onDatabaseUpdated()
            }
        }
        
    }
    
    fileprivate func removeDatabaseObserver() {
        // 1. iOS Specific. Remove observer from db state changes
     
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.cblDatabaseChange, object: nil)
    }
    
   
    
    fileprivate func startDBPullReplication() {
        
        if (_pullRepl == nil) {
            // 1: Create a Pull replication to start pulling from remote source
            _pullRepl = _db?.createPullReplication(URL(string: self.kDBName.lowercased(), relativeTo: URL.init(string: kRemoteSyncUrl))!)
            
            // 2. Continuously look for changes
            _pullRepl?.continuous = true
            
            // Optionally, Set channels from which to pull
            // pullRepl?.channels = [...]
            
         }
        
        // 3. Start the pull replicator
        _pullRepl?.start()
        
    }
    
    fileprivate func startDBPushReplication() {
        
        if (_pushRepl == nil) {
        
            // 1: Create a push replication to start pushing to remote source
            _pushRepl = _db?.createPushReplication(URL(string: self.kDBName.lowercased(), relativeTo: URL.init(string:kRemoteSyncUrl))!)
            
            // 2. Continuously push  changes
            _pushRepl?.continuous = true
            
         }
        
        // 3. Start the push replicator
        _pushRepl?.start()
        
    }
    
    fileprivate func addReplicationChangeObserverForReplicator(_ replicator:CBLReplication) {
        
        // 1. iOS Specific. Add observer to the NOtification Center to observe replicator changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name.cblReplicationChange, object: replicator, queue: nil) {
            [weak self] (notification) in
            if replicator == self?._pushRepl && self?._pushRepl?.suspended == true {
                // In case of iOS App Extension, the replication suspends itself
             //  self?._pushRepl?.suspended = false
            }
            if replicator == self?._pullRepl && self?._pullRepl?.suspended == true {
                 // In case of iOS App Extension, the replication suspends itself 
              //  self?._pullRepl?.suspended = false
            }
            
        }
        
    }
    
    fileprivate func removeReplicationChangeObserver() {
        // 1. iOS Specific. Remove observer from Replication state changes
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.cblReplicationChange, object: nil)
        
    }
    
    
}

