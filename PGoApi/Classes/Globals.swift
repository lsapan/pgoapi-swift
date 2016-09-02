//
//  Globals.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


public struct PGoEndpoint {
    public static let LoginInfo = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    public static let LoginTicket = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    public static let LoginOAuth = "https://sso.pokemon.com/sso/oauth2.0/accessToken"
    public static var LoginProvider:PGoAuthType = .Ptc
    public static let Rpc = "https://pgorelease.nianticlabs.com/plfe/rpc"
    public static let GoogleLogin = "https://android.clients.google.com/auth"
}

public enum PGoApiIntent {
    case Login
    case SimulateAppStart
    case HeartBeat
    case PlayerUpdate
    case GetPlayer
    case GetInventory
    case DownloadSettings
    case DownloadItemTemplates
    case DownloadRemoteConfigVersion
    case FortSearch
    case EncounterPokemon
    case CatchPokemon
    case FortDetails
    case ItemUse
    case GetMapObjects
    case FortDeployPokemon
    case FortRecallPokemon
    case ReleasePokemon
    case UseItemPotion
    case UseItemCapture
    case UseItemFlee
    case UseItemRevive
    case TradeSearch
    case TradeOffer
    case TradeResponse
    case TradeResult
    case GetPlayerProfile
    case GetItemPack
    case BuyItemPack
    case BuyGemPack
    case EvolvePokemon
    case GetHatchedEggs
    case EncounterTutorialComplete
    case LevelUpRewards
    case CheckAwardedBadges
    case UseItemGym
    case GetGymDetails
    case StartGymBattle
    case AttackGym
    case RecycleInventoryItem
    case CollectDailyBonus
    case UseItemXpBoost
    case UseItemEggIncubator
    case UseIncense
    case GetIncensePokemon
    case IncenseEncounter
    case AddFortModifier
    case DiskEncounter
    case CollectDailyDefenderBonus
    case UpgradePokemon
    case SetFavoritePokemon
    case NicknamePokemon
    case EquipBadge
    case SetContactSettings
    case GetAssetDigest
    case GetDownloadUrls
    case GetSuggestedCodenames
    case CheckCodenameAvailable
    case ClaimCodename
    case SetAvatar
    case SetPlayerTeam
    case MarkTutorialComplete
    case LoadSpawnPoints
    case Echo
    case DebugUpdateInventory
    case DebugDeletePlayer
    case SfidaRegistration
    case SfidaActionLog
    case SfidaCertification
    case SfidaUpdate
    case SfidaAction
    case SfidaDowser
    case SfidaCapture
    //case getBuddyWalked
    //case setBuddyPokemon
    case checkChallenge
    case verifyChallenge
}

public struct PGoDeviceInfo {
    public var deviceId = NSData.randomBytes(8).getHexString
    public var androidBoardName: String? = "universal8890"
    public var androidBootloader: String? = "unknown"
    public var deviceBrand: String? = "samsung"
    public var deviceModel: String? = "herolte"
    public var deviceModelIdentifier: String? = "MMB29K.G930FXXU1APC8"
    public var deviceModelBoot: String? = "unknown"
    public var hardwareManufacturer: String? = "samsung"
    public var hardwareModel: String? = "SM-G930F"
    public var firmwareBrand: String? = "heroltexx"
    public var firmwareTags: String? = "release-keys"
    public var firmwareType: String? = "user"
    public var firmwareFingerprint: String? = "samsung/heroltexx/herolte:6.0.1/MMB29K/G930FXXU1APC8:user/release-keys"
    public init() {}
}

public enum PGoAuthType: CustomStringConvertible {
    case Google
    case Ptc
    
    public var description: String {
        switch self {
        case .Google: return "google"
        case .Ptc: return "ptc"
        }
    }
}