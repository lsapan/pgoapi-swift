//
//  PgoApi.swift
//  pgomap
//
//  Based on https://github.com/tejado/pgoapi/blob/master/pgoapi/pgoapi.py
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import ProtocolBuffers


struct ApiMethod {
    let id: Pogoprotos.Networking.Requests.RequestType
    let message: GeneratedMessage
    let parser: NSData -> GeneratedMessage
}

struct ApiResponse {
    let response: GeneratedMessage
    let subresponses: [GeneratedMessage]
}

class PGoApiRequest {
    var methodList: [ApiMethod] = []

    func makeRequest(intent: ApiIntent, delegate: PGoApiDelegate?) {  // analogous to call in pgoapi.py
        if methodList.count == 0 {
            print("makeRequest() called without any methods in methodList.")
            return
        }

        if !Auth.sharedInstance.loggedIn {
            print("makeRequest() called without being logged in.")
            return
        }

        // TODO: Get player position
        // position stuff here...
        let request = RpcApi(subrequests: methodList, intent: intent, delegate: delegate)
        request.request(Api.endpoint)
    }

    func simulateAppStart() {
        getPlayer()
        getHatchedEggs()
        getInventory()
        checkAwardedBadges()
        downloadSettings()
    }

    func getPlayer() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetPlayerMessage.Builder()
        methodList.append(ApiMethod(id: .GetPlayer, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetPlayerResponse.parseFromData(data)
        }))
    }

    func getHatchedEggs() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetHatchedEggsMessage.Builder()
        methodList.append(ApiMethod(id: .GetHatchedEggs, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetHatchedEggsResponse.parseFromData(data)
        }))
    }

    func getInventory() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetInventoryMessage.Builder()
        methodList.append(ApiMethod(id: .GetInventory, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetInventoryResponse.parseFromData(data)
        }))
    }

    func checkAwardedBadges() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckAwardedBadgesMessage.Builder()
        methodList.append(ApiMethod(id: .CheckAwardedBadges, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse.parseFromData(data)
        }))
    }

    func downloadSettings() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadSettingsMessage.Builder()
        messageBuilder.hash = Api.SettingsHash
        methodList.append(ApiMethod(id: .DownloadSettings, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadSettingsResponse.parseFromData(data)
        }))
    }

    func getMapObjects(latitude: Double, longitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetMapObjectsMessage.Builder()
        messageBuilder.latitude = latitude
        messageBuilder.longitude = longitude
        methodList.append(ApiMethod(id: .GetMapObjects, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetMapObjectsResponse.parseFromData(data)
        }))
    }
}
