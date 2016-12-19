# FirebaseSwiftExample
Example iOS app using Firebase, Swift 3, Xcode 8, iOS 10. Initially demonstrating only the Authentication module with the email address provider, but expanding over time. Setup instructions are in-progress

Firebase is a mobile platform from Google. The most distinguishing feature for iOS development is a local database in a mobile app that synchronizes with the cloud while gracefully handling offline modes and queueing up changes for the next connected session.

![Video of App Demo](https://raw.githubusercontent.com/jeffcollier/FirebaseSwiftExample/master/FirebaseSwiftExample/Images/FirebaseSwiftExampleSignIn.gif)

# Setup
1. Install CocoaPods
    * You can utilize gem, rvm ruby, brew and others, or you can obtain the compiled macOS app from https://cocoapods.org
2. [Setup Your Own Firebase Account](https://firebase.google.com)
3. Create a Firebase Project for this App
    * Login to your Firebase account
    * Locate the console
    * Locate the action to create a new project
        * Project Name: Enter any name -- there is no dependency on this example project
4. Add Firebase to Your iOS App -- You should see a project overview screen -- select the action to add a Firebase to your iOS app
    1. App Details - iOS Bundle ID: There is a dependency on the Bundle Identifier in the Xcode project -- either enter your bundle ID here and update in your Xcode project, or enter the value from this sample Xcode project here
    2. Config File: In this step, you'll download the required GoogleService-Info.plist file
        * Move that file to the root directory of this sample project (i.e. the directory containing FirebaseSwiftExample.xcodeproj)
    3. Install Pod: The Firebase screen will include instructions for using CocoaPods here to manage dependencies. You do not need to take this action, as the files already exist in this sample project
        * Note that with your next project, this is the step that will generate an Xcode workspace for your Xcode project. However, the workspace already exists for your for this sample projecdt
    4. Add Initialization Code: Again, you do not need to take this action, as the code already exists
5. Setup Firebase Authentication -- You should see the proejct overview screen. Location the Authentication tile and select the option to Get Started
    1. Select the option to Setup Sign-In Method
    2. In the list of providers, locate Email, and select the row
    3. Enable Email, and save
6. Complete in Xcode -- Open the workspace (i.e. FirebaseSwiftExample.xcworkspace), **NOT** the project file
    1. You should see two top-level items: the project (FirebaseSwiftExample) and Pods
    2. Select the project and the action to add files (e.g. menu / File / Add files)
    3. Locate the GoogleService-Info.plist file, and add it -- it should appear at the root level along with folders such as FirebaseSwiftExampleTests
    4. In the properties window that appears for the project, look in the Identity section at the top. Confirm that the Bundle Identifier matches whatever you entered in the Firebase setup screen
7. Run the app
    
        
