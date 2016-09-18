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


internal class PGoRpcApi {
    fileprivate let intent: PGoApiIntent
    fileprivate var auth: PGoAuth
    fileprivate let delegate: PGoApiDelegate?
    fileprivate let subrequests: [PGoApiMethod]
    fileprivate let api: PGoApiRequest
    fileprivate var manager: SessionManager?
    fileprivate var responseObject: PGoResponseObject?
    fileprivate var unknown6Builder: platformRequest?
    fileprivate let headers = [
        "User-Agent": "Niantic App"
    ]
    
    internal init(subrequests: [PGoApiMethod], intent: PGoApiIntent, auth: PGoAuth, api: PGoApiRequest, delegate: PGoApiDelegate?) {
        manager = auth.manager
        
        self.subrequests = subrequests
        self.intent = intent
        self.auth = auth
        self.delegate = delegate
        self.api = api
        self.unknown6Builder = platformRequest(auth: auth, api: api)
        if self.api.ApiSettings.useResponseObjects {
            self.responseObject = PGoResponseObject()
        }
    }
    
    internal func request() {
        let requestData = buildMainRequest().data()
        let params:[String:Data] = [:]
        
        manager?.request(auth.endpoint, method: .post, parameters: params, encoding: BinaryEncoding(data: requestData), headers: headers).responseData { response in
            let statusCode = response.response?.statusCode
            if statusCode != 200 {
                self.api.debugMessage("Unexpected response code, should be 200, got \(statusCode)")
                self.delegate?.didReceiveApiError(self.intent, statusCode: statusCode)
                return
            }
            
            self.api.debugMessage("Got a response!")
            self.delegate?.didReceiveApiResponse(self.intent, response: self.parseMainResponse(response.result.value!))
        }
    }
    
    fileprivate func buildMainRequest() -> Pogoprotos.Networking.Envelopes.RequestEnvelope {
        self.api.debugMessage("Generating main request...")
        
        let requestBuilder = Pogoprotos.Networking.Envelopes.RequestEnvelope.Builder()
        requestBuilder.statusCode = 2
        requestBuilder.requestId = self.api.session.requestId
        
        requestBuilder.latitude = self.api.Location.lat
        requestBuilder.longitude = self.api.Location.long
        requestBuilder.accuracy = self.api.Location.horizontalAccuracy
        
        self.api.debugMessage("Generating subrequests...")
        for subrequest in subrequests {
            self.api.debugMessage("Processing \(subrequest)...")
            let subrequestBuilder = Pogoprotos.Networking.Requests.Request.Builder()
            subrequestBuilder.requestType = subrequest.id
            subrequestBuilder.requestMessage = subrequest.message.data()
            let subData = try! subrequestBuilder.build()
            requestBuilder.requests += [subData]
            if auth.authToken != nil {
                unknown6Builder!.requestHashes.append(unknown6Builder!.hashRequest(subData.data()))
            }
        }
        
        if auth.authToken == nil {
            requestBuilder.authInfo = unknown6Builder!.generateAuthInfo()
        } else {
            requestBuilder.authTicket = auth.authToken!
        }
        
        requestBuilder.platformRequests = [unknown6Builder!.build()]
        
        self.api.session.requestId += 1
        
        if self.api.unknown6Settings.useLocationFix {
            requestBuilder.msSinceLastLocationfix = Int64(self.api.locationFix.timeStamp)
        } else {
            requestBuilder.msSinceLastLocationfix = Int64(UInt64.random(100, max: 300))
        }
                
        self.api.debugMessage("Building request...")
        return try! requestBuilder.build()
    }
    
    fileprivate func parseMainResponse(_ data: Data) -> PGoApiResponse {
        self.api.debugMessage("Parsing main response...")
        
        let response = try! Pogoprotos.Networking.Envelopes.ResponseEnvelope.parseFrom(data: data)
        
        if response.statusCode == .badRequest {
            self.auth.banned = true
            self.api.debugMessage("WARNING: Account may be banned.")
            self.delegate?.didReceiveApiException(intent, exception: .banned)
        } else if response.statusCode == .redirect {
            auth.endpoint = "https://\(response.apiUrl)/rpc"
            self.api.debugMessage("New endpoint: \(auth.endpoint)")
        } else if response.statusCode == .invalidAuthToken {
            self.api.debugMessage("Auth token is expired.")
            if (self.api.ApiSettings.refreshAuthTokens) {
                self.api.refreshAuthToken()
            } else {
                auth.expired = true
                self.delegate?.didReceiveApiException(intent, exception: .authTokenExpired)
            }
        } else if response.statusCode == .invalidRequest {
            self.api.debugMessage("Warning! Request was invalid.")
            self.delegate?.didReceiveApiException(intent, exception: .invalidRequest)
        } else if response.statusCode == .invalidPlatformRequest {
            self.api.debugMessage("Warning! Platform request is invalid. Try adding a delay of 10 seconds.")
            self.delegate?.didReceiveApiException(intent, exception: .delayRequired)
        } else if response.statusCode == .sessionInvalidated {
            self.api.debugMessage("Warning! Session is invalid.")
            self.delegate?.didReceiveApiException(intent, exception: .sessionInvalidated)
        } else if response.statusCode == .unknown {
            self.api.debugMessage("Warning! Unknown error.")
            self.delegate?.didReceiveApiException(intent, exception: .unknown)
        }
        
        if response.hasAuthTicket {
            auth.authToken = response.authTicket
        }
        
        let subresponses = parseSubResponses(response)
        return PGoApiResponse(response: response, subresponses: subresponses, object: responseObject)
    }
    
