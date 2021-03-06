//
//  Constant.swift
//  Xchangerator
//
//  Created by 张一唯 on 2020-02-24.
//  Copyright © 2020 YYES. All rights reserved.
//

enum Constant {
    // Xchangerator Server API
    static let xAPIGetLatest = "https://xchangerator.com/api/latest"

    // DB alert ratio for computation
    static let xScaleNum = 100.00 // don't set it to 0

    // Logger
    static let xLogFileName = "XChangeratorLog.log"
    static let maxAlertsForFree = 5

    // DB
    static let xDBtokenPrefix = "V1_"
    static let xDBnotiSuffix = "_notif_"
    static let xDBuserCollection = "users"
    static let xDBnotiCollection = "notifications"

    // Asset
    static let xAvatarPlaceholder = "https://pbs.twimg.com/profile_images/1218947796671324162/oWGgRsyn_400x400.jpg"
    static let xAvatarLogo = "https://media-exp1.licdn.com/dms/image/C560BAQF61rdZs2O6iA/company-logo_200_200/0?e=1594252800&v=beta&t=l4ie7PKFqkKDByG06arn1wNloOdLF8jvQINvtHs452A"

    // Website link
    static let xLinkedIn = "https://www.linkedin.com/company/xchangerator/"

    // description
    static let xDesc = """
    A free tool for conversion and notification of foreign exchange rates:
    · Mobile notification on demand
    · Conversion calculation on the go
    · Ad free 
    """
    static let xDescFav = """
    · Add your favorite currencies from Home page.
    · Exchange rates update for every one hour
    · Or click the star to remove.
    """

    // Color
    static let cardActive = 0x448AFF
    static let cardDisabled = 0x607D8B
    static let cardHighlight = 0x64FFFD
}

// For Previews
enum ConstantDevices {
    static let iPhone11ProMax = "iPhone 11 Pro Max"
    static let iPhoneSE = "iPhone SE"
    static let iPhone8 = "iPhone 8"
    static let iPadPro = "iPad Pro (12.9-inch) (4th generation)"
    static let iPad = "iPad (7th generation)"
    static let AllDevices = [iPhoneSE, iPhone11ProMax, iPadPro, iPad]
    static let AlliPhones = [iPhoneSE, iPhone8, iPhone11ProMax]
}
