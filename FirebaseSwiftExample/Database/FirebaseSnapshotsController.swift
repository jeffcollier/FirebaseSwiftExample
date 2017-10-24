//
//  FirebaseSnapshotsController.swift
//  FirebaseSwiftExample
//
//  Created by Collier, Jeff on 1/2/17.
//  Copyright © 2017 Collierosity, LLC. All rights reserved.
//

import Foundation
import FirebaseFirestore

class FirebaseSnapshotsController {
    
    var handlers: [() -> Void] = []
    var snapshots: [DocumentSnapshot] = []
    
    var count: Int {
        get { return snapshots.count }
    }
    var maxPriority: Int {
        get { return snapshots.last?.data()["priority"] as? Int ?? 0 }
    }
    
    
    func find (_ snapshot: DocumentSnapshot) -> DocumentSnapshot? {
        return find(byID: snapshot.documentID)
    }
    
    func find (byIndex index: Int) -> DocumentSnapshot? {
        if snapshots.count == 0 || index < 0 || index > snapshots.count - 1 { return nil }
        return snapshots[index]
    }
    
    func find (byID id: String) -> DocumentSnapshot? {
        for (index, element) in snapshots.enumerated() {
            if element.documentID == id {
                return snapshots[index]
            }
        }
        
        return nil
    }
    
    func indexOf (_ snapshot: DocumentSnapshot) -> Int? {
        for (index, element) in snapshots.enumerated() {
            if element.documentID == snapshot.documentID {
                return index
            }
        }
        
        return nil
    }
    
    func indexOf (byID id: String?) -> Int? {
        for (index, element) in snapshots.enumerated() {
            if element.documentID == id {
                return index
            }
        }
        
        return nil
    }
    
    func append (_ snapshot: DocumentSnapshot) -> Int? {
        snapshots.append(snapshot)
        return snapshots.count - 1
    }
    
    func replace (_ snapshot: DocumentSnapshot) -> Int? {
        if let index = indexOf(snapshot) {
            snapshots[index] = snapshot
            return index
        }
        
        return nil
    }
    
    func remove (_ snapshot: DocumentSnapshot) -> Int? {
        if let index = indexOf(snapshot) {
            snapshots.remove(at: index)
            return index
        }
        
        return nil
    }
    
    func removeAll () -> Void {
        snapshots.removeAll()
    }
    
    func move (from fromIndex: Int, to toIndex: Int) -> Int? {
        if snapshots.count == 0 || fromIndex < 0 || fromIndex > snapshots.count - 1 || toIndex < 0 || toIndex > snapshots.count - 1 { return nil }
        
        // let newIndex = (fromIndex < toIndex) ? toIndex - 1 : toIndex
        let snapshot = snapshots.remove(at: fromIndex)
        snapshots.insert(snapshot, at: toIndex)
        
        return toIndex
    }
    
    func move (_ snapshot: DocumentSnapshot, to toIndex: Int) -> Int? {
        if snapshots.count == 0 || toIndex < 0 || toIndex > snapshots.count - 1 { return nil }
        guard let fromIndex = indexOf(snapshot) else { return nil }
        
        let newIndex = (fromIndex < toIndex) ? toIndex - 1 : toIndex
        snapshots.remove(at: fromIndex)
        snapshots.insert(snapshot, at: newIndex)
        
        return fromIndex
    }
    
    // Assumes ascending priority with integers
    func calculatePriorityOnMove (from fromIndex: Int, to toIndex: Int) -> Int? {
        if snapshots.count == 0 || fromIndex < 0 || fromIndex > snapshots.count - 1 || toIndex < 0 || toIndex > snapshots.count - 1 { return nil }
        
        let movedElement = snapshots[fromIndex]
        let movedPriority = movedElement.data()["priority"] as? Int ?? 0
        print("Calculating priority for idea moving from index = \(fromIndex) with priority = \(movedPriority) to index = \(toIndex)")
        
        let displacedPriority = snapshots[toIndex].data()["priority"] as? Int ?? 0
        var newPriority: Int
        if toIndex == 0 {
            // If moved to the beginning, calculate the midpoint between 0 and the first element
            let firstPriority = snapshots.first?.data()["priority"] as? Int ?? 0
            newPriority = firstPriority / 2
        }
        else if toIndex == snapshots.count - 1 {
            // If moved to the end, calculate the average difference between each element and add to the last element
            let lastPriority = snapshots.last?.data()["priority"] as? Int ?? 0
            newPriority = lastPriority + ((lastPriority - 0) / snapshots.count)
        }
        else if toIndex > fromIndex {
            // If moving right, calculate the midpoint using the succeeding element
            let succeedingPriority = snapshots[toIndex + 1].data()["priority"] as? Int ?? 0
            newPriority = ((succeedingPriority - displacedPriority) / 2) + displacedPriority
        }
        else {
            // Otherwise, calculate the midpoint between the two elements
            let precedingPriority = snapshots[toIndex - 1].data()["priority"] as? Int ?? 0
            newPriority = ((displacedPriority - precedingPriority) / 2) + precedingPriority
        }
        print("Calculated priority for idea moving from index = \(fromIndex) with priority = \(movedPriority) to index = \(toIndex) as new priority = \(newPriority)")
        
        return newPriority
    }
    
    func childValueAsString (in snapshot: DocumentSnapshot, for key: String) -> String? {
        guard let value = snapshot.data()[key] as? String else { return nil }
        
        return value
    }
    
}

