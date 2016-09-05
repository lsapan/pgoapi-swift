//
//  PtcOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire

public class PtcOAuth: PGoAuth {
    public var username: String!
    public var password: String!
    public var accessToken: String?
    public var expires: Int?
    public var expired: Bool = false
    public var loggedIn: Bool = false
    public var delegate: PGoAuthDelegate?
    public let authType: PGoAuthType = .Ptc
    public var endpoint: String = PGoEndpoint.Rpc
    public var authToken: Pogoprotos.Networking.Envelopes.AuthTicket?
    public var manager: Manager
    public var banned: Bool = false
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        manager = Alamofire.Manager(configuration: configuration)
    }
    
    private func getTicket(lt: String, execution: String) {
        print("Requesting ticket...")
        
        let parameters = [
            "lt": lt,
            "execution": execution,
            "_eventId": "submit",
            "username": username,
            "password": password
        ]
        
        manager.request(.POST, PGoEndpoint.LoginInfo, parameters: parameters)
            .responseData { response in
                if let location = response.response!.allHeaderFields["Location"] as? String {
                    let ticketRange = location.rangeOfString("?ticket=")
                    let ticket = String(location.characters.suffixFrom(ticketRange!.endIndex))
                    
                    self.loginOAuth(ticket)
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    private func loginOAuth(ticket: String) {
        print("Logging in via OAuth...")
        
        let parameters = [
            "client_id": "mobile-app_pokemon-go",
            "redirect_uri": "https://www.nianticlabs.com/pokemongo/error",
            "client_secret": "w8ScCUXJQc6kXKw8FiOhd8Fixzht18Dq3PEVkUCP5ZPxtgyWsbTvWHFLm2wNY0JR",
            "grant_type": "refresh_token",
            "code": ticket
        ]
        
        // Remove "niantic" from the User-Agent
        manager.session.configuration.HTTPAdditionalHeaders = [:]
        
        // Clean cookies, credit to github.com/aipeople
        if let cookies = manager.session.configuration.HTTPCookieStorage?.cookies {
            for cookie in cookies {
                manager.session.configuration.HTTPCookieStorage?.deleteCookie(cookie)
            }
        }
        
        manager.request(.POST, PGoEndpoint.LoginOAuth, parameters: parameters)
            .responseString { response in
                let value = response.result.value!
                let regex = try! NSRegularExpression(pattern: "access_token=([A-Za-z0-9\\-.]+)&expires=([0-9]+)", options: [])
                let matches = regex.matchesInString(value, options: [], range: NSRange(location: 0, length: value.utf16.count))
                
                guard let matchResult = matches.first else {
                    self.delegate?.didNotReceiveAuth()
                    return
                }
                
                // Extract the access_token
                let atRange = matchResult.rangeAtIndex(1)
                let atSwiftRange = atRange.rangeForString(value)!
                self.accessToken = value.substringWithRange(atSwiftRange)
                
                // Extract the expires
                let eRange = matchResult.rangeAtIndex(2)
                let eSwiftRange = eRange.rangeForString(value)!
                self.expires = Int(value.substringWithRange(eSwiftRange))
                
                self.loggedIn = true
                self.delegate?.didReceiveAuth()
        }
    }
    
    public func login(withUsername username:String, withPassword password:String) {
        print("Starting login...")
        self.username = username
        self.password = password
        
        let delegate = manager.delegate
        delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
            return nil
        }
        
        manager.session.configuration.HTTPAdditionalHeaders = [
            "User-Agent": "niantic"
        ]
        
        manager.request(.GET, PGoEndpoint.LoginInfo)
            .responseJSON { response in
                if let JSON = response.result.value {
                    let lt = JSON["lt"] as! String
                    let execution = JSON["execution"] as! String
                    
                    self.getTicket(lt, execution: execution)
                }
        }
    }
    
    public func login(withToken token: String) {
        self.delegate?.didNotReceiveAuth()
    }
}
