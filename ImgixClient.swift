//
//  ImgixClient.swift
//  imgix-swift
//
//  Created by Paul Straw on 6/30/16.
//
//

import Foundation

public class ImgixClient {
    static public let version = "0.1.0"
    
    public let host: String
    public var useHttps: Bool = true
    public var secureUrlToken: String? = nil
    public var includeLibraryParam: Bool = true
    
    public init(host: String) {
        self.host = host
    }
    
    public init(host: String, useHttps: Bool) {
        self.host = host
        self.useHttps = useHttps
    }
    
    public init(host: String, useHttps: Bool, secureUrlToken: String) {
        self.host = host
        self.useHttps = useHttps
        self.secureUrlToken = secureUrlToken
    }
    
    public init(host: String, secureUrlToken: String) {
        self.host = host
        self.secureUrlToken = secureUrlToken
    }
    
    public func buildUrl(path: String, params: [String: AnyObject]) -> NSURL {
        let path = sanitizePath(path)
        
        let urlComponents = NSURLComponents.init()
        urlComponents.scheme = useHttps ? "https" : "http"
        urlComponents.host = self.host
        urlComponents.percentEncodedPath = path
        urlComponents.queryItems = buildParams(params)
        
        if secureUrlToken != nil {
            let signature = signatureForPathAndQueryString(path, queryString: urlComponents.percentEncodedQuery!)
            urlComponents.queryItems?.append(signature)
        }
        
        if urlComponents.queryItems!.isEmpty {
            urlComponents.queryItems = nil
        } else {
            urlComponents.percentEncodedQuery = encodeQueryItems(urlComponents.queryItems!)
        }

        return urlComponents.URL!
    }
    
    public func buildUrl(path: String) -> NSURL {
        return buildUrl(path, params: [String: AnyObject]())
    }
    
    private func sanitizePath(path: String) -> String {
        var path = path
        
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            path = UriCoder.encodeURIComponent(path)
        }
        
        if !path.hasPrefix("/") {
            path = "/" + path
        }
        
        return path
    }
    
    private func encodeQueryItems(queryItems: [NSURLQueryItem]) -> String {
        var queryPairs = [String]()
        
        for queryItem in queryItems {
            let encodedKey = UriCoder.encodeURIComponent(queryItem.name)
            let encodedVal = UriCoder.encodeURIComponent(queryItem.value!)
            queryPairs.append(encodedKey + "=" + encodedVal)
        }
        
        return queryPairs.joinWithSeparator("&")
    }
    
    private func buildParams(params: [String: AnyObject]) -> [NSURLQueryItem] {
        var params = params
        var queryItems = [NSURLQueryItem]()
        
        if (includeLibraryParam) {
            params["ixlib"] = "swift-" + ImgixClient.version
        }
        
        for (key, val) in params {
            var stringVal = String(val)
            
            if key.hasSuffix("64") {
                stringVal = Base64Coder.encode64(stringVal)
            }
            
            let queryItem = NSURLQueryItem.init(name: key, value: stringVal)
            
            queryItems.append(queryItem)
        }
        
        return queryItems
    }
    
    private func signatureForPathAndQueryString(path: String, queryString: String) -> NSURLQueryItem {
        var signatureBase = secureUrlToken! + path
        
        if queryString.characters.count > 0 {
            signatureBase += "?" + queryString
        }
        
        let signature = signatureBase.md5
        
        return NSURLQueryItem.init(name: "s", value: signature)
    }
}