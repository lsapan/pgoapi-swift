//
//  RPC.swift
//  pgomap
//
//  Based on https://github.com/tejado/pgoapi/blob/master/pgoapi/rpc_api.py
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire
import ProtocolBuffers


class PGoRpcApi {
    let intent: PGoApiIntent
    let auth: PGoAuth
    let delegate: PGoApiDelegate?
    let subrequests: [PGoApiMethod]
    let api: PGoApiRequest
    
    init(subrequests: [PGoApiMethod], intent: PGoApiIntent, auth: PGoAuth, api: PGoApiRequest, delegate: PGoApiDelegate?) {
        // TODO: Eventually use a custom session
        // Add "Niantic App" as the User-Agent
        let manager = Manager.sharedInstance
        manager.session.configuration.HTTPAdditionalHeaders = [
            "User-Agent": "Niantic App"
        ]
        
        self.subrequests = subrequests
        self.intent = intent
        self.auth = auth
        self.delegate = delegate
        self.api = api
    }
    
    func request() {
        // TODO: Eventually update this function to take playerPosition, and pass to buildMainRequest
        let requestData = buildMainRequest().data()
        
        Alamofire.request(.POST, auth.endpoint, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.HTTPBody = requestData
            return (mutableRequest, nil)
        })).responseData { response in
            let statusCode = response.response?.statusCode
            if statusCode != 200 {
                print("Unexpected response code, should be 200, got \(statusCode)")
                self.delegate?.didReceiveApiError(self.intent, statusCode: statusCode)
                return
            }
            
            print("Got a response!")
            self.delegate?.didReceiveApiResponse(self.intent, response: self.parseMainResponse(response.result.value!))
        }
    }
    
    private func buildMainRequest() -> Pogoprotos.Networking.Envelopes.RequestEnvelope {
        print("Generating main request...")
        let requestBuilder = Pogoprotos.Networking.Envelopes.RequestEnvelope.Builder()
        requestBuilder.statusCode = 2
        requestBuilder.requestId = PGoSetting.id
        requestBuilder.unknown12 = 1431
                
        requestBuilder.latitude = self.api.Location.lat
        requestBuilder.longitude = self.api.Location.long
        if self.api.Location.alt != nil {
            requestBuilder.altitude = self.api.Location.alt!
        }
        
        if (auth.authToken == nil) {
            let authInfoBuilder = requestBuilder.getAuthInfoBuilder()
            let authInfoTokenBuilder = authInfoBuilder.getTokenBuilder()
            authInfoBuilder.provider = auth.authType.description
            authInfoTokenBuilder.contents = auth.accessToken!
            authInfoTokenBuilder.unknown2 = 10800
        } else {
            requestBuilder.authTicket = auth.authToken!
        }
        
        print("Generating subrequests...")
        for subrequest in subrequests {
            print("Processing \(subrequest)...")
            let subrequestBuilder = Pogoprotos.Networking.Requests.Request.Builder()
            subrequestBuilder.requestType = subrequest.id
            subrequestBuilder.requestMessage = subrequest.message.data()
            requestBuilder.requests += [try! subrequestBuilder.build()]
        }
        
        print("Building request...")
        return try! requestBuilder.build()
    }
    
    private func parseMainResponse(data: NSData) -> PGoApiResponse {
        print("Parsing main response...")
        
        let response = try! Pogoprotos.Networking.Envelopes.ResponseEnvelope.parseFromData(data)
        let subresponses = parseSubResponses(response)
        return PGoApiResponse(response: response, subresponses: subresponses)
    }
    
    private func parseSubResponses(response: Pogoprotos.Networking.Envelopes.ResponseEnvelope) -> [GeneratedMessage] {
        print("Parsing subresponses...")
        
        var subresponses: [GeneratedMessage] = []
        for (idx, subresponseData) in response.returns.enumerate() {
            let subrequest = subrequests[idx]
            subresponses.append(subrequest.parser(subresponseData))
        }
        return subresponses
    }
    
}