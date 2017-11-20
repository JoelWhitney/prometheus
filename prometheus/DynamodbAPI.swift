//
//  DynamodbAPI.swift
//  prometheus
//
//  Created by Joel Whitney on 11/19/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import SwiftyJSON
import AWSDynamoDB
import AWSMobileHubHelper

//typealias ServiceResponse = (JSON, NSError?) -> Void

class DynamodbAPI: NSObject {
    static let sharedInstance = DynamodbAPI()
    
    // MARK: - Methods
    func queryWithPartitionKeyDescription() -> String {
        let partitionKeyValue = AWSIdentityManager.default().identityId!
        return "Find all items with userId = \(partitionKeyValue)."
    }
    
    func queryWithPartitionKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        if let userId = AWSIdentityManager.default().identityId {
            let objectMapper = AWSDynamoDBObjectMapper.default()
            let queryExpression = AWSDynamoDBQueryExpression()
            
            queryExpression.keyConditionExpression = "#userId = :userId"
            queryExpression.expressionAttributeNames = ["#userId": "userId",]
            queryExpression.expressionAttributeValues = [":userId": userId,]
            
            objectMapper.query(AWSHike.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
                DispatchQueue.main.async(execute: {
                    completionHandler(response, error as? NSError)
                })
            }
        }
    }
    
    func updateBeer(awsHike: AWSHike, completioHandler: () -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        objectMapper.save(awsHike, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("Item saved.")
        })
        completioHandler()
    }
    
    func removeBeer(awsHike: AWSHike, completioHandler: () -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        objectMapper.remove(awsHike, completionHandler:  {(error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
        })
        completioHandler()
    }
    
    func insertBeer(awsHike: AWSHike, completioHandler: () -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let itemToCreate: AWSHike = AWSHike()
        itemToCreate._userId = AWSIdentityManager.default().identityId!
        itemToCreate._hikeEntryId = awsBeer.beer().brewerydb_id
        itemToCreate._hike = awsHike.Hike().hikeData
        objectMapper.save(itemToCreate, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("Item saved.")
        })
        completioHandler()
    }
    
    func removeAllBeers(onCompletion: @escaping () -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        queryWithPartitionKeyWithCompletionHandler { (response, error) in
            if let erro = error {
                print("error: \(erro)")
            } else if response?.items.count == 0 {
                print("No items")
            } else {
                print("success: \(response!.items.count) items")
                for item in response!.items {
                    let awsHike = item as! AWSHike
                    DynamodbAPI.sharedInstance.removeBeer(awsHike: awsHike, completioHandler: {
                        print("item deleted")
                    })
                }
                onCompletion()
            }
        }
    }
}
