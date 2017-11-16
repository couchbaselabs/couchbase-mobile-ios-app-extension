# couchbase-mobile-ios-app-extension
Simple App that demonstrates how Couchbase Lite can be used as an embedded database with an iOS App Extension. Details will be provided in a blog post coming soon.

## Platform
Xcode 8.3 +
Couchbase Lite 1.4.1

## Installation
- Clone the repo
```bash
git clone git clone git@github.com:couchbaselabs/couchbase-mobile-ios-app-extension.git
```

- Install Couchbase Lite using Cocoapods . If you do not have Cocoapods installed on your machine, [download](https://guides.cocoapods.org/using/getting-started.html) it. Then run the following command from the root folder of the repo that you cloned
```bash
pod install
```

- Open the `CBLiteApp.xcworkspace` using Xcode

- Build and run the `CBLiteApp target`



## App Architecture
![Alt-Text](http://blog.couchbase.com/wp-content/uploads/2017/05/app-arch.png)


### Demo
- Screen Recording demonstrating how changes made by App Container are reflected in the Today Widget view

-- <img src="http://blog.couchbase.com/wp-content/uploads/2017/05/editdeletetask-1.gif" alt="Updating Tasks Through Container App" width=300px height=500>

- Screen Recording demonstrating how updates made in the Today Widget are reflected in the App
-- <img src="http://blog.couchbase.com/wp-content/uploads/2017/05/forcetouch.gif" alt="Updating tasks Through Today Widget" width=300px height=500>

