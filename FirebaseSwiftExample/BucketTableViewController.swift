//
//  BucketTableViewController.swift
//  FirebaseSwiftExample
//
//  Created by Collier, Jeff on 12/22/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import FirebaseAuth
import FirebaseFirestore

class BucketTableViewController: UITableViewController {
    
    // A reference to the remote Firebase database which also handles local persistence when offline
    var ref: CollectionReference?
    var query: Query?
    var listener: ListenerRegistration?

    // A reference to my utlity class for managing a local cache (array) of snapshots for the remote Firebase database
    var snapshotsController = FirebaseSnapshotsController()
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        // Set the logo
        let imageView = UIImageView(image: UIImage(named: "AppTitleBarLogo"))
        imageView.contentMode =  .scaleAspectFill
        navigationItem.titleView = imageView
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140
        
        // Obtain a database reference to bucket list for the signed-in user
        guard let user = Auth.auth().currentUser else { return }
        ref = Firestore.firestore().collection("users/\(user.uid)/bucketlists")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Synchronize the table view with the (empty) data source (local cache of snapshots) before adding initial data into the data source
        tableView.reloadData()
        
        // For a static list, use .getDocuments(completion: <#T##FIRQuerySnapshotBlock##FIRQuerySnapshotBlock##(QuerySnapshot?, Error?) -> Void#>)
        // for document in querySnapshot!.documents
        // document.documentID, data(), map, type
        // func data() -> [String : Any] which is an NSDictionary
        
        listener = ref?.order(by: "priority").addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            if let error = error {
                print("Error retreiving collection: \(error)")
                return
            }
            snapshot.documentChanges.forEach { docChange in
                if (docChange.type == .added) {
                    if let index = self.snapshotsController.append(docChange.document) {
                        let indexPath = IndexPath(row: index, section: 0)
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
                if (docChange.type == .modified) {
                    // If the change happened in place
                    if (docChange.oldIndex == docChange.newIndex) {
                        print("Change in place")
                        if let index = self.snapshotsController.replace(docChange.document) {
                            let indexPath = IndexPath(row: index, section: 0)
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                        }
                    }
                    // Otherwise, the order changed
                    else {
                        print("Change with oldIndex=\(docChange.oldIndex) and newIndex=\(docChange.newIndex)")
                        /* TODO:
                         let fromIndex = self.snapshotsController.indexOf(snapshot) ?? 0
                        print("The idea with name = \((snapshot.value as? NSDictionary)?.value(forKey: "name") ?? "No Name") and priority = \(snapshot.priority ?? -1) moved from \(fromIndex)")
                        
                        let previousIndex = self.snapshotsController.indexOf(byKey: previousKey) ?? -1
                        // If moving to the beginning, to=0. If moving left, to will be after previous sibling. Otherwise, to will replace previous sibling
                        let toIndex = (previousIndex == -1) ? 0 : (previousIndex < fromIndex) ? (previousIndex + 1) : previousIndex
                        print("The new position follows index = \(previousIndex) requiring a new index = \(toIndex)")
                        
                        if let _ = self.snapshotsController.move(from: fromIndex, to: toIndex) {
                            let lowerIndex = (fromIndex <= toIndex) ? fromIndex : toIndex
                            let upperIndex = (fromIndex <= toIndex) ? toIndex : fromIndex
                            var reloadRowsIndexes: [IndexPath] = []
                            for index in lowerIndex...upperIndex {
                                reloadRowsIndexes.append(IndexPath(row:index, section: 0))
                            }
                            print("That idea moved from index = \(fromIndex) to index = \(toIndex), requiring table rows in this range to be reloaded: \(lowerIndex)...\(upperIndex)")
                            self.tableView.reloadRows(at: reloadRowsIndexes, with: .automatic)
                            self.tableView.scrollToRow(at: IndexPath(row: toIndex, section: 0), at: .bottom, animated: true)
                        }*/
                    }
                }
                if (docChange.type == .removed) {
                    if let index = self.snapshotsController.remove(docChange.document) {
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                }
            }
        }
        // Your listener can use the hasLocalChanges field on each document to determine whether the document has local changes that have not yet been written to the backend.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove the Firebase database observers and empty the local cache in order to clean up memory
        listener?.remove()
        snapshotsController.removeAll()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Add
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        
        // Create a dialog alert controller with a text field to collect the new bucket list idea
        let alertController = UIAlertController(title: "New Thing", message: "An idea to accomplish before you die", preferredStyle: .alert)
        alertController.addTextField { textField in }
        
        // Insert the new idea into the Firebase database
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if let text = alertController.textFields?.first?.text {
                
                // Log an event with Firebase Analytics
                if self.snapshotsController.count == 0 {
                    Analytics.logEvent("BucketListNew", parameters: nil)
                }
                
                self.ref?.document().setData(["name": text, "priority": self.snapshotsController.maxPriority + 10])
            }
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: Delete and Move
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let snapshotToDelete = snapshotsController.find(byIndex: indexPath.row) {
                // Remove the idea from the Firestore database using the database reference stored in the snapshot
                snapshotToDelete.reference.delete()
            }
        }
        else if editingStyle == .insert {
            self.ref?.document().setData(["name": "New Idea", "priority": self.snapshotsController.maxPriority + 10])
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if let snapshotForMovedRow = snapshotsController.find(byIndex: sourceIndexPath.row) {
            if let newPriority = snapshotsController.calculatePriorityOnMove(from: sourceIndexPath.row, to: destinationIndexPath.row) {
                let dict = snapshotForMovedRow.data() as NSDictionary
                print ("About to set newPriority = \(newPriority) for moved row with name = \(dict["name"] ?? "No Name") and priority = \(dict["priority"] ?? 0)")
                // Change the priority, which controls the query sort order, by changing in the Firebase database using a reference stored in the snapshot
                snapshotForMovedRow.reference.updateData(["priority": newPriority])
            }
        }
    }
    
    // MARK: - Table Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snapshotsController.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt index=\(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "BucketIdea", for: indexPath) as! BucketIdeaTableViewCell
        
        let snapshot = snapshotsController.find(byIndex: indexPath.row)
        cell.bucketIdea = snapshot?.data()

        return cell
    }
    
}

