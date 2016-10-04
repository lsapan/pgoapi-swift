//
//  PtcOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire


open class PtcOAuth: PGoAuth {
    open var username: String!
    open var password: String!
    open var accessToken: String?
    open var expires: Int?
    open var expired: Bool = false
    open var loggedIn: Bool = false
    open var delegate: PGoAuthDelegate?
    open let authType: PGoAuthType = .ptc
    open var endpoint: String = PGoEndpoint.Rpc
    open var authToken: Pogoprotos.Networking.Envelopes.AuthTicket?
    open var manager: SessionManager
    open var banned: Bool = false
    
    public init(proxyHost: String? = nil, proxyPort: String? = nil) {
        let configuration = URLSessionConfiguration.default
        if proxyHost != nil && proxyPort != nil {
            var proxyConfiguration = [NSObject: Any]()
            proxyConfiguration[kCFNetworkProxiesHTTPProxy] = proxyHost!
            proxyConfiguration[kCFNetworkProxiesHTTPPort] = proxyPort!
            proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 1
            configuration.connectionProxyDictionary = proxyConfiguration
        }
        manager = Alamofire.SessionManager(configuration: configuration)
    }
    
    public func disableProxy() {
        var proxy = manager.session.configuration.connectionProxyDictionary
        proxy?[kCFNetworkProxiesHTTPEnable as AnyHashable] = 0
        manager.session.configuration.connectionProxyDictionary = proxy
    }
    
    public func enableProxy(proxyHost: String? = nil, proxyPort: String? = nil) {
        var proxy = manager.session.configuration.connectionProxyDictionary
        proxy?[kCFNetworkProxiesHTTPEnable as AnyHashable] = 1
        if proxyHost != nil && proxyPort != nil {
            proxy?[kCFNetworkProxiesHTTPProxy as AnyHashable] = proxyHost!
            proxy?[kCFNetworkProxiesHTTPPort as AnyHashable] = proxyPort!
        }
        manager.session.configuration.connectionProxyDictionary = proxy
    }
    
    fileprivate func getTicket(lt: String, execution: String) {
        let parameters: [String:String] = [
            "lt": lt,
            "execution": execution,
            "_eventId": "submit",
            "username": username,
            "password": password
        ]
        
        manager.request(PGoEndpoint.LoginInfo, method: .post, parameters: parameters, encoding: URLEncoding(destination: .httpBody))
            .responseData { response in
                if let location = response.response!.allHeaderFields["Location"] as? String {
                    let ticketRange = location.range(of: "?ticket=")
                    
                    // response will occasionally come back with no ticket arg
                    if ticketRange == nil {
                        self.delegate?.didNotReceiveAuth()
                    } else {
                        let ticket = String(location.characters.suffix(from: ticketRange!.upperBound))
                        self.loginOAuth(ticket)
                    }
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    fileprivate func loginOAuth(_ ticket: String) {
        let parameters: [String:String] = [
            "client_id": "mobile-app_pokemon-go",
            "redirect_uri": "https://www.nianticlabs.com/pokemongo/error",
            "client_secret": "w8ScCUXJQc6kXKw8FiOhd8Fixzht18Dq3PEVkUCP5ZPxtgyWsbTvWHFLm2wNY0JR",
            "grant_type": "refresh_token",
            "code": ticket
        ]
        
        self.cleanCookies()
        
        manager.request(PGoEndpoint.LoginOAuth, method: .post, parameters: parameters, encoding: URLEncoding(destination: .httpBody))
            .responseString { response in
                let value = response.result.value!
                let regex = try! NSRegularExpression(pattern: "access_token=([A-Za-z0-9\\-.]+)&expires=([0-9]+)", options: [])
                let matches = regex.matches(in: value, options: [], range: NSRange(location: 0, length: value.utf16.count))
                
                guard let matchResult = matches.first else {
                    self.delegate?.didNotReceiveAuth()
                    return
                }
                
                // Extract the access_token
                let atRange = matchResult.rangeAt(1)
                let atSwiftRange = atRange.rangeForString(value)!
                self.accessToken = value.substring(with: atSwiftRange)
                
                // Extract the expires
                let eRange = matchResult.rangeAt(2)
                let eSwiftRange = eRange.rangeForString(value)!
                self.expires = Int(value.substring(with: eSwiftRange))
                
                self.loggedIn = true
                self.delegate?.didReceiveAuth()
        }
    }
    
    fileprivate func cleanCookies() {
        if let cookies = manager.session.configuration.httpCookieStorage?.cookies {
            for cookie in cookies {
                manager.session.configuration.httpCookieStorage?.deleteCookie(cookie)
            }
        }
    }
    
    open func login(withUsername username:String, withPassword password:String) {
        self.username = username
        self.password = password
        
        self.cleanCookies()
        
        let delegate = manager.delegate
        delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
            return nil
        }
        
        let headers = [
            "User-Agent": "niantic"
        ]
        
        manager.request(PGoEndpoint.LoginInfo, headers: headers)
            .responseJSON { response in
                if let JSON = response.result.value as? [String:Any] {
                    let lt = JSON["lt"] as! String
                    let execution = JSON["execution"] as! String
                    
                    self.getTicket(lt: lt, execution: execution)
                }
        }
    }
}
