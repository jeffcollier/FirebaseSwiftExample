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
    
    // References to the remote Firebase database which also handles local persistence when offline
    var bucketItemsCollection: CollectionReference?
    var bucketItems: [DocumentSnapshot] = []
    var queryListener: ListenerRegistration?
    var queryUser: User?

    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        // Set the logo
        let imageView = UIImageView(image: UIImage(named: "AppTitleBarLogo"))
        imageView.contentMode =  .scaleAspectFill
        navigationItem.titleView = imageView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Obtain a reference to the collection in Firestore
        guard let currUser = Auth.auth().currentUser else { return }
        self.bucketItemsCollection = Firestore.firestore().collection("users/\(currUser.uid)/bucketlists")
        guard let bucketItemsCollection = self.bucketItemsCollection else { return }
        
        // Run the main query and create a listener only if this is the first presentation, or if the user has changed
        // If the listener were removed, the complete set of data would appear as "changes" with each view presentation
        if self.queryListener != nil && self.queryUser == currUser { return }

        // Reset the query, data source, and table view
        self.queryListener?.remove()
        self.bucketItems = []
        self.tableView.reloadData()
        self.queryUser = currUser

        // Run the query, update the data source, and update the table view
        let query = bucketItemsCollection.order(by: "priority")
        self.queryListener = query.addSnapshotListener { querySnapshot, error in
            guard let querySnapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            if let error = error {
                print("Error retreiving collection: \(error)")
                return
            }
            
            // Update the table data source
            self.bucketItems = querySnapshot.documents
            
            // Update the table view, animating all the table changes at the same time
            // Note: Indexes for inserts must be new; updates and deletes must be original
            var scrollToIndex: UInt = 0
            self.tableView.performBatchUpdates({
                querySnapshot.documentChanges.forEach { docChange in
                    switch (docChange.type) {
                    case .added:
                        self.tableView.insertRows(at: [IndexPath(row: Int(docChange.newIndex), section: 0)], with: .automatic)
                    case .modified:
                        // In-place change
                        if (docChange.oldIndex == docChange.newIndex) {
                            self.tableView.reloadRows(at: [IndexPath(row: Int(docChange.oldIndex), section: 0)], with: .automatic)
                        }
                            // Reordered
                        else {
                            let lowerIndex = (docChange.oldIndex <= docChange.newIndex) ? docChange.oldIndex : docChange.newIndex
                            let upperIndex = (docChange.oldIndex <= docChange.newIndex) ? docChange.newIndex : docChange.oldIndex
                            var reloadRowsIndexes: [IndexPath] = []
                            for index in lowerIndex...upperIndex {
                                reloadRowsIndexes.append(IndexPath(row:Int(index), section: 0))
                            }
                            self.tableView.reloadRows(at: reloadRowsIndexes, with: .automatic)
                        }
                    case .removed:
                        self.tableView.deleteRows(at: [IndexPath(row: Int(docChange.oldIndex), section: 0)], with: .automatic)
                    }
                    // Scroll down to the first row that has changed (i.e. min index). Will be 0 for only deletes
                    if (docChange.newIndex < scrollToIndex || scrollToIndex == 0) {
                        scrollToIndex = docChange.newIndex
                    }
                }
            }, completion: {(success) in
                // Scroll to the first/top row in the table containing a change. If the table is empty, there is no row to scroll to
                if (querySnapshot.documents.count == 0) { return }
                self.tableView.scrollToRow(at: IndexPath(row:Int(scrollToIndex), section: 0), at: .bottom, animated: true)
            })
        } // end: query.addSnapshotListener
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
                if self.bucketItems.count == 0 {
                    Analytics.logEvent("BucketListNew", parameters: nil)
                }
                
                let maxPriority = self.bucketItems.last?.data()?["priority"] as? Int ?? 0
                self.bucketItemsCollection?.document().setData(["name": text, "priority": maxPriority + 100])
            }
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Table Data Source
    
    // Provide the number of sections and rows in the data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bucketItems.count
    }
    
    // Compose the cell with data from the source for a particular row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BucketIdea", for: indexPath) as! BucketIdeaTableViewCell
        if (self.bucketItems.indices.contains(indexPath.row)) {
            cell.bucketIdea = self.bucketItems[indexPath.row].data()
        }

        return cell
    }

    // Inform the view that a user can edit a particular row
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // The user has deleted a row in the view, through the button in editing mode or a swipe. Delete it now in the data source
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if !self.bucketItems.indices.contains(indexPath.row) { return }
            let itemToDeleteReference = self.bucketItems[indexPath.row].reference
            itemToDeleteReference.delete()
        }
        // No implementation for now for .insert
    }
    
    // Inform the view that a user can move a particular row
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // The user has moved a row in the view. Move it now in the data source
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let fromIndex = sourceIndexPath.row, toIndex = destinationIndexPath.row
        if (!self.bucketItems.indices.contains(fromIndex) || !self.bucketItems.indices.contains(toIndex)) { return }
        
        let documentForMovedRow = self.bucketItems[fromIndex]
        if let newPriority = calculateSortOnMove(self.bucketItems, from: fromIndex, to: toIndex, forSortKey: "priority") {
            documentForMovedRow.reference.updateData(["priority": newPriority])
        }
    }
}


class BucketIdeaTableViewCell: UITableViewCell {
    
    var bucketIdea: [String: Any]? {
        didSet {
            self.configureView()
        }
    }
    
    func configureView () {
        if let bucketIdea = self.bucketIdea {
            textLabel?.text = bucketIdea["name"] as? String ?? "No Name"
        }
    }
}


// Assumes ascending priority with integers
func calculateSortOnMove (_ documents: [DocumentSnapshot], from fromIndex: Int, to toIndex: Int, forSortKey sortKey: String) -> Int? {
    
    // Validate parameters
    if !documents.indices.contains(fromIndex) || !documents.indices.contains(toIndex) { return nil }
    
    // No work is required on an empty or single-element array
    if documents.count == 0  || documents.count == 1 { return nil }
    
    let movedDoc = documents[fromIndex]
    let movedSort = movedDoc.data()?[sortKey] as? Int ?? 0
    
    let displacedSort = documents[toIndex].data()?[sortKey] as? Int ?? 0
    var newSort: Int
    if toIndex == 0 {
        // If moved to the beginning, calculate the midpoint between 0 and the first element
        let firstSort = documents.first?.data()?[sortKey] as? Int ?? 0
        newSort = firstSort / 2
    }
    else if toIndex == documents.count - 1 {
        // If moved to the end, calculate the average difference between each element and add to the last element
        let lastSort = documents.last?.data()?[sortKey] as? Int ?? 0
        newSort = lastSort + ((lastSort - 0) / documents.count)
    }
    else if toIndex > fromIndex {
        // If moving right, calculate the midpoint using the succeeding element
        let succeedingSort = documents[toIndex + 1].data()?[sortKey] as? Int ?? 0
        newSort = ((succeedingSort - displacedSort) / 2) + displacedSort
    }
    else {
        // Otherwise, calculate the midpoint between the two elements
        let precedingSort = documents[toIndex - 1].data()?[sortKey] as? Int ?? 0
        newSort = ((displacedSort - precedingSort) / 2) + precedingSort
    }
    print("Calculated sort for row moving from index = \(fromIndex) with sort = \(movedSort) to index = \(toIndex) where the sort was \(displacedSort) with new sort = \(newSort)")
    
    return newSort
}
