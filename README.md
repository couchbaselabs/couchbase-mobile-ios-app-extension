# couchbase-mobile-ios-app-extension
This is simple Task List app that allows users to add, edit, delete tasks. A user can mark tasks as completed. 
A Today Extension is bundled with the app that shows the top 2 tasks right in your notification center without the need
to open the app. The user can mark tasks as completed right from the notification center. 

All tasks are stored in a local Couchbase Lite database and synched with the remote Sync Gateway so changes are made available to apps/app extensions on other devices.

## Platform
- Xcode 8.3 + (Prefer Xcode 9 as it allows multiple simulator support)
- Couchbase Lite 1.4.1

## Installation
- Clone the repo
```bash
 git clone git@github.com:couchbaselabs/couchbase-mobile-ios-app-extension.git
```

- Switch to the syncsupport branch
```bash
    git checkout syncsupport
```

- Install Couchbase Lite using Cocoapods . If you do not have Cocoapods installed on your machine, [download](https://guides.cocoapods.org/using/getting-started.html) it. 

Then run the following command from the root folder of the repo that you cloned
```bash
pod install
```

- Open the `CBLiteTaskApp.xcworkspace` using Xcode

- Build and run the `CBLiteTaskApp target`


## App Architecture
![Alt-Text](http://blog.couchbase.com/wp-content/uploads/2017/11/app_extension_sync.png)


### Demo
- Screen Recording demonstrating how changes made in the App are reflected in the Today Widget view and vice versa. Also changes made via the Sync Gateway REST API are reflected in the

-- <img src="http://blog.couchbase.com/wp-content/uploads/2017/11/app_extensions_withsync.gif" alt="Updating Tasks Through Container App" width=1000px height=500>




