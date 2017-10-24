//
//  Bucket.swift
//  FirebaseSwiftExample
//
//  Created by Collier, Jeff on 12/28/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import UIKit

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
