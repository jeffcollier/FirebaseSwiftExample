//
//  LoginViewController.swift
//  DecidePath
//
//  Created by Collier, Jeff on 12/7/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import FirebaseAuth

class SignInEmailViewController: UIViewController {
    
    // MARK: Segues

    // Return point for any downstream views such as Sign Up
    @IBAction func unwindToSignIn(segue: UIStoryboardSegue) {
        if let user = Auth.auth().currentUser {
            handleSuccess(forUser: user)
        }
    }
    
    func handleSuccess (forUser user: User) {
        // Cache the email address with the iOS utility class
        UserDefaults().set(user.email, forKey: "auth_emailaddress")
        UserDefaults().synchronize()
        
        // Log an event with Firebase Analytics. See FIREventNames.h for pre-defined event strings
        Analytics.logEvent(AnalyticsEventLogin, parameters: nil)
        
        performSegue(withIdentifier: "unwindFromSignIn", sender: self)
    }
        
    // MARK: Sign In

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = usernameTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        configureViewBusy()
        
        // Sign in a user with Firebase using the email provider. Callback with FIRUser, Error with _code = FIRAuthErrorCode
        Auth.auth().signIn(withEmail: email, password: password) { (authDataResult, error) in

            self.configureViewNotBusy()

            if let error = error, let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode {
                    case .wrongPassword,
                         .invalidCredential:
                        let alert = UIAlertController(title: "Incorrect password for \(email)", message: "The password you entered is incorrect. Please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {(action) in self.clearPassword() }))
                        self.present(alert, animated: true, completion: {() -> Void in })
                    case .userNotFound,
                         .invalidEmail:
                        let alert = UIAlertController(title: "Incorrect Email Address", message: "The email address you entered doesn't appear to belong to an account. Please check your address and try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {(action) -> Void in
                            self.clearPassword()
                        }))
                        self.present(alert, animated: true, completion: {() -> Void in })
                    // TODO: case .errorCodeUserDisabled:
                    // TODO: case .errorCodeTooManyRequests:
                    default:
                        let alert = UIAlertController(title: "Something is Fucked Up", message: "Here is the message from Firebase: \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay, G", style: .default, handler: {(action) -> Void in
                            self.clearPassword()
                        }))
                        self.present(alert, animated: true, completion: {() -> Void in })
                    }
                    
                    return
            }
            
            guard let user = authDataResult?.user else {
                // This should never happen and would be an error with Firebase
                let alert = UIAlertController(title: "I'm Stumped", message: "Firebase returned no error message and no user", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay?", style: .default, handler: {(action) -> Void in }))
                self.present(alert, animated: true, completion: {() -> Void in })
                
                return
            }
  
            self.handleSuccess(forUser: user)
        }
    }
    
    // MARK: View Lifecycle
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var busy = UIActivityIndicatorView()
    
    // Invoked after after the view controller has loaded its view hierarchy into memory, but only then. Not before every display
    override func viewDidLoad() {
        super.viewDidLoad()

        busy = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: loginButton.frame.height, height: loginButton.frame.height))
        busy.style = .white
        busy.center = loginButton.center
        busy.hidesWhenStopped = true
        view.addSubview(busy)

        if let lastemail = UserDefaults().string(forKey: "auth_emailaddress") {
            usernameTextField.text = lastemail
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
    
    func configureView() {
        configureViewEdit()
    }
    
    func configureViewBusy () {
        loginButton.isEnabled = false
        loginButton.alpha = 0.33
        loginButton.setTitle("", for: .disabled)
        busy.startAnimating()
    }
    
    func configureViewNotBusy () {
        busy.stopAnimating()
        loginButton.setTitle("Login", for: .disabled)
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
    }
    // If not optimistic UIs, can disable the UI with UIApplication.shared.beginIgnoringInteractionEvents()
    // To cover the view, see 28785715/how-to-display-an-activity-indicator-with-text-on-ios-8-with-swift and self.messageFrame.removeFromSuperview()
    
    func configureViewEdit () {
        if usernameTextField.text == "" || passwordTextField.text == "" {
            loginButton.isEnabled = false
            loginButton.alpha = 0.33
        }
        else {
            loginButton.isEnabled = true
            loginButton.alpha = 1.0
        }
    }
    
    // MARK: Editing
    
    @IBAction func usernameChanged(_ sender: UITextField) {
        configureViewEdit()
    }

    @IBAction func passwordChanged(_ sender: UITextField) {
        configureViewEdit()
    }
    
    func clearPassword() {
        passwordTextField.text = ""
        configureViewEdit()
    }
    

}

