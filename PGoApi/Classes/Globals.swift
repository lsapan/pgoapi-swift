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

public struct PGoSetting {
    public static let id: UInt64 = 8145806132888207460
    public static let SettingsHash = "05daf51635c82611d1aac95c0b051d3ec088a930"
}

public enum PGoApiIntent {
    case Login
    case SimulateAppStart
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
