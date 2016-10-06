//
//  GPSOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Created by Brian Barton on 9/4/16.
//  
//

import Foundation
import Alamofire


open class GPSOAuth: PGoAuth {
    static open let LOGIN_URL = "https://accounts.google.com/o/oauth2/auth?client_id=848232511240-73ri3t7plvk96pj4f85uj8otdat2alem.apps.googleusercontent.com&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&scope=openid%20email%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email"
    fileprivate let OAUTH_TOKEN_ENDPOINT = "https://www.googleapis.com/oauth2/v4/token"
    fileprivate let SECRET = "NCjF1TLi2CcY6t5mt0ZveuL7"
    fileprivate let CLIENT_ID = "848232511240-73ri3t7plvk96pj4f85uj8otdat2alem.apps.googleusercontent.com"
    
    fileprivate let baseParams = [
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
    
    fileprivate let headers = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    open var email: String!
    open var password: String!
    open var token: String?
    open var accessToken: String?
    open var expires: Int?
    open var expired: Bool = false
    open var loggedIn: Bool = false
    open var delegate: PGoAuthDelegate?
    open var authType: PGoAuthType = .google
    open var endpoint: String = PGoEndpoint.Rpc
    open var authToken: Pogoprotos.Networking.Envelopes.AuthTicket?
    open var manager: SessionManager
    open var banned: Bool = false
    fileprivate var refreshToken: String?

    public init(proxyHost: String? = nil, proxyPort: Int? = nil) {
        let configuration = URLSessionConfiguration.default
        if proxyHost != nil && proxyPort != nil {
            var proxyConfiguration = [NSObject: Any]()
            proxyConfiguration[kCFNetworkProxiesHTTPProxy] = proxyHost!
            proxyConfiguration[kCFNetworkProxiesHTTPPort] = proxyPort!
            proxyConfiguration[kCFNetworkProxiesHTTPEnable] = true
            configuration.connectionProxyDictionary = proxyConfiguration
        }
        manager = Alamofire.SessionManager(configuration: configuration)
    }
    
    public func disableProxy() {
        var proxy = manager.session.configuration.connectionProxyDictionary
        proxy?[kCFNetworkProxiesHTTPEnable as AnyHashable] = false
        manager.session.configuration.connectionProxyDictionary = proxy
    }
    
    public func enableProxy(proxyHost: String? = nil, proxyPort: Int? = nil) {
        var proxy = manager.session.configuration.connectionProxyDictionary
        proxy?[kCFNetworkProxiesHTTPEnable as AnyHashable] = true
        if proxyHost != nil && proxyPort != nil {
            proxy?[kCFNetworkProxiesHTTPProxy as AnyHashable] = proxyHost!
            proxy?[kCFNetworkProxiesHTTPPort as AnyHashable] = proxyPort!
        }
        manager.session.configuration.connectionProxyDictionary = proxy
    }
    
    fileprivate func parseKeyValues(_ body:String) -> Dictionary<String, String> {
        var obj = [String:String]()
        let bodySplit = body.components(separatedBy: "\n")
        for values in bodySplit {
            var keysValues = values.components(separatedBy: "=")
            if keysValues.count >= 2 {
                obj[keysValues[0]] = keysValues[1]
            }
        }
        return obj;
    }
    
    fileprivate func getTicket() {
        var params: [String:String] = baseParams
        params["Email"] = self.email
        params["Passwd"] = self.password
        params["service"] = "ac2dm"
        
        manager.request(PGoEndpoint.GoogleLogin, method: .post, parameters: params, encoding: URLEncoding(destination: .httpBody), headers: headers)
            .responseJSON { (response) in
                let responseString = String(data: response.data!, encoding: String.Encoding.utf8)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Token"] != nil {
                    self.loginOAuth(googleDict["Token"]!)
                    self.token = googleDict["Token"]
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    fileprivate func loginOAuth(_ token: String) {
        var params: [String:String]  = baseParams
        params["Email"] = self.email
        params["EncryptedPasswd"] = token
        params["service"] = "audience:server:client_id:848232511240-7so421jotr2609rmqakceuu1luuq0ptb.apps.googleusercontent.com"
        params["app"] = "com.nianticlabs.pokemongo"
        params["client_sig"] = "321187995bc7cdc2b5fc91b11a96e2baa8602c62"
        
        manager.request(PGoEndpoint.GoogleLogin, method: .post, parameters: params, encoding: URLEncoding(destination: .httpBody), headers: headers).responseJSON { (response) in
                let responseString = String(data: response.data!, encoding: String.Encoding.utf8)
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
    
    fileprivate func cleanCookies() {
        if let cookies = manager.session.configuration.httpCookieStorage?.cookies {
            for cookie in cookies {
                manager.session.configuration.httpCookieStorage?.deleteCookie(cookie)
            }
        }
    }
    
    open func login(withUsername username: String, withPassword password: String) {
        self.email = username.trimmingCharacters(in: CharacterSet.whitespaces)
        self.password = password
        
        self.cleanCookies()
        
        self.getTicket()
    }
    
    fileprivate func refreshAccessToken() {
        manager.request(OAUTH_TOKEN_ENDPOINT, method: .post, parameters: [
            "client_id": CLIENT_ID,
            "client_secret": SECRET,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken!
            ]).validate().responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? NSDictionary,
                        let token = json["id_token"] as? String,
                        let expiresIn = json["expires_in"] as? Int? {
                        self.authToken = nil
                        self.accessToken = token
                        self.expires = expiresIn
                        self.expired = false
                        self.delegate?.didReceiveAuth()
                    } else {
                        self.delegate?.didNotReceiveAuth()
                    }
                case .failure:
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    // username is not used and password is oauth code user receives after approving access
    open func login(withToken token: String) {
        // refresh the token if it has expired
        if loggedIn && expired {
            refreshAccessToken()
            return
        }
        
        manager.request(OAUTH_TOKEN_ENDPOINT, method: .post, parameters: [
            "code": token,
            "client_id": CLIENT_ID,
            "client_secret": SECRET,
            "grant_type": "authorization_code",
            "scope": "openid email https://www.googleapis.com/auth/userinfo.email",
            "redirect_uri": "urn:ietf:wg:oauth:2.0:oob"
            ]).validate().responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? NSDictionary,
                        let idToken = json["id_token"] as? String,
                        let refreshToken = json["refresh_token"] as? String,
                        let expires = json["expires_in"] as? Int {
                        self.accessToken = idToken
                        self.refreshToken = refreshToken
                        self.loggedIn = true
                        self.expires = expires
                        self.delegate?.didReceiveAuth()
                    } else {
                        self.delegate?.didNotReceiveAuth()
                    }
                case .failure:
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }

}
