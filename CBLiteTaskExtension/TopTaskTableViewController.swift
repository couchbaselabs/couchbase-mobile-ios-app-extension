//
//  TopTaskTableViewController.swift
//  CBLiteTaskExtension
//
//  Created by Priya Rajagopal on 4/19/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import UIKit
import NotificationCenter

class TopTaskTableViewController: UITableViewController, NCWidgetProviding {
    
    @IBOutlet weak var taskLabel: UILabel!
    fileprivate var taskPresenter:TaskPresenter = TaskPresenter()
    fileprivate let topNTasks:UInt = 2
    var initialized:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 44.0
        print("taskPresenter is \(taskPresenter)")
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(#function)
        self.initializeTaskPresenter()
        self.taskPresenter.getAllDocumentsInDatabase(handler: { [unowned self](error) in
            switch error {
            case nil:
                print("Succesfuly Updated!")
                self.tableView.reloadData()
                self.updatePreferredContentSize()

                
            default:
                print("Error in fetching documents:\(String(describing: error?.localizedDescription))")
                
                
            }
        })
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        print(#function)
        super.viewDidDisappear(animated)
        self.deinitializeTaskPresenter()

    }
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        print(#function)
         
        self.initializeTaskPresenter()
        self.taskPresenter.getAllDocumentsInDatabase(handler: { [unowned self] (error) in
            switch error {
            case nil:
                print("Succesfuly Updated!")
                self.tableView.reloadData()
                self.updatePreferredContentSize()
                 completionHandler(NCUpdateResult.newData)
                
            default:
                print("Error in fetching documents:\(String(describing: error?.localizedDescription))")
                 completionHandler(NCUpdateResult.noData)
            
                
            }
        })
       
 
    }
    
   
    private func updatePreferredContentSize() {
        preferredContentSize = CGSize(width: CGFloat(0), height: CGFloat(tableView(tableView, numberOfRowsInSection: 0)) * CGFloat(tableView.rowHeight) + tableView.sectionFooterHeight)
        
        
    }
    
    
    private func initializeTaskPresenter() {
        if initialized == true
        {
            return
        }
        self.taskPresenter.attachPresentingView(self)
        self.taskPresenter.databaseManager.startObservingDatabaseChanges(self)
        self.taskPresenter.databaseManager.startPushAndPullReplication()
        initialized = true
     }
    
    private func deinitializeTaskPresenter() {
        if initialized == false
        {
            return
        }
        self.taskPresenter.detachPresentingView(self)
        self.taskPresenter.databaseManager.endObservingDatabaseChanges(self)
        self.taskPresenter.databaseManager.stopAllReplications()
        initialized = false
    }

}



//MARK:DatabaseManagerProtocol
extension TopTaskTableViewController:DatabaseManagerProtocol {
   
    func onDatabaseUpdated() {
        self.taskPresenter.getAllDocumentsInDatabase(handler: { (error) in
            switch error {
            case nil:
                print("Succesfuly Updated!")
                self.tableView.reloadData()
                
            default:
               print("Error in fetching documents\(String(describing: error?.localizedDescription))")
               
            }
        })
    }
    
 
        
    func onReplicationStatusUpdated(status:CBLReplicationStatus) {
            
    }
    

    
}

// MARK: PresentingViewProtocol
extension TopTaskTableViewController:PresentingViewProtocol {
    // override default impl
    func showAlertWithTitle(_ title:String?, message:String) {
        print(#function)
        //noop
    }
    func showSuccessAlertWithTitle(_ title:String?, message:String) {
        print(#function)
        //noop
    }
}

// MARK: UITableViewDelegate
extension TopTaskTableViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.taskPresenter.docsEnumerator?.count {
            // Just show upto top topNTasks tasks
            return count > topNTasks ? Int(topNTasks): Int(count)
        }
        return 0
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") else { return UITableViewCell.init()}
        
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
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let count = self.taskPresenter.docsEnumerator?.count else {
            print("Something very odd!!")
            return
        }
        
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
              print("Failed to update")
                
                
            }
        })
        
    }

}
