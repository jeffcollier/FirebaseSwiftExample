# Bucket List - An Example App for Firebase in Swift
Example iOS app using Firebase, Swift 3, Xcode 8.2 with Auto Layout and Segues, and iOS 10. Demonstrating the Firebase Authentication, Analytics and Database modules. Firebase is a mobile platform from Google. The most distinguishing feature for iOS development is a local database in a mobile app that synchronizes with the cloud while gracefully handling offline modes and queueing up changes for the next connected session.

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

# About

### Firebase Authentication
Firebase offers a remote administration of users and their authorizations for your mobile apps. At this point, Firebase offers providers for Facebook, Google+ and others. For simplicity, I used only the email address provider for this sample project. 

### Firebase Analytics
#### Tracking
By default, Firebase collects usage data such as device type, country, and view controllers. Firebase can additional capture data from the iOS AddSupport as long as the user has not disabled advertiser tracking. To include that data such as age and gender, you must:
1. Add the iOS AdSupport framework: [Firebase instructions](https://firebase.google.com/support/guides/analytics-adsupport) -- completed in this project
2. Check if the user allows ad tracking -- completed
3. When you submit your app to Apple, you will need to attest to your deference to user preferences and your usage of the ID: [Apple instructions](https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html#//apple_ref/doc/uid/TP40011225-CH33-SW8)

#### Logging Events
Firebase provides string constants for common events. You can also define your own strings, but take care to avoid clashing with reserved system values such as "first_open_time"

### Firebase Database
Firebase provide a local databaes in the same way as CoreData but, at the time of this development, the Firebase database is distinguished by its syncrhonization with the cloud, gracefully handling offline modes and queueing up changes for the next connected session. Unlike with CoreData, you query changes with the Firebase data through observer handlers which are often defined in viewDidAppear methods. With this sample app, you should be able to watch data created in realtime in the cloud under "bucketlists" "using the Firebase Database console.  

