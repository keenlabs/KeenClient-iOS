//
//  ThirdViewController.swift
//  KeenSwiftClientExample
//
//  Created by Heitor Sergent on 6/30/15.
//  Copyright (c) 2015 Keen.IO. All rights reserved.
//

import UIKit

@objc(ThirdViewController) class ThirdViewController: UIViewController {
    
    @IBOutlet weak var resultTextView: UITextView!;
    
    @IBAction func sendQueryButtonPressed(sender: AnyObject) {
        
        let countQueryCompleted = { (responseData: NSData!, returningResponse: NSURLResponse!, error: NSError!) -> Void in
            var error: NSError?;
            
            var responseDictionary: NSDictionary? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary;
            
            NSLog("response: %@", responseDictionary!);
            if let actualError = error {
                println("error: \(actualError)");
            }
            var result: NSNumber = responseDictionary!.objectForKey("result") as! NSNumber;
            
            NSLog("result: %@", result);
            
            // Get result value when querying with group_by property
            //var resultArray: NSArray = responseDictionary!.objectForKey("result") as! NSArray;
            //var resultDictionary: NSDictionary = resultArray[0] as! NSDictionary;
            //var resultValue: NSNumber = resultDictionary.objectForKey("result") as! NSNumber;
            //NSLog("resultValue: %@", resultValue);
            
            if let actualError = error, errorCode = responseDictionary!.objectForKey("error_code") as? String {
                println(NSString(format:"Failure! 😞 \n\n error: %@\n\n response: %@", actualError, errorCode));
                self.resultTextView.text = NSString(format:"Failure! 😞 \n\n error: %@\n\n response: %@", actualError, errorCode) as String;
            } else {
                self.resultTextView.text = NSString(format:"Success! 😄 \n\n response: %@", responseDictionary!.description) as String;
            }
        }
        
        // Async querying
        var countQuery: KIOQuery = KIOQuery(query:"count", andPropertiesDictionary:["event_collection": "collection"]);
        
        KeenClient.sharedClient().runAsyncQuery(countQuery, block: countQueryCompleted);
        
        // Multi-analysis querying example
        /*
        var countUniqueQuery: KIOQuery = KIOQuery(query:"count_unique", andPropertiesDictionary:["event_collection": "collection", "target_property": "key"]);
        
        countQuery.queryName = "count_query";
        countUniqueQuery.queryName = "count_unique_query";
        
        KeenClient.sharedClient().runAsyncMultiAnalysisWithQueries([countQuery, countUniqueQuery], block: countQueryCompleted);
        */
        
        // Funnel example
        /*
        var funnelQuery: KIOQuery = KIOQuery(query:"funnel", andPropertiesDictionary:["steps": [["event_collection": "user_signed_up", @"actor_property": "user.id"], ["event_collection": "user_completed_profile", "actor_property": "user.id"]]]);
        
        KeenClient.sharedClient().runAsyncQuery(funnelQuery, block: countQueryCompleted);
        */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated);
        let theEvent = ["view_name": "third view Swift", "action": "going to"];
        KeenClient.sharedClient().addEvent(theEvent, toEventCollection: "tab_views", error: nil);
    }
    
    override func viewWillDisappear(animated : Bool) {
        
        super.viewWillDisappear(animated);
        let theEvent = ["view_name" : "third view Swift", "action" : "leaving from"];
        KeenClient.sharedClient().addEvent(theEvent, toEventCollection: "tab_views", error: nil);
    }
    
}

