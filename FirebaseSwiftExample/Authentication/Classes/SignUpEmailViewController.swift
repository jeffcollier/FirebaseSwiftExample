//
//  SigupEmailViewController.swift
//  DecidePath
//
//  Created by Collier, Jeff on 12/8/16.
//  Copyright © 2016 Collierosity, LLC. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import FirebaseAuth

class SignUpEmailViewController: UIViewController {
    
    // MARK: Segues
    
    func handleSuccess (forUser user: User) {
        // Log an event with Firebase Analytics. See FIREventNames.h for pre-defined event strings
        Analytics.logEvent(AnalyticsEventSignUp, parameters: nil)
        
        let newemail = user.email ?? "your email address"
        let alert = UIAlertController(title: "Success", message: "You have a new account for \(newemail)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: {(action) in
            UserDefaults().set(user.email, forKey: "auth_emailaddress")
            UserDefaults().synchronize()
            self.performSegue(withIdentifier: "unwindFromSignIn", sender: self)
        }))
        self.present(alert, animated: true, completion: {() -> Void in })
    }
    
    // MARK: Sign Up
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        configureViewBusy()
        
        // Create a new user with Firebase using the email provider. Callback with FIRUser, Error with _code = FIRAuthErrorCode
        Auth.auth().createUser(withEmail: email, password: password) { (authDataResult, error) in
            
            self.configureViewNotBusy()
            
            if let error = error, let errorCode = AuthErrorCode(rawValue: error._code) {
                switch errorCode {
                case .weakPassword:
                    let alert = UIAlertController(title: "Weak password", message: "The password you entered is not strong enough with varied characters. Please try a different password", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {(action) in }))
                    self.present(alert, animated: true, completion: {() -> Void in })
                case .emailAlreadyInUse:
                    let alert = UIAlertController(title: "Account exists", message: "The email address \(email) already exists. Either login with the password for that address or click the help button if you have forgotten your password", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: {(action) in }))
                    self.present(alert, animated: true, completion: {() -> Void in })
                case .invalidEmail:
                    let alert = UIAlertController(title: "Incorrect Email Address", message: "The email address you entered doesn't appear to belong to an account. Please check your address and try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {(action) -> Void in }))
                    self.present(alert, animated: true, completion: {() -> Void in })
                default:
                    let alert = UIAlertController(title: "Something is Fucked Up", message: "Here is the message from Firebase: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay, G", style: .default, handler: {(action) -> Void in }))
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
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    var busy = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        busy = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: signUpButton.frame.height, height: signUpButton.frame.height))
        busy.style = .white
        busy.center = signUpButton.center
        busy.hidesWhenStopped = true
        view.addSubview(busy)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureViewEdit()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureView() {
        configureViewEdit()
    }
    
    func configureViewBusy () {
        signUpButton.isEnabled = false
        signUpButton.alpha = 0.33
        signUpButton.setTitle("", for: .disabled)
        busy.startAnimating()
    }
    
    func configureViewNotBusy () {
        busy.stopAnimating()
        signUpButton.setTitle("Sign Up", for: .disabled)
        signUpButton.isEnabled = true
        signUpButton.alpha = 1.0
    }
    
    func configureViewEdit () {
        if emailTextField.text == "" || passwordTextField.text == "" {
            signUpButton.isEnabled = false
            signUpButton.alpha = 0.33
        }
        else {
            signUpButton.isEnabled = true
            signUpButton.alpha = 1.0
        }
    }

    @IBAction func emailChanged(_ sender: UITextField) {
        configureViewEdit()
    }

    @IBAction func passwordChanged(_ sender: UITextField) {
        configureViewEdit()
    }
    
}
