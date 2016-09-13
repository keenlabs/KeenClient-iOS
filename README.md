Keen IO iOS SDK
===============

[![Build Status](https://travis-ci.org/keenlabs/KeenClient-iOS.svg?branch=master)](https://travis-ci.org/keenlabs/KeenClient-iOS) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Coverage Status](https://coveralls.io/repos/github/keenlabs/KeenClient-iOS/badge.svg?branch=master)](https://coveralls.io/github/keenlabs/KeenClient-iOS?branch=master)

---

**Important**: Starting in version 3.5.0, the variable `maxAttempts` was renamed to `maxEventUploadAttempts` to avoid any confusion with the query functionality for limiting failed attempts.

**Important**: Starting in version 3.3.0, you'll need to add the SystemConfiguration framework to your project. Check the ["Build Settings"](#build-settings) section for more information.

---

The Keen IO iOS client is designed to be simple to develop with, yet incredibly flexible. Our goal is to let you decide what events are important to you, use your own vocabulary to describe them, and decide when you want to send them to Keen IO.

While the name of this repo implies that this SDK is strictly for iOS, it can also be used in Mac OS applications by using the Cocoa version as outlined below. The code base is the same, but the build targets are different. :)

* [Installation](#installation) - How to install `KeenClient` in your application
	* [Carthage](#carthage)
	* [CocoaPods](#cocoapods)
	* [Binary](#universal-binary)
* [Usage](#usage) - How to use `KeenClient`
	* [Add Events](#add-events) - How to add an event
	* [Global Properties](#global-properties) - How to set global properties
	* [Geo Location](#geo-location) - How to use Geo Location
	* [Upload to Keen](#upload-events-to-keen-io) - How to upload all previously saved events
	* [Add-ons](#add-ons) - How to use Keen's [Data Enrichment](https://keen.io/docs/data-collection/data-enrichment/#data-enrichment) features to enrich your data
	* [Querying](#querying) - How to query and analyze your data
		* [Examples](#examples) - Example of queries
		* [Count Example](#count-example) - Count query example
		* [Count Unique Example](#count-unique-example) - Count Unique query example
		* [Multi-Analysis Example](#multi-analysis-example) - Multi-Analysis query example
		* [Funnel Example](#funnel-example) - Funnel query example
	* [Debugging](#debugging) - How to debug your application using the SDK's built in logging
* [FAQs](#faqs)
* [Change Log](#change-log)
* [To Do](#to-do)
* [Questions & Support](#questions--support)
* [Contributing](#contributing)
* [API Documentation](https://keen.io/static/iOS-reference/index.html)

### Installation

Installing the client should be a breeze, and there are 3 different ways to do it: Carthage, CocoaPods, and Binary. If you run into any problems, please let us know by opening an issue on this repository or sending us an email at [contact@keen.io](mailto:contact@keen.io)!

#### Carthage

If you're using [Carthage](https://github.com/Carthage/Carthage), add the following to your Cartfile:

```
github "keenlabs/KeenClient-iOS"
```

After that, just run `carthage update` and drag and drop the frameworks in the newly created Carthage/Build folder to the "Linked Frameworks and Libraries" in your project "General" settings tab.

Also, follow the instructions on step 4 found [here](https://github.com/Carthage/Carthage/blob/5fd867c4895b4f59d70181dec169a1644f4430e3/README.md#if-youre-building-for-ios) to work around a bug when submitting to the App Store.

#### CocoaPods

If you're using [CocoaPods](http://cocoapods.org/), add the following to your Podfile:

```
pod 'KeenClient'
```

Then run:

```
pod install
```

#### Universal Binary

You can check the latest version of the binary in our release page [here](https://github.com/keenlabs/KeenClient-iOS/releases).

> While we think the universal binary makes things really easy, we love to be transparent. We love feedback, especially in the form of pull requests. :)

##### Download

* [Cocoa](https://github.com/keenlabs/KeenClient-iOS/releases/download/3.5.2/KeenClient-Cocoa.zip)
* [iOS](https://github.com/keenlabs/KeenClient-iOS/releases/download/3.5.2/KeenClient.zip)

##### Uncompress and Add to Xcode

Uncompress the ZIP file for the platform you're using, and drag the folder into your Xcode project. (KeenClient-Cocoa for Cocoa, and KeenClient for iOS).

#### Swift

Add a header file “ProjectName-Bridging-Header.h”. In the bridging header file, add: 

```objc
// If you're using the binary
#import “KeenClient.h”

// If you're using Carthage
#import <KeenClient/KeenClient.h>
```

In Build Settings, set the "Objective-C Bridging Header” section to your newly-created bridging header file ProjectName-Bridging-Header.h.

##### Build Settings

Make sure to add the following libraries in the "Link Binary with Libraries" section:

* CoreLocation.framework
* SystemConfiguration.framework

Also enable the "-ObjC" linker flag under "Other Linker Flags".

Voila!

### Usage

To use this client with the Keen IO API, you have to configure your Keen IO Project ID and its access keys (if you need an account, [sign up here](https://keen.io/) - it's free).

##### Register Your Project ID and Access Keys

Register the `KeenClient` shared client with your Project ID and access keys. The recommended place to do this is in one of your application delegates like so:

Objective C
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[KeenClient sharedClientWithProjectID:@"your_project_id" andWriteKey:@"your_write_key" andReadKey:@"your_read_key"];
	return YES;
}
```
Swift
```Swift
func application(application: UIApplication, 
	    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool 
{ 
	let client: KeenClient
	client = KeenClient.sharedClientWithProjectID("your_project_id",
									andWriteKey: "your_write_key", 
									andReadKey: nil)
	return true
}
```


The write key is required to send events to Keen IO. The read key is required to do analysis on Keen IO.

`[KeenClient sharedClientWithProjectID: andWriteKey: andReadKey:]` does the registration. From now on, in your code, you can just reference the shared client by calling `objc [KeenClient sharedClient]`.

##### Add Events

Add events to track. Here’s a very basic example for an app that includes two tabs. We want to track when a tab is switched to.

Objective C
```objc
- (void)viewWillAppear:(BOOL)animated
{
  	[super viewWillAppear:animated];

  	NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name", @"going to", @"action", nil];
  	[[KeenClient sharedClient] addEvent:event toEventCollection:@"tab_views" error:nil];
}
```
Swift
```Swift
override func viewWillAppear(animated: Bool) 
{
	super.viewWillAppear(animated)
	let event = ["view_name": "first view Swift", "action": "going to"]
	do {
		try KeenClient.sharedClient().addEvent(event, toEventCollection: "tab_views")
	} catch _ {
	}
}
```

The idea is to first create an arbitrary dictionary of JSON-serializable values. We support:

```objc
NSString, NSNumber, NSDate, NSDictionary, NSArray, and BOOL
```

> The JSON spec doesn’t include anything about date values. At Keen, we know dates are important to track. Keen sends dates back and forth through its API in ISO-8601 format. `KeenClient` handles this for you.

Keys must be alphanumeric, with the exception of the underscore (_) character, which can appear anywhere but the beginning of the string. For example, “view_name” is allowed, but “_view_name” is not.

Add as many events as you like. `KeenClient` will cache them on disk until you’re ready to send them.

`KeenClient` will automatically stamp every event you track with a timestamp. If you want to override the system value with your own, use the following example. Note that the “timestamp” key is set in the header properties dictionary.

Objective C
```objc
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

   	NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name", @"going to", @"action", nil];
    NSDate *myDate = [NSDate date];
    KeenProperties *keenProperties = [[KeenProperties alloc] init];
   	keenProperties.timestamp = myDate;
    [[KeenClient sharedClient] addEvent:event
           	         withKeenProperties:keenProperties
       	              toEventCollection:@"tab_views"
   	                              error:nil];
}
```
Swift
```Swift

override func viewWillAppear(animated: Bool) 
{
	super.viewWillAppear(animated)
        
	let event = ["view_name": "first view Swift", "action": "going to"]
	let keenProps: KeenProperties = KeenProperties()
	keenProps.timestamp = NSDate();
	do {
		try KeenClient.sharedClient().addEvent(event, withKeenProperties: keenProps, toEventCollection: "tab_views")
	} catch _ {
	}
}
```
##### Global Properties

Now you might be thinking, “Okay, that looks pretty easy. But what if I want to send the same properties on _every_ event in a particular collection? Or just _every_ event, period?” We’ve got you covered through something we call Global Properties.

Global properties are properties which are sent with every event. For example, you may wish to always capture device information like OS version, handset type, orientation, etc.

There are two ways to handle Global Properties - one is more simple but more limited, while the other is a bit more complex but much more powerful. For each of them, after you register your client, you’ll need to set an Objective-C property on the `KeenClient` instance you’re using.

###### Dictionary-based Global Properties

For this, the Objective-C property is called `globalPropertiesDictionary`. The property’s value will be an `NSDictionary` that you define. Each time an event is added, the client will look at the value of this property and add all its contents to the user-defined event. Use this if you have a bunch of static properties that you want to add to every event.

Here's an example using a dictionary:

Objective C
```objc
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    KeenClient *client = [KeenClient sharedClient];
   	client.globalPropertiesDictionary = @{@"some_standard_key": @"some_standard_value"};
}
```
Swift
```Swift
func applicationDidBecomeActive(application: UIApplication) 
{
	KeenClient.sharedClient().globalPropertiesDictionary = 
					        ["some_standard_key" : "some_standard_value"]
}
```

> If there are two properties with the same name specified in the user-defined event and the global properties, the user-defined event’s property will be the one used.

###### Block-based Global Properties

For this, the Objective-C property is called `globalPropertiesBlock`. The property’s value will be a block that you define. Every time an event is added, the block will be called. The client expects the block to return an `NSDictionary` consisting of the global properties for that event collection. Use this if you have a bunch of dynamic properties (see below) that you want to add to every event.

Here’s an example using blocks:

Objective C
```objc
- (void)applicationDidBecomeActive:(UIApplication *)application
{
   	KeenClient *client = [KeenClient sharedClient];
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
   	    if ([eventCollection isEqualToString:@"apples"]) {
       	    return @{ @"color": @"red" };
        } else if ([eventCollection isEqualToString:@"pears"]) {
   	        return @{ @"color": @"green" };
        } else {
   	        return nil;
        }
   	};
}
```
Swift
```Swift
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    KeenClient.sharedClient().globalPropertiesBlock = 
			    {(eventCollection : String!) -> [NSObject : AnyObject]! in
			    
            if (eventCollection.compare("apples") == 
	            NSComparisonResult.OrderedSame)
            {
                return ["color" : "red"]
            } else if (eventCollection.compare("pears") ==
						NSComparisonResult.OrderedSame)
            {
                return ["color" : "green"]
            }
            return nil
        };
}
```

The block takes in a single string parameter which corresponds to the name of this particular event. And we expect it to return an `NSDictionary` of your construction. This example doesn’t make use of the parameter, but yours could!

> Because we support a block here, you can create **dynamic** global properties. For example, you might want to capture the orientation of the device, which obviously could change at run-time. With the block, you can use functional programming to ask the OS what the current orientation is, each time you add an event. Pretty useful, right?

> Another note - you can use _both_ the dictionary property and the block property at the same time. If there are conflicts between defined properties, the order of precedence is: user-defined event > block-defined event > dictionary-defined event. Meaning the properties you put in a single event will **always** show up, even if you define the same property in one of your globals.

##### Geo Location

Like any good mobile-first service, Keen supports geo localization so you can track where events happened. This is **disabled by default**. To enable it, use:

Objective-C:
```objc
[KeenClient enableGeoLocation];
```

Swift:
```swift
KeenClient.enableGeoLocation()
```

Your users will be asked to allow geo location services. If the user chooses "Allow", all events will be automatically tagged with the current location.

###### Requesting Authorization for Location in iOS 8+

iOS 8 introduced a new method for requesting authorization that requires a few additional steps before location will automatically be appended to your events:

1. Add one or both of the following keys to your Info.plist file: `NSLocationWhenInUseUsageDescription`,`NSLocationAlwaysUsageDescription`
2. Call the appropriate authorization method to authorize your app to use location services. `authorizeGeoLocationWhenInUse` and `authorizeGeoLocationAlways` were both added as of version 3.2.16 of this SDK. `authorizeGeoLocationWhenInUse` is enabled by default as long as `NSLocationWhenInUseUsageDescription` is specified in your Info.plist file, so you don't need to call it if you're going the 'When in Use' route. `authorizeGeoLocationAlways` on the other hand must be called explicitly.

Example:

Objective C
```objc
[KeenClient authorizeGeoLocationAlways];
[KeenClient sharedClientWithProjectID:@"your_project_id" andWriteKey:@"your_write_key" andReadKey:@"your_read_key"];
```
Swift
```Swift
KeenClient.authorizeGeoLocationAlways()
KeenClient.sharedClientWithProjectID("your_project_id", andWriteKey: "your_write_key", andReadKey: "your_read_key")
```

###### Refreshing Current Location

Every time the app is freshly loaded, the client will automatically ask the device for its current location. It won’t ask again in order to save battery life. You can tell the client to ask the device for location again. Simply call:

Objective C
```objc
[[KeenClient sharedClient] refreshCurrentLocation];
```
Swift
```Swift
KeenClient.sharedClient().refreshCurrentLocation()
```

###### Manually Setting Location

You can also set the location manually. See the following example:

Objective C
```objc
NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name", @"going to", @"action", nil];

KeenProperties *keenProperties = [[KeenProperties alloc] init];
CLLocation *location = [[CLLocation alloc] initWithLatitude:37.73 longitude:-122.47];
keenProperties.location = location;

[[KeenClient sharedClient] addEvent:event withKeenProperties:keenProperties toEventCollection:@"tab_views" error:nil];
```
Swift
```Swift
let event = ["view_name": "first view Swift", "action": "going to"]
let keenProps: KeenProperties = KeenProperties()
let location: CLLocation = CLLocation(latitude: 37.73, longitude: -122.47)
keenProps.location = location

do {
    try KeenClient.sharedClient().addEvent(event, withKeenProperties:keenProps, toEventCollection:"tab_views")
} catch _ {
}
```


##### Upload Events to Keen IO

Upload the captured events to the Keen service. This must be done explicitly. We recommend doing the upload when your application is sent to the background, but you can do it whenever you’d like (for example, if your application typically has very long user sessions). The uploader spawns its own background thread so the main UI thread is not blocked.

Objective C
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
Swift
```Swift
- (void)applicationDidEnterBackground:(UIApplication *)application
{
        let taskId: UIBackgroundTaskIdentifier = application.beginBackgroundTaskWithExpirationHandler({() -> Void in
            NSLog("Background task is being expired.")
        });
        KeenClient.sharedClient().uploadWithFinishedBlock({() -> Void in
            application.endBackgroundTask(taskId)})
}
```
In this example, the upload is done in a background task so that even once the user backgrounds your application, the upload can continue. Here we first start the background task, start the upload, and then end the background task once the upload completes.

If you want to call upload periodically during your application’s execution, you can do so by simply invoking the `uploadWithFinishedBlock` method on your `KeenClient` instance at any point.

Objective C
```objc
[[KeenClient sharedClient] uploadWithFinishedBlock:nil];
```
Swift
```Swift
KeenClient.sharedClient().uploadWithFinishedBlock(nil)
```

**An important note:** it's a best practice to issue a single upload at a time. We make a best effort to reduce the number of threads spawned to upload in the background, but if you call upload many many times in a tight loop you're going to cause issues for yourself.

###### Limiting Upload Retries

By default, the client will only attempt to upload a given event 3 times --
after that it will be purged from the local queue. You can change this number to
your liking by setting the `client.maxEventUploadAttempts` value:

Objective C
```objc
// Set the max upload attempts to 10
[KeenClient sharedClient].maxEventUploadAttempts = 10;
```
Swift
```Swift
// Set the max upload attempts to 10
KeenClient.sharedClient().maxEventUploadAttempts = 10
```

##### Add-ons

Keen IO can take data you’ve sent and enrich it by parsing the data or joining it with other data sets. This is done through the concept of “add-ons”.

To activate add-ons, you simply add some new properties within the “keen” namespace in your events. Detailed documentation for the configuration of our add-ons is available [here](https://keen.io/docs/data-collection/data-enrichment/#add-ons).

For example, let's say we want to enable the [IP to Geo](https://keen.io/docs/data-collection/data-enrichment/#ip-to-geo) add-on:

Objective C
```objc
KeenClient *client = [KeenClient sharedClient];
client.globalPropertiesDictionary = @{@"keen":
                                         @{
                                           @"addons":@[
                                                       @{
                                                           @"name":@"keen:ip_to_geo",
                                                           @"input":@{
                                                                   @"ip":@"ip_address"
                                                           },
                                                           @"output":@"ip_geo_info"
                                                       }
                                                   ]
                                               },
                                           @"ip_address":[self getIPAddress:YES]
                                         };
```
Swift
```Swift
KeenClient.sharedClient().globalPropertiesDictionary = [
	"keen": [
		"addons": [
			[
				"name": "keen:ip_to_geo",
				"input": ["ip" : "ip_address"],
				"output": "ip_geo_info"
			]
		]
	],
	"ip_address": self.getIPAddress(true)
]
```

In this example, we add a global property for the IP to Geo information that allows us to translate the device's current IP address into the geographical location of the device by using the `[self getIPAddress:YES]` method.

**Note:** `[self getIPAddress:YES]` is a custom method that you'll have to implement for yourself as there's currently no built-in method to obtain the device's IP address. We've had success using a few of the solutions suggested in [this post](http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically).

##### Querying

After collecting event data inside your application, you might want to analyze it by running certain queries. You can do so by using the class `KIOQuery` and the methods `KeenClient.runAsyncQuery` and `KeenClient.runAsyncMultiAnalysisWithQueries`.

There's a whole bunch of different queries you can run depending on the questions you're trying to answer. You can find more detailed information in our documentation [here](https://keen.io/docs/api/#analyses), but the list of analysis types is:

- [Count](https://keen.io/docs/api/#count) - Return the total number of events found in a given collection.
- [Count Unique](https://keen.io/docs/api/#count-unique) - Return the number of unique values for a given property.
- [Minimum](https://keen.io/docs/api/#minimum) - Return the minimum of all numeric values for a given property.
- [Maximum](https://keen.io/docs/api/#maximum) - Return the maximum of all numeric values for a given property.
- [Sum](https://keen.io/docs/api/#sum) - Calculate the sum of all numeric values for a given property.
- [Average](https://keen.io/docs/api/#average) - Calculate the average of all numeric values for a given property.
- [Median](https://keen.io/docs/api/#median) - Calculate the median of all numeric values for a given property.
- [Percentile](https://keen.io/docs/api/#percentile) - Calculate a given percentile of all numeric values for a given property.
- [Select Unique](https://keen.io/docs/api/#select-unique) - Return a list of all unique values found for a given property.

Besides that, you can also run:

- [Multi-Analysis](https://keen.io/docs/api/#multi-analysis) - Run multiple analyses with a single request.
- [Funnels](https://keen.io/docs/api/#funnels) - Track the completion of a sequence of events.

###### Limiting Query Attempts

Keen IO has rate limits for Queries (more information can be found [here](https://keen.io/docs/api/#limits). For that reason, and taking into account the long approval process that apps go through, a small error in a query statement or changing your event collection properties could cause your app to hit that query limit and in turn create a bad experience for your users.

By default, the client will only attempt to run a failed query up to 10 times. After that it will only try to run it again after 3600 seconds (1 hour). You can change these numbers to your liking by setting the `client.maxQueryAttempts` and the `client.queryTTL` values:

Objective C
```objc
[KeenClient sharedClient].maxQueryAttempts = 10;

// Change the default value to 10 minutes
[KeenClient sharedClient].queryTTL = 600;
```

Swift
```Swift
KeenClient.sharedClient().maxQueryAttempts = 10

// Change the default value to 10 minutes
KeenClient.sharedClient().queryTTL = 600
```

###### Examples

Creating a query is as simple as instantiating a `KIOQuery` object:

Objective-C:
```objc
KIOQuery *countQuery = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection", @"timeframe": @"this_14_days"}];
```

Swift:
```Swift
let countQuery: KIOQuery = KIOQuery(query:"count", andPropertiesDictionary:["event_collection": "collection", "timeframe": "this_14_days"])
```

Let's show a few examples of running different queries. The last parameter of both `KeenClient.runAsyncQuery` and `KeenClient.runAsyncMultiAnalysisWithQueries` is a block. To avoid copy+pasting we'll use the same block for all the queries. It is going to print out the results in case of a successful query, or print out the errors in case the query fails:

Objective-C:
```objc
// Create block to run after query completes
void (^countQueryCompleted)(NSData *, NSURLResponse *, NSError *) = ^(NSData *responseData, NSURLResponse *returningResponse, NSError *error) {
    NSDictionary *responseDictionary = [NSJSONSerialization
                                        JSONObjectWithData:responseData
                                        options:kNilOptions
                                        error:nil];
    
    NSNumber *result = [responseDictionary objectForKey:@"result"];
    
    if(error || [responseDictionary objectForKey:@"error_code"]) {
        NSLog(@"Failure! 😞 \n\n error: %@\n\n response: %@", [error localizedDescription], [responseDictionary description]);
    } else {
        NSLog(@"Success! 😄 \n\n response: %@", [responseDictionary description]);
    }
};
```

Swift:
```Swift
// Create block to run after query completes
let countQueryCompleted = { (responseData: NSData!, returningResponse: NSURLResponse!, error: NSError!) -> Void in
    do {
        let responseDictionary: NSDictionary? = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
        
        if error != nil {
            self.resultTextView.text = "Error! 😞 \n\n error: \(error.localizedDescription)"
        } else if let errorCode = responseDictionary!.objectForKey("error_code"),
            errorMessage = responseDictionary!.objectForKey("message") as? String {
            self.resultTextView.text = "Failure! 😞 \n\n error code: \(errorCode)\n\n message: \(errorMessage)"
        } else {
            let result: NSNumber = responseDictionary!.objectForKey("result") as! NSNumber
            
            self.resultTextView.text = "Success! 😄 \n\n result: \(result) \n\n response: \(responseDictionary!.description)"
        }
    } catch let error as NSError {
        print("Error: \(error.localizedDescription)")
    }
}
```

###### Count Example

Objective-C:
```objc
KIOQuery *countQuery = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection", @"timeframe": @"this_14_days"}];
    
[[KeenClient sharedClient] runAsyncQuery:countQuery block:countQueryCompleted];
```

Swift:
```Swift
// KIOQuery object containing the query type and properties
let countQuery: KIOQuery = KIOQuery(query:"count", andPropertiesDictionary:["event_collection": "collection", "timeframe": "this_14_days"])

// Run the query
KeenClient.sharedClient().runAsyncQuery(countQuery, block: countQueryCompleted)
```

###### Count Unique Example

Objective-C:
```objc
KIOQuery *countUniqueQuery = [[KIOQuery alloc] initWithQuery:@"count_unique" andPropertiesDictionary:@{@"event_collection": @"collection", @"target_property": @"key", @"timeframe": @"this_14_days"}];
    
[[KeenClient sharedClient] runAsyncQuery:countUniqueQuery block:countQueryCompleted];
```

Swift:
```Swift
let countUniqueQuery: KIOQuery = KIOQuery(query:"count_unique", andPropertiesDictionary:["event_collection": "collection", "target_property": "key", "timeframe": "this_14_days"])

KeenClient.sharedClient().runAsyncQuery(countUniqueQuery, block: countQueryCompleted)
```

###### Multi-Analysis Example

Objective-C:
```objc
KIOQuery *countQuery = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection", @"timeframe": @"this_14_days"}];
KIOQuery *countUniqueQuery = [[KIOQuery alloc] initWithQuery:@"count_unique" andPropertiesDictionary:@{@"event_collection": @"collection", @"target_property": @"key", @"timeframe": @"this_14_days"}];

// Optionally set a name for your queries, so it's easier to check the results
[countQuery setQueryName:@"count_query"];
[countUniqueQuery setQueryName:@"count_unique_query"];

[[KeenClient sharedClient] runAsyncMultiAnalysisWithQueries:@[countQuery, countUniqueQuery] block:countQueryCompleted];
```

Swift:
```Swift
let countQuery: KIOQuery = KIOQuery(query:"count", andPropertiesDictionary:["event_collection": "collection", "timeframe": "this_14_days"])
let countUniqueQuery: KIOQuery = KIOQuery(query:"count_unique", andPropertiesDictionary:["event_collection": "collection", "target_property": "key", "timeframe": "this_14_days"])

// Optionally set a name for your queries, so it's easier to check the results
countQuery.queryName = "count_query"
countUniqueQuery.queryName = "count_unique_query"

KeenClient.sharedClient().runAsyncMultiAnalysisWithQueries([countQuery, countUniqueQuery], block: countQueryCompleted)
```

###### Funnel Example

Objective-C:
```objc
KIOQuery *funnelQuery = [[KIOQuery alloc] initWithQuery:@"funnel" andPropertiesDictionary:@{@"timeframe": @"this_14_days", @"steps": @[@{@"event_collection": @"user_signed_up",
            @"actor_property": @"user.id"},
          @{@"event_collection": @"user_completed_profile",
            @"actor_property": @"user.id"}]}];
    
[[KeenClient sharedClient] runAsyncQuery:funnelQuery block:countQueryCompleted];
```

Swift:
```Swift
let funnelQuery: KIOQuery = KIOQuery(query:"funnel", andPropertiesDictionary:["timeframe": "this_14_days", "steps": [["event_collection": "user_signed_up", "actor_property": "user.id"], ["event_collection": "user_completed_profile", "actor_property": "user.id"]]])

KeenClient.sharedClient().runAsyncQuery(funnelQuery, block: countQueryCompleted)
```

##### Debugging


`KeenClient` code does a lot of logging, but it’s turned off by default. If you’d like to see the log lines generated by your usage of the client, you can enable logging easily:

Objective C
```objc
[KeenClient enableLogging];
```
Swift
```Swift
KeenClient.enableLogging()
```

Just put this at any point before you use `KeenClient`. A good place is in your application delegate.

To disable logging, simply call:

Objective C
```objc
[KeenClient disableLogging];
```
Swift
```Swift
KeenClient.disableLogging()
```

### FAQs

Q: What happens when the device is offline? Will events automatically be sent when the device connects to wifi again?

A: Our SDK handles offline data collection and have built-in limits to prevent too much data from building up. We also handle re-posting events so that you don't have to worry about this.

Here's how it works. You specify when events should be uploaded to Keen (e.g. when the app is backgrounded).

If your player is offline when that happens, their data will be collected on the device and it will not be posted to Keen IO.
However, the next time they trigger the code that send events (e.g. backgrounding the app again) all the data from the previous sessions will also be posted (the timestamps will reflect the times the events actually happened).

### Change Log

You can find the change log [here](CHANGELOG.md).

### To Do

* Native iOS visualizations.

### Questions & Support

If you have any questions, bugs, or suggestions, please
report them via Github Issues. Or, come chat with us anytime
at [slack.keen.io](http://slack.keen.io). We'd love to hear your feedback and ideas!

### Contributing
This is an open source project and we love involvement from the community! Hit us up with pull requests and issues.
