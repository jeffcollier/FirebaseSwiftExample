//
//  ForgotEmailViewController.swift
//  DecidePath
//
//  Created by Collier, Jeff on 12/17/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import UIKit
import FirebaseAuth

class ForgotEmailViewController: UIViewController {
    
    // MARK: Segues
    
    func handleSuccess () {
        self.performSegue(withIdentifier: "unwindToSignIn", sender: self)
    }
    
    // MARK: Sign In
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text else { return }
        
        configureViewBusy()
        
        // Sign in a user with Firebase using the email provider. Callback with FIRUser, Error with _code = FIRAuthErrorCode
        FIRAuth.auth()?.sendPasswordReset(withEmail: email) { (error) in
            
            self.configureViewNotBusy()
            
            if let error = error, let errorCode = FIRAuthErrorCode(rawValue: error._code) {
                switch errorCode {
                case .errorCodeUserNotFound:
                    let alert = UIAlertController(title: "Incorrect address", message: "There is no record of an account with that email address. Please check that you have entered it correctly", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {(action) in }))
                    self.present(alert, animated: true, completion: {() -> Void in })
                case .errorCodeInvalidEmail:
                    let alert = UIAlertController(title: "Incorrect address", message: "The email address you entered doesn't appear to be a valid address. Please check your spelling and try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {(action) -> Void in }))
                    self.present(alert, animated: true, completion: {() -> Void in })
                default:
                    let alert = UIAlertController(title: "Something is Fucked Up", message: "Here is the message from Firebase: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay, G", style: .default, handler: {(action) -> Void in }))
                    self.present(alert, animated: true, completion: {() -> Void in })
                }
                
                return
            }
            
            self.handleSuccess()
        }
    }
    
    // MARK: View Lifecycle
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    var busy = UIActivityIndicatorView()
    
    // Invoked after after the view controller has loaded its view hierarchy into memory, but only then. Not before every display
    override func viewDidLoad() {
        super.viewDidLoad()
        
        busy = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: sendButton.frame.height, height: sendButton.frame.height))
        busy.activityIndicatorViewStyle = .white
        busy.center = sendButton.center
        busy.hidesWhenStopped = true
        view.addSubview(busy)
        
        if let lastemail = UserDefaults().string(forKey: "auth_emailaddress") {
            emailTextField.text = lastemail
        }
    }
    
    // Invoked after viewDidLoad, and invoked every time the view is dispalyed (e.g. tab change, exit segue)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.configureViewEdit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureViewBusy () {
        sendButton.isEnabled = false
        sendButton.alpha = 0.33
        sendButton.setTitle("", for: .disabled)
        busy.startAnimating()
    }
    
    func configureViewNotBusy () {
        busy.stopAnimating()
        sendButton.setTitle("Send Email with Link", for: .disabled)
        sendButton.isEnabled = true
        sendButton.alpha = 1.0
    }
    // If not optimistic UIs, can disable the UI with UIApplication.shared.beginIgnoringInteractionEvents()
    // To cover the view, see 28785715/how-to-display-an-activity-indicator-with-text-on-ios-8-with-swift and self.messageFrame.removeFromSuperview()
    
    func configureViewEdit () {
        if emailTextField.text == "" {
            sendButton.isEnabled = false
            sendButton.alpha = 0.33
        }
        else {
            sendButton.isEnabled = true
            sendButton.alpha = 1.0
        }
    }
    
    // MARK: Editing
    
    @IBAction func emailChanged(_ sender: UITextField) {
        configureViewEdit()
    }
}