    fileprivate func setResponseObject(_ intent: Pogoprotos.Networking.Requests.RequestType, parsedData: GeneratedMessage) {
        switch intent {
        case .getPlayer:
            responseObject!.GetPlayer = parsedData as? Pogoprotos.Networking.Responses.GetPlayerResponse
        case .getInventory:
            responseObject!.GetInventory = parsedData as? Pogoprotos.Networking.Responses.GetInventoryResponse
        case .downloadSettings:
            responseObject!.DownloadSettings = parsedData as? Pogoprotos.Networking.Responses.DownloadSettingsResponse
        case .downloadItemTemplates:
            responseObject!.DownloadItemTemplates = parsedData as? Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse
        case .downloadRemoteConfigVersion:
            responseObject!.DownloadRemoteConfigVersion = parsedData as? Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse
        case .fortSearch:
            responseObject!.FortSearch = parsedData as? Pogoprotos.Networking.Responses.FortSearchResponse
        case .encounter:
            responseObject!.EncounterPokemon = parsedData as? Pogoprotos.Networking.Responses.EncounterResponse
        case .catchPokemon:
            responseObject!.CatchPokemon = parsedData as? Pogoprotos.Networking.Responses.CatchPokemonResponse
        case .fortDetails:
            responseObject!.FortDetails = parsedData as? Pogoprotos.Networking.Responses.FortDetailsResponse
        case .getMapObjects:
            responseObject!.GetMapObjects = parsedData as? Pogoprotos.Networking.Responses.GetMapObjectsResponse
        case .fortDeployPokemon:
            responseObject!.FortDeployPokemon = parsedData as? Pogoprotos.Networking.Responses.FortDeployPokemonResponse
        case .fortRecallPokemon:
            responseObject!.FortRecallPokemon = parsedData as? Pogoprotos.Networking.Responses.FortRecallPokemonResponse
        case .releasePokemon:
            responseObject!.ReleasePokemon = parsedData as? Pogoprotos.Networking.Responses.ReleasePokemonResponse
        case .useItemPotion:
            responseObject!.UseItemPotion = parsedData as? Pogoprotos.Networking.Responses.UseItemPotionResponse
        case .useItemCapture:
            responseObject!.UseItemCapture = parsedData as? Pogoprotos.Networking.Responses.UseItemCaptureResponse
        case .useItemRevive:
            responseObject!.UseItemRevive = parsedData as? Pogoprotos.Networking.Responses.UseItemReviveResponse
        case .getPlayerProfile:
            responseObject!.GetPlayerProfile = parsedData as? Pogoprotos.Networking.Responses.GetPlayerProfileResponse
        case .evolvePokemon:
            responseObject!.EvolvePokemon = parsedData as? Pogoprotos.Networking.Responses.EvolvePokemonResponse
        case .getHatchedEggs:
            responseObject!.GetHatchedEggs = parsedData as? Pogoprotos.Networking.Responses.GetHatchedEggsResponse
        case .encounterTutorialComplete:
            responseObject!.EncounterTutorialComplete = parsedData as? Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse
        case .levelUpRewards:
            responseObject!.LevelUpRewards = parsedData as? Pogoprotos.Networking.Responses.LevelUpRewardsResponse
        case .checkAwardedBadges:
            responseObject!.CheckAwardedBadges = parsedData as? Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse
        case .useItemGym:
            responseObject!.UseItemGym = parsedData as? Pogoprotos.Networking.Responses.UseItemGymResponse
        case .getGymDetails:
            responseObject!.GetGymDetails = parsedData as? Pogoprotos.Networking.Responses.GetGymDetailsResponse
        case .startGymBattle:
            responseObject!.StartGymBattle = parsedData as? Pogoprotos.Networking.Responses.StartGymBattleResponse
        case .attackGym:
            responseObject!.AttackGym = parsedData as? Pogoprotos.Networking.Responses.AttackGymResponse
        case .recycleInventoryItem:
            responseObject!.RecycleInventoryItem = parsedData as? Pogoprotos.Networking.Responses.RecycleInventoryItemResponse
        case .collectDailyBonus:
            responseObject!.CollectDailyBonus = parsedData as? Pogoprotos.Networking.Responses.CollectDailyBonusResponse
        case .useItemXpBoost:
            responseObject!.UseItemXpBoost = parsedData as? Pogoprotos.Networking.Responses.UseItemXpBoostResponse
        case .useItemEggIncubator:
            responseObject!.UseItemEggIncubator = parsedData as? Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse
        case .useIncense:
            responseObject!.UseIncense = parsedData as? Pogoprotos.Networking.Responses.UseIncenseResponse
        case .getIncensePokemon:
            responseObject!.GetIncensePokemon = parsedData as? Pogoprotos.Networking.Responses.GetIncensePokemonResponse
        case .incenseEncounter:
            responseObject!.IncenseEncounter = parsedData as? Pogoprotos.Networking.Responses.IncenseEncounterResponse
        case .addFortModifier:
            responseObject!.AddFortModifier = parsedData as? Pogoprotos.Networking.Responses.AddFortModifierResponse
        case .diskEncounter:
            responseObject!.DiskEncounter = parsedData as? Pogoprotos.Networking.Responses.DiskEncounterResponse
        case .collectDailyDefenderBonus:
            responseObject!.CollectDailyBonus = parsedData as? Pogoprotos.Networking.Responses.CollectDailyBonusResponse
        case .upgradePokemon:
            responseObject!.UpgradePokemon = parsedData as? Pogoprotos.Networking.Responses.UpgradePokemonResponse
        case .setFavoritePokemon:
            responseObject!.SetFavoritePokemon = parsedData as? Pogoprotos.Networking.Responses.SetFavoritePokemonResponse
        case .nicknamePokemon:
            responseObject!.NicknamePokemon = parsedData as? Pogoprotos.Networking.Responses.NicknamePokemonResponse
        case .equipBadge:
            responseObject!.EquipBadge = parsedData as? Pogoprotos.Networking.Responses.EquipBadgeResponse
        case .setContactSettings:
            responseObject!.SetContactSettings = parsedData as? Pogoprotos.Networking.Responses.SetContactSettingsResponse
        case .getAssetDigest:
            responseObject!.GetAssetDigest = parsedData as? Pogoprotos.Networking.Responses.GetAssetDigestResponse
        case .getDownloadUrls:
            responseObject!.GetDownloadUrls = parsedData as? Pogoprotos.Networking.Responses.GetDownloadUrlsResponse
        case .getSuggestedCodenames:
            responseObject!.GetSuggestedCodenames = parsedData as? Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse
        case .checkCodenameAvailable:
            responseObject!.CheckCodenameAvailable = parsedData as? Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse
        case .claimCodename:
            responseObject!.ClaimCodename = parsedData as? Pogoprotos.Networking.Responses.ClaimCodenameResponse
        case .setAvatar:
            responseObject!.SetAvatar = parsedData as? Pogoprotos.Networking.Responses.SetAvatarResponse
        case .setPlayerTeam:
            responseObject!.SetPlayerTeam = parsedData as? Pogoprotos.Networking.Responses.SetPlayerTeamResponse
        case .markTutorialComplete:
            responseObject!.MarkTutorialComplete = parsedData as? Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse
        case .echo:
            responseObject!.Echo = parsedData as? Pogoprotos.Networking.Responses.EchoResponse
        case .sfidaActionLog:
            responseObject!.SfidaActionLog = parsedData as? Pogoprotos.Networking.Responses.SfidaActionLogResponse
        case .checkChallenge:
            responseObject!.CheckChallenge = parsedData as? Pogoprotos.Networking.Responses.CheckChallengeResponse
        case .verifyChallenge:
            responseObject!.VerifyChallenge = parsedData as? Pogoprotos.Networking.Responses.VerifyChallengeResponse
        default:
            return
        }
    }
    
    fileprivate func parseSubResponses(_ response: Pogoprotos.Networking.Envelopes.ResponseEnvelope) -> [GeneratedMessage] {
        self.api.debugMessage("Parsing subresponses...")
        
        var subresponses: [GeneratedMessage] = []
        for (idx, subresponseData) in response.returns.enumerated() {
            let subrequest = subrequests[idx]
            let parsedData = subrequest.parser(subresponseData)
            subresponses.append(parsedData)
            if self.api.ApiSettings.useResponseObjects {
                if responseObject == nil {
                    responseObject = PGoResponseObject()
                }
                setResponseObject(subrequest.id, parsedData: parsedData)
            }
        }
        return subresponses
    }
}
