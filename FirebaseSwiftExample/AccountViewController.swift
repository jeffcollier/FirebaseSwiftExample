//
//  FirstViewController.swift
//  FirebaseSwiftExample
//
//  Created by Collier, Jeff on 12/18/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import FirebaseAnalytics
import FirebaseAuth
import FirebaseStorage
import UIKit

class AccountViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: Segues
    
    // Returning from succesfully signing up a new account or signing in
    @IBAction func unwindFromSignIn(segue: UIStoryboardSegue) {
        self.profileImageView.image = nil
        // TODO: refs.keepSynced = true for this user
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Log Out of Sample App?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: {(action) in
            do {
                try Auth.auth().signOut()
                self.profileImageView.image = nil
                // TODO: refs.keepSynced = false for this user
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            self.performSegue(withIdentifier: "unwindFromSignIn", sender: self)
        }))
        self.present(alert, animated: true, completion: {() -> Void in })
    }
    
    // MARK: Profile Picture
    
    @IBAction func changePictureButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Change Profile Picture", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove Profile Picture", style: .destructive, handler: {(action) in
            self.profileImageView.image = nil
            guard let user = Auth.auth().currentUser else { return }
            let storageRef = Storage.storage().reference()
            storageRef.child("shared/\(user.uid)/profile-400x400.png").delete {(error) in
                print("Error occurred deleting profile image from Firebase Storage: \(error?.localizedDescription)")
            }
            storageRef.child("shared/\(user.uid)/profile-80x80.png").delete {(error) in
                print("Error occurred deleting profile thumbnail image from Firebase Storage: \(error?.localizedDescription)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: {(action) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .popover // for iPad
            picker.popoverPresentationController?.sourceView = sender
            picker.popoverPresentationController?.sourceRect = sender.bounds
            picker.delegate = self
            self.present(picker, animated: true, completion: {() -> Void in })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) in
        }))
        self.present(alert, animated: true, completion: {() -> Void in })
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    // After the user cancels the picer, revert and do nothing
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // After the user picks an image, update the view and Firebase Storage
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        guard let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage,
              let user = Auth.auth().currentUser else {
            picker.dismiss(animated: true, completion: nil)
            return
        }

        guard let image = pickedImage.scaleAndCrop(withAspect: true, to: 200),
              let imageData = image.pngData() else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        // TODO: Handle @1x, @3x sizes and on the Storyboard, turn off Content Mode = Aspect Fill (and Clip to Bounds = true)
        
        // Display the picked image
        self.profileImageView.image = image
            
        // Upload the new profile image to Firebase Storage
        let storageRef = Storage.storage().reference().child("shared/\(user.uid)/profile-400x400.png")
        let metadata = StorageMetadata(dictionary: ["contentType": "image/png"])
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            guard metadata != nil else {
                print("Error uploading image to Firebase Storage: \(error?.localizedDescription)")
                return
            }
            // Metadata dictionary: bucket, contentType, downloadTokens, downloadURL, [file]name, updated, et al
            
            // Log the event with Firebase Analytics
            Analytics.logEvent("User_NewProfileImage", parameters: nil)

            // Create a thumbnail image for future use, too
            // TODO: Move this to a server-side background worker task
            guard let image = pickedImage.scaleAndCrop(withAspect: true, to: 40),
                let imageData = image.pngData() else {
                    return
            }
            let storageRef = Storage.storage().reference().child("shared/\(user.uid)/profile-80x80.png")
            storageRef.putData(imageData, metadata: StorageMetadata(dictionary: ["contentType": "image/png"]))
        }
            
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: View Lifecycle
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener({(auth, user) in
            
            if user == nil {
                self.performSegue(withIdentifier: "showAuthSignIn", sender: self)
                
                // If there are issues with views flickering then move to AppDelegate and switch window?.rootViewController
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // If a user is logged in, setup the view with name, profile image, et al
        if let user = Auth.auth().currentUser {
            
            nameLabel.text = user.displayName ?? user.email
            
            if profileImageView.image == nil {
                // Download the profile image from Firebase Storage with a maximum allowed size of 2MB (2 * 1024 * 1024 bytes)
                activityIndicator.startAnimating()
                let imageStorageRef = Storage.storage().reference().child("shared/\(user.uid)/profile-400x400.png")
                let downloadTask = imageStorageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
                    // Error available with .localizedDescription, but can simply be that the image does not exist yet
                    self.activityIndicator.stopAnimating()
                    if error == nil, let data = data {
                        self.profileImageView.image = UIImage(data: data)
                    }
                }
                // TODO: Timeout downloadTask and .cancel()
                // TODO: Avoid unnecessary network load and latency. Use the last profile image and replace asynchronously
                // UserDefaults().string(forKey: "profile_updated"), .object(forKey: "profile_image") as? NSData
            }
        }
        
        
    }

/*
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // If a user is logged in, setup the view with name, profile image, et al
        if let user = FIRAuth.auth()?.currentUser {
            
            if profileImageView.image == nil {
                let busy = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: profileImageView.frame.width, height: profileImageView.frame.height))
                busy.activityIndicatorViewStyle = .white
                busy.center = profileImageView.center
                busy.hidesWhenStopped = true
                busy.startAnimating()
                view.addSubview(busy)
                print("width: \(profileImageView.frame.width), height: \(profileImageView.frame.height), center.x: \(profileImageView.center.x), center.y: \(profileImageView.center.y), view.center.y=\(view.center.y), image.minY: \(profileImageView.frame.minY), busy.frame.minY: \(busy.frame.minY), busy.center.Y: \(busy.center.y), busy.height: \(busy.frame.height)")
            }
        }
        
    }
 */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
