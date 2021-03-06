//
//  GiftVM.swift
//  AgoraLive
//
//  Created by CavanSu on 2020/4/9.
//  Copyright © 2020 Agora. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import AlamoClient

enum Gift: Int {
    case smallBell = 0, iceCream, wine, cake, ring, watch, crystal, rocket
    
    var description: String {
        switch self {
        case .smallBell: return NSLocalizedString("Small_Bell")
        case .iceCream:  return NSLocalizedString("Ice_Cream")
        case .wine:      return NSLocalizedString("Wine")
        case .cake:      return NSLocalizedString("Cake")
        case .ring:      return NSLocalizedString("Ring")
        case .watch:     return NSLocalizedString("Watch")
        case .crystal:   return NSLocalizedString("Crystal")
        case .rocket:    return NSLocalizedString("Rocket")
        }
    }
    
    var image: UIImage {
        switch self {
        case .smallBell: return UIImage(named: "gift-dang")!
        case .iceCream:  return UIImage(named: "gift-icecream")!
        case .wine:      return UIImage(named: "gift-wine")!
        case .cake:      return UIImage(named: "gift-cake")!
        case .ring:      return UIImage(named: "gift-ring")!
        case .watch:     return UIImage(named: "gift-watch")!
        case .crystal:   return UIImage(named: "gift-diamond")!
        case .rocket:    return UIImage(named: "gift-rocket")!
        }
    }
    
    var price: Int {
        switch self {
        case .smallBell: return 20
        case .iceCream:  return 30
        case .wine:      return 40
        case .cake:      return 50
        case .ring:      return 60
        case .watch:     return 70
        case .crystal:   return 80
        case .rocket:    return 90
        }
    }
    
    var hasGIF: Bool {
        switch self {
        case .smallBell: return true
        case .iceCream:  return true
        case .wine:      return true
        case .cake:      return true
        case .ring:      return true
        case .watch:     return true
        case .crystal:   return true
        case .rocket:    return true
        }
    }
    
    var gifFileName: String {
        switch self {
        case .smallBell: return "SuperBell"
        case .iceCream:  return "SuperIcecream"
        case .wine:      return "SuperWine"
        case .cake:      return "SuperCake"
        case .ring:      return "SuperRing"
        case .watch:     return "SuperWatch"
        case .crystal:   return "SuperDiamond"
        case .rocket:    return "SuperRocket"
        }
    }
    
    static var list: [Gift] = [.smallBell, .iceCream, .wine,
                               .cake, .ring, .watch, .crystal,
                               .rocket]
}

class GiftVM: NSObject {
    var received = PublishRelay<(userName:String, gift:Gift)>()
    
    override init() {
        super.init()
        observe()
    }
    
    func present(gift: Gift, to owner: BasicUserInfo, from local: BasicUserInfo, of room: String, fail: Completion) {
        let client = ALCenter.shared().centerProvideRequestHelper()
        
        let event = RequestEvent(name: "present-gift")
        let url = URLGroup.receivedGift(roomId: room)
        let task = RequestTask(event: event,
                               type: .http(.post, url: url),
                               timeout: .medium,
                               header: ["token": ALKeys.ALUserToken],
                               parameters: ["giftId": gift.rawValue, "count": 1])
        
        client.request(task: task, success: ACResponse.blank({ [weak self] in
            self?.received.accept((local.name, gift))
        }))
    }
    
    deinit {
        let rtm = ALCenter.shared().centerProvideRTMHelper()
        rtm.removeReceivedChannelMessage(observer: self)
    }
}

private extension GiftVM {
    func observe() {
        let rtm = ALCenter.shared().centerProvideRTMHelper()
        rtm.addReceivedChannelMessage(observer: self) { [weak self] (json) in
            guard let cmd = try? json.getEnum(of: "cmd", type: ALChannelMessage.AType.self) else {
                return
            }
            guard cmd == .gift else  {
                return
            }
            
            let data = try json.getDataObject()
            let gift = try data.getEnum(of: "giftId", type: Gift.self)
            let userId = try data.getStringValue(of: "fromUserId")
            let userName = try data.getStringValue(of: "fromUserName")
            
            guard let user = ALCenter.shared().liveSession?.role else {
                return
            }
            
            guard user.info.userId != userId else {
                return
            }
            
            self?.received.accept((userName, gift))
        }
    }
}
