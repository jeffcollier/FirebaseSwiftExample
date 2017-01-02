//
//  FirstViewController.swift
//  FirebaseSwiftExample
//
//  Created by Collier, Jeff on 12/18/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import FirebaseAuth
import UIKit

class FirstViewController: UIViewController {

    // MARK: Segues
    
    // Returning from succesfully signing up a new account or signing in
    @IBAction func unwindFromSignIn(segue: UIStoryboardSegue) {
        // TODO: refs.keepSynced = true for this user
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Log Out of Sample App?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: {(action) in
            do {
                try FIRAuth.auth()?.signOut()
                // TODO: refs.keepSynced = false for this user
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            self.performSegue(withIdentifier: "unwindFromSignIn", sender: self)
        }))
        self.present(alert, animated: true, completion: {() -> Void in })
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addStateDidChangeListener({(auth, user) in
            
            if user == nil {
                self.performSegue(withIdentifier: "showAuthSignIn", sender: self)
                
                // If there are issues with views flickering then move to AppDelegate and switch window?.rootViewController
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

