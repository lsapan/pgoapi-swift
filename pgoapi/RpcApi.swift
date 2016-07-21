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


class RpcApi {
    let intent: ApiIntent
    let delegate: PGoApiDelegate?
    let subrequests: [ApiMethod]

    init(subrequests: [ApiMethod], intent: ApiIntent, delegate: PGoApiDelegate?) {
        // TODO: Eventually use a custom session
        // Add "Niantic App" as the User-Agent
        let manager = Manager.sharedInstance
        manager.session.configuration.HTTPAdditionalHeaders = [
            "User-Agent": "Niantic App"
        ]

        self.subrequests = subrequests
        self.intent = intent
        self.delegate = delegate
    }

    func request(endpoint: String) {
        // TODO: Eventually update this function to take playerPosition, and pass to buildMainRequest
        let requestData = buildMainRequest().data()

        Alamofire.request(.POST, endpoint, parameters: [:], encoding: .Custom({
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
        requestBuilder.requestId = Api.id
        requestBuilder.unknown12 = 989

        // TODO: Add playerPosition if it is available
        // requestBuilder.latitude = location.latitude
        // requestBuilder.longitude = location.longitude
        // requestBuilder.altitude = location.altitude

        let authInfoBuilder = requestBuilder.getAuthInfoBuilder()
        authInfoBuilder.provider = "ptc"
        let authInfoTokenBuilder = authInfoBuilder.getTokenBuilder()
        authInfoTokenBuilder.contents = Auth.sharedInstance.accessToken!
        authInfoTokenBuilder.unknown2 = 59

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

    private func parseMainResponse(data: NSData) -> ApiResponse {
        print("Parsing main response...")

        let response = try! Pogoprotos.Networking.Envelopes.ResponseEnvelope.parseFromData(data)
        let subresponses = parseSubResponses(response)
        return ApiResponse(response: response, subresponses: subresponses)
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
