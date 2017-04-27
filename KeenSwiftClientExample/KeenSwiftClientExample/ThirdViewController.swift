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

    @IBAction func sendQueryButtonPressed(_ sender: AnyObject) {

        let countQueryCompleted = { (responseData: Data?, returningResponse: URLResponse?, error: Error?) -> Void in
            do {
                let responseDictionary: NSDictionary? = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary;

                NSLog("response: %@", responseDictionary!);

                if error != nil {
                    self.resultTextView.text = "Error! 😞 \n\n error: \(error?.localizedDescription)";
                } else if let errorCode = responseDictionary!.object(forKey: "error_code"),
                              let errorMessage = responseDictionary!.object(forKey: "message") as? String {
                    self.resultTextView.text = "Failure! 😞 \n\n error code: \(errorCode)\n\n message: \(errorMessage)";
                } else {
                    let result: NSNumber = responseDictionary!.object(forKey: "result") as! NSNumber;

                    NSLog("result: %@", result);

                    // Get result value when querying with group_by property
                    let resultArray: NSArray = responseDictionary!.object(forKey: "result") as! NSArray;
                    let resultDictionary: NSDictionary = resultArray[0] as! NSDictionary;
                    let resultValue: NSNumber = resultDictionary.object(forKey: "result") as! NSNumber;
                    NSLog("resultValue: %@", resultValue);

                    self.resultTextView.text = "Success! 😄 \n\n response: \(responseDictionary!.description)";
                }
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
        }

        // Async querying
        let countQuery: KIOQuery = KIOQuery(query:"count", andPropertiesDictionary:["event_collection": "tab_views", "timeframe": "this_7_days"]);
        KeenClient.shared().runAsyncQuery(countQuery, completionHandler: countQueryCompleted);

        // Multi-analysis querying example
        /*
        let countUniqueQuery: KIOQuery = KIOQuery(query:"count_unique", andPropertiesDictionary:["event_collection": "collection", "target_property": "key", "timeframe": "this_7_days"]);

        countQuery.queryName = "count_query";
        countUniqueQuery.queryName = "count_unique_query";

        KeenClient.shared().runAsyncMultiAnalysis(withQueries: [countQuery, countUniqueQuery], block: countQueryCompleted);
        */

        // Funnel example
        /*
        let funnelQuery: KIOQuery = KIOQuery(query:"funnel", andPropertiesDictionary:["timeframe": "this_7_days", "steps": [["event_collection": "user_signed_up", "actor_property": "user.id"], ["event_collection": "user_completed_profile", "actor_property": "user.id"]]]);

        KeenClient.shared().runAsyncQuery(funnelQuery, block: countQueryCompleted);
        */
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated);
        let theEvent = ["view_name": "third view Swift", "action": "going to"];
        do {
            try KeenClient.shared().addEvent(theEvent, toEventCollection: "tab_views")
        } catch _ {
        };
    }

    override func viewWillDisappear(_ animated : Bool) {

        super.viewWillDisappear(animated);
        let theEvent = ["view_name" : "third view Swift", "action" : "leaving from"];
        do {
            try KeenClient.shared().addEvent(theEvent, toEventCollection: "tab_views")
        } catch _ {
        };
    }

}

