//
//  GPSOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire

public class GPSOAuth: PGoAuth {
    
    private let baseParams = [
        "accountType": "HOSTED_OR_GOOGLE",
        "has_permission": "1",
        "add_account": "1",
        "source": "android",
        "androidId": "9774d56d682e549c",
        "device_country": "us",
        "operatorCountry": "us",
        "lang": "en",
        "sdk_version": "17"
    ]
    
    private let headers = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    public var email: String!
    public var password: String!
    public var token: String?
    public var accessToken: String?
    public var expires: Int?
    public var loggedIn: Bool = false
    public var delegate: PGoAuthDelegate?
    public var authType: PGoAuthType = .Google
    public var endpoint: String = PGoEndpoint.Rpc
    public var authToken: Pogoprotos.Networking.Envelopes.AuthTicket?
    
    public init() {}
    
    private func parseKeyValues(body:String) -> Dictionary<String, String> {
        var obj = [String:String]()
        let bodySplit = body.componentsSeparatedByString("\n")
        for values in bodySplit {
            var keysValues = values.componentsSeparatedByString("=")
            obj[keysValues[0]] = keysValues[1]
        }
        return obj;
    }
    
    private func getTicket() {
        var params = baseParams
        params["Email"] = self.email
        params["Passwd"] = self.password
        params["service"] = "ac2dm"
        
        Alamofire.request(.POST, PGoEndpoint.GoogleLogin, parameters: params, headers: headers, encoding: .URLEncodedInURL)
            .responseJSON { (response) in
                let responseString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Token"] != nil {
                    self.loginOAuth(googleDict["Token"]!)
                    self.token = googleDict["Token"]
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    private func loginOAuth(token: String) {
        var params = baseParams
        params["Email"] = self.email
        params["EncryptedPasswd"] = token
        params["service"] = "audience:server:client_id:848232511240-7so421jotr2609rmqakceuu1luuq0ptb.apps.googleusercontent.com"
        params["app"] = "com.nianticlabs.pokemongo"
        params["client_sig"] = "321187995bc7cdc2b5fc91b11a96e2baa8602c62"
        
        Alamofire.request(.POST, PGoEndpoint.GoogleLogin, parameters: params, headers: headers, encoding: .URLEncodedInURL)
            .responseJSON { (response) in
                let responseString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Auth"] != nil {
                    self.accessToken = googleDict["Auth"]!
                    self.expires = Int(googleDict["Expiry"]!)!
                    self.loggedIn = true
                    self.delegate?.didReceiveAuth()
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    public func login(withUsername username: String, withPassword password: String) {
        self.email = username.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        self.password = password

        self.getTicket()
    }
}