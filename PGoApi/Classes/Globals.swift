//
//  Globals.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


internal struct PGoVersion {
    internal static let versionHash: Int64 = -1553869577012279119
    internal static let versionString: String = "0.45.0"
    internal static let versionInt: UInt32 = 4500
    internal static let HASH_SEED: UInt32 = 0x46E945F8
}

internal struct PGoEndpoint {
    internal static let LoginInfo = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    internal static let LoginTicket = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    internal static let LoginOAuth = "https://sso.pokemon.com/sso/oauth2.0/accessToken"
    internal static var LoginProvider:PGoAuthType = .ptc
    internal static let Rpc = "https://pgorelease.nianticlabs.com/plfe/rpc"
    internal static let GoogleLogin = "https://android.clients.google.com/auth"
}

public enum PGoApiIntent {
    case login
    case simulateAppStart
    case heartBeat
    case playerUpdate
    case getPlayer
    case getInventory
    case downloadSettings
    case downloadItemTemplates
    case downloadRemoteConfigVersion
    case fortSearch
    case encounterPokemon
    case catchPokemon
    case fortDetails
    case itemUse
    case getMapObjects
    case fortDeployPokemon
    case fortRecallPokemon
    case releasePokemon
    case useItemPotion
    case useItemCapture
    case useItemFlee
    case useItemRevive
    case tradeSearch
    case tradeOffer
    case tradeResponse
    case tradeResult
    case getPlayerProfile
    case getItemPack
    case buyItemPack
    case buyGemPack
    case evolvePokemon
    case getHatchedEggs
    case encounterTutorialComplete
    case levelUpRewards
    case checkAwardedBadges
    case useItemGym
    case getGymDetails
    case startGymBattle
    case attackGym
    case recycleInventoryItem
    case collectDailyBonus
    case useItemXpBoost
    case useItemEggIncubator
    case useIncense
    case getIncensePokemon
    case incenseEncounter
    case addFortModifier
    case diskEncounter
    case collectDailyDefenderBonus
    case upgradePokemon
    case setFavoritePokemon
    case nicknamePokemon
    case equipBadge
    case setContactSettings
    case getAssetDigest
    case getDownloadUrls
    case getSuggestedCodenames
    case checkCodenameAvailable
    case claimCodename
    case setAvatar
    case setPlayerTeam
    case markTutorialComplete
    case loadSpawnPoints
    case echo
    case debugUpdateInventory
    case debugDeletePlayer
    case sfidaRegistration
    case sfidaActionLog
    case sfidaCertification
    case sfidaUpdate
    case sfidaAction
    case sfidaDowser
    case sfidaCapture
    case getBuddyWalked
    case setBuddyPokemon
    case verifyChallenge
    case registerBackgroundDevice
}

public enum PGoAuthType: CustomStringConvertible {
    case google
    case ptc
    
    public var description: String {
        switch self {
        case .google: return "google"
        case .ptc: return "ptc"
        }
    }
}
