//
//  TaskListTableViewController.swift
//  CBLiteStarterApp
//
//  Created by Priya Rajagopal on 4/6/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import UIKit

class TaskListTableViewController:UITableViewController {
    
    var taskPresenter:TaskPresenter = TaskPresenter()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.updateUIWithAddButton()
        self.title = NSLocalizedString("Tasks", comment: "")
       
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.initialize()
        handleFetchDocumentsRequest()
       
    }
    

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.deinitialize()
    }
    

    
    private func updateUIWithAddButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddDocumentRequest))
    }
    
    
    private func initialize() {
        self.addAppActivatedNotification() // to be notified when app is activated
        self.taskPresenter.attachPresentingView(self)
        self.taskPresenter.databaseManager.startObservingDatabaseChanges(self)

    }
    
    private func deinitialize() {
        self.removeAppActivatedNotification()
        self.taskPresenter.detachPresentingView(self)
        self.taskPresenter.databaseManager.endObservingDatabaseChanges(self)
  
    }

}

// MARK:DatabaseManagerProtocol
extension TaskListTableViewController:DatabaseManagerProtocol {
      
    func onDatabaseUpdated() {
        // Refetch all documents
        handleFetchDocumentsRequest()
    }

    func onReplicationStatusUpdated(status:CBLReplicationStatus) {
        
    }
}

// MARK: PresentingViewProtocol
extension TaskListTableViewController:PresentingViewProtocol {
    public func dataStartedLoading() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    public func dataFinishedLoading() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

//MARK:UITableViewDataSource
extension TaskListTableViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int (self.taskPresenter.docsEnumerator?.count ?? 0)
    }
    
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell") else { return UITableViewCell.init()}
        if let queryRow = self.taskPresenter.docsEnumerator?.row(at: UInt(indexPath.row)) {
            if let userProps = queryRow.document?.userProperties ,let title = userProps[DocumentUserProperties.name.rawValue] as? String , let isDone = userProps[DocumentUserProperties.isCompleted.rawValue] as? Bool{
                cell.textLabel?.text = title
                if isDone == true {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                
                cell.selectionStyle = .default
                
            }
        }
        return cell
        
    }
    
    
}

//MARK: UITableViewDelegate
extension TaskListTableViewController {
    override public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [unowned self] (action, indexPath) in
            
            // remove document at index
            let row = indexPath.row
            self.taskPresenter.deleteDocumentAtIndex(row, handler: { (error) in
                switch error {
                    case nil:
                        print("Succesfuly deleted!")
                    default:
                        self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Failed to delete document:\(String(describing: error?.localizedDescription))", comment: ""))
               
                    
                }
            })
            
            
        })
        let editAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Edit", comment: ""), handler: { [unowned self] (action, indexPath) in
            
            let cell = tableView.cellForRow(at: indexPath)
            
            let alertController = UIAlertController(title: nil,
                                                    message: NSLocalizedString("Update Document", comment: ""),
                                                    preferredStyle: .alert)
            var docTitleTextField: UITextField!
            alertController.addTextField(configurationHandler: { (textField) in
                textField.text = cell?.textLabel?.text
                docTitleTextField = textField
            })
            
            let isCompleted = cell?.accessoryType == UITableViewCellAccessoryType.checkmark ? true:false
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Update", comment: ""), style: .default) { _ in
                // update document at index
                let row = indexPath.row
                let props = [DocumentUserProperties.name.rawValue:docTitleTextField.text ?? "",DocumentUserProperties.isCompleted.rawValue:isCompleted] as [String : Any]
                self.taskPresenter.updateDocumentAtIndex(row, properties: props,  handler: { (error) in
                    switch error {
                    case nil:
                        print("Succesfuly Updated!")
                     default:
                        self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Failed to updated document:\(String(describing: error?.localizedDescription))", comment: ""))
                        
                    }
                })

            })
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
                
            })
            self.present(alertController, animated: true, completion: nil)
            
            
        })
        return [deleteAction,editAction]
        
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = cell?.accessoryType == UITableViewCellAccessoryType.checkmark ? UITableViewCellAccessoryType.none:UITableViewCellAccessoryType.checkmark
        let isCompleted = cell?.accessoryType == UITableViewCellAccessoryType.checkmark ? true:false
        
        let row = indexPath.row
        let props = [DocumentUserProperties.name.rawValue:cell?.textLabel?.text ?? "",DocumentUserProperties.isCompleted.rawValue:isCompleted] as [String : Any]
        self.taskPresenter.updateDocumentAtIndex(row, properties: props,  handler: { (error) in
            switch error {
            case nil:
                print("Succesfuly Updated!")
                
            default:
                self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Failed to updated document:\(String(describing: error?.localizedDescription))", comment: ""))
                
                
            }
        })

        
    }
}

//MARK: UI Stuff
extension TaskListTableViewController {
    func handleFetchDocumentsRequest() {
        self.taskPresenter.getAllDocumentsInDatabase(handler: { (error) in
            switch error {
            case nil:
                print("Succesfuly fetched docs!")
                self.tableView.reloadData()
                
            default:
                print("Errror when fetching documents on app activcation \(String(describing: error?.localizedDescription))")
                
            }
        })
    }
    func handleAddDocumentRequest() {
        var docNameTextField:UITextField!
        
        let alertController = UIAlertController(title: nil,
                                                message: NSLocalizedString("Add Document", comment: ""),
                                                preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Enter Document Name", comment: "")
            docNameTextField = textField
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { _ in
            guard let _ = docNameTextField.text else {
                return
            }
            let props = [DocumentUserProperties.name.rawValue:docNameTextField.text ?? "",DocumentUserProperties.isCompleted.rawValue:false] as [String : Any]
            self.taskPresenter.createDocumentWithProperties(props, handler: { (error) in
                switch error {
                case nil:
                    print("Succesfuly Created!")
                    self.tableView.reloadData()
                default:
                    self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Failed to create document:\(String(describing: error?.localizedDescription))", comment: ""))
                    
                }
            })
            
            
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
            
        })
        self.present(alertController, animated: true, completion: nil)
        
    }
}

// MARK : App Life cycle notifications
extension TaskListTableViewController {
    fileprivate func addAppActivatedNotification() {
        
        // 1. iOS Specific. Add observer to the NOtification Center to observe app notification changes when it comes to foreground
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) {
            [weak self] (notification) in
            self?.handleFetchDocumentsRequest()
           
        }
        
    }

    fileprivate func removeAppActivatedNotification() {
        // 1. iOS Specific. Remove observer from db state changes
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
}



