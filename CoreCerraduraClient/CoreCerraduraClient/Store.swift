//
//  Store.swift
//  CoreCerraduraClient
//
//  Created by Alsey Coleman Miller on 6/4/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import NetworkObjects
import CoreCerradura

final public class Store: NetworkObjects.Store {
    
    // MARK: - Properties
    
    /** The authenticating user's username. */
    public let username: String
    
    /** The authenticating user's password. */
    public let password: String
    
    // MARK: - Private Properties
    
    private let httpDateFormatter: NSDateFormatter = {
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        
        return dateFormatter
        }()
    
    // MARK: - Initialization
    
    public init(managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType, serverURL: NSURL, prettyPrintJSON: Bool = false, username: String, password: String) {
        
        self.username = username
        self.password = password
        
        super.init(managedObjectModel: CoreCerraduraManagedObjectModel(), managedObjectContextConcurrencyType: managedObjectContextConcurrencyType, serverURL: serverURL, prettyPrintJSON: prettyPrintJSON, resourceIDAttributeName: "id", dateCachedAttributeName: "dateCached", searchPath: "search")
    }
    
    // MARK: - Build URL Requests
    
    public override func requestForSearchEntity(name: String, withParameters parameters: [String : AnyObject]) -> NSURLRequest {
        
        return self.appendAuthorizationHeaderToRequest(request: super.requestForSearchEntity(name, withParameters: parameters))
    }
    
    public override func requestForCreateEntity(name: String, withInitialValues initialValues: [String : AnyObject]?) -> NSURLRequest {
        
        return self.appendAuthorizationHeaderToRequest(request: super.requestForCreateEntity(name, withInitialValues: initialValues))
    }
    
    public override func requestForFetchEntity(name: String, resourceID: UInt) -> NSURLRequest {
        
        return self.appendAuthorizationHeaderToRequest(request: super.requestForFetchEntity(name, resourceID: resourceID))
    }
    
    public override func requestForEditEntity(name: String, resourceID: UInt, changes: [String : AnyObject]) -> NSURLRequest {
        
        return self.appendAuthorizationHeaderToRequest(request: super.requestForEditEntity(name, resourceID: resourceID, changes: changes))
    }
    
    public override func requestForDeleteEntity(name: String, resourceID: UInt) -> NSURLRequest {
        
        return self.appendAuthorizationHeaderToRequest(request: super.requestForDeleteEntity(name, resourceID: resourceID))
    }
    
    public override func requestForPerformFunction(functionName: String, entityName: String, resourceID: UInt, JSONObject: [String : AnyObject]?) -> NSURLRequest {
        
        return self.appendAuthorizationHeaderToRequest(request: self.requestForPerformFunction(functionName, entityName: entityName, resourceID: resourceID, JSONObject: JSONObject))
    }
    
    // MARK: - Requests
    
    public override func performSearch(fetchRequest: NSFetchRequest, URLSession: NSURLSession, completionBlock: ((error: NSError?, results: [NSManagedObject]?) -> Void)) -> NSURLSessionDataTask {
        
        return super.performSearch(fetchRequest, URLSession: URLSession, completionBlock: { (error: NSError?, results: [NSManagedObject]?) -> Void in
            
            // send notification for unauthorized error
            if error?.code == ServerStatusCode.Unauthorized.rawValue {
                
                NSNotificationCenter.defaultCenter().postNotificationName(<#aName: String#>, object: <#AnyObject?#>, userInfo: <#[NSObject : AnyObject]?#>)
            }
            
            // forward
            
            completionBlock(error: error, results: results)
        })
    }
    
    // MARK: - Private Methods
    
    private func appendAuthorizationHeaderToRequest(request originalRequest: NSURLRequest) -> NSURLRequest {
        
        let dateString = self.httpDateFormatter.stringFromDate(NSDate())
        
        let authenticationContext = AuthenticationContext(verb: originalRequest.HTTPMethod!, path: originalRequest.URL!.path!, dateString: dateString)
        
        let token = GenerateAuthenticationToken(self.username, self.password, authenticationContext)
        
        let request = originalRequest.mutableCopy() as! NSMutableURLRequest
        
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        return request
    }
}

public enum StoreNotification: String {
    
    case UnauthorizedError
}
