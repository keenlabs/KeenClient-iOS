Keen IO iOS SDK
===============

[![Build Status](https://travis-ci.org/keenlabs/KeenClient-iOS.png)](https://travis-ci.org/keenlabs/KeenClient-iOS)

The Keen IO iOS client is designed to be simple to develop with, yet incredibly flexible. Our goal is to let you decide what events are important to you, use your own vocabulary to describe them, and decide when you want to send them to Keen IO.

[API Documentation](https://keen.io/static/iOS-reference/index.html)

[Client Documentation](https://keen.io/docs/clients/iOS/usage-guide)

### Installation

Use [cocoapods](http://cocoapods.org/) to install! Just add a line to your Podfile like so:
```
    pod 'KeenClient'
```

Then run

```objc
    pod install
```

##### Build Settings

Make sure to add CoreLocation.framework to the "Link Binary with Libraries" section. If you're using SDK version 3.2.9 or above, add libsqlite3.dylib as well.

Also enable the "-ObjC" linker flag under "Other Linker Flags".

Voila!

For other methods, see our detailed documentation [here](https://keen.io/docs/clients/iOS/usage-guide).

### Usage

To use this client with the Keen IO API, you have to configure your Keen IO Project ID and its access keys (if you need an account, [sign up here](https://keen.io/) - it's free).

##### Register Your Project ID and Access Keys

```objc
    - (void)applicationDidBecomeActive:(UIApplication *)application
    {
        [KeenClient sharedClientWithProjectId:@"your_project_id" andWriteKey:@"your_write_key" andReadKey:@"your_read_key"];
    }
```

The write key is required to send events to Keen IO. The read key is required to do analysis on Keen IO.

##### Add Events

Use the client like so:

```objc
    - (void)viewWillAppear:(BOOL)animated
    {
        [super viewWillAppear:animated];

        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name",
                               @"going to", @"action", nil];
        [[KeenClient sharedClient] addEvent:event toEventCollection:@"tab_views" error:nil];
    }
```

##### Upload Events to Keen IO

Adding events just stores the events locally on the device. You must explicitly upload them to Keen IO. Here's an example:

```objc
    - (void)applicationDidEnterBackground:(UIApplication *)application
    {
        UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
            NSLog(@"Background task is being expired.");
        }];

        [[KeenClient sharedClient] uploadWithFinishedBlock:^(void) {
            [application endBackgroundTask:taskId];
        }];
    }
```
    
That's it! After running your code, check your Keen IO Project to see the event has been added.

An important note: it's a best practice to issue a single upload at a time. We make a best effort to reduce the number of threads spawned to upload in the background, but if you call upload many many times in a tight loop you're going to cause issues for yourself.

##### Do analysis with Keen IO

    TO DO
    
##### Tracking events in OS X apps

This SDK *should* work for OS X apps. If you try and it doesn't work, please file an issue here. Thanks!
    
### Changelog

##### 3.2.9

+ Replaced use of filesystem's cache directory with SQLite via KIOEventStore

##### 3.2.8

+ Upload with finished block consistency fix

##### 3.2.7

+ Support sending addons in events.

##### 3.2.6

+ Bugfix to always invoke callback on upload, even if there are no events to upload.

##### 3.2.5

+ Don't throw exceptions and crash the app when the local cache directory is unavailable.
+ Remove ISO8601DateFormatter dependency.
+ Use Grand Central Dispatch to not spawn one thread per upload invocation.

##### 3.2.4

+ Get semantic versioning cleaned up for cocoapods (somehow got confused between 3.2.2 and 3.2.3).

##### 3.2.2

+ Support for iOS 7 and ARM64.
+ Removed JSONKit dependency in favor of NSJONSerialization.

##### 3.2.1

+ Changed project token -> project ID.
+ Added support for read and write scoped keys.
+ Added support for travis.

### To Do

* Support analysis APIs.
* Native iOS visualizations.

### Questions & Support

If you have any questions, bugs, or suggestions, please
report them via Github Issues. Or, come chat with us anytime
at [users.keen.io](http://users.keen.io). We'd love to hear your feedback and ideas!

### Contributing
This is an open source project and we love involvement from the community! Hit us up with pull requests and issues.
