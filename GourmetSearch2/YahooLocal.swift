//
//  YahooLocal.swift
//  GourmetSearch2
//
//  Created by HideakiTouhara on 2017/08/23.
//  Copyright © 2017年 HideakiTouhara. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public extension Notification.Name {
    // 読み込み開始Notification
    public static let apiLoadStart = Notification.Name("ApiLoadStart")
    // 読み込み終了Notification
    public static let apiLoadComplete = Notification.Name("ApiLoadComplete")
}

public struct Shop: CustomStringConvertible {
    public var gid: String? = nil
    public var name: String? = nil
    public var photoUrl: String? = nil
    public var yomi: String? = nil
    public var tel: String? = nil
    public var address: String? = nil
    public var lat: Double? = nil
    public var lon: Double? = nil
    public var catchCopy: String? = nil
    public var hasCoupon = false
    public var station: String? = nil
    
    public var url: String? {
        get {
            if let gid = gid {
                return "http://loco.yahoo.co.jp/place/g-\(gid)/"
            }
            return nil
        }
    }
    
    public var description: String {
        get {
            var string = "\nGid: \(gid)\n"
            string += "Name: \(name)\n"
            string += "PhotoUrl: \(photoUrl)\n"
            string += "Yomi: \(yomi)\n"
            string += "Tel: \(tel)\n"
            string += "Address: \(address)"
            string += "Lat & Lon: (\(lat), \(lon))\n"
            string += "CatchCopy: \(catchCopy)\n"
            string += "hasCoupon: \(hasCoupon)\n"
            string += "Station: \(station)\n"
            
            return string
        }
    }
}

public struct QueryCondition {
    // キーワード
    public var query: String? = nil
    // 店舗ID
    public var gid: String? = nil
    // ソート順
    public enum Sort: String {
        case score = "score"
        case geo = "geo"
    }
    public var sort: Sort = .score
    // 経度
    public var lat: Double? = nil
    // 緯度
    public var lon: Double? = nil
    // 距離
    public var dist: Double? = nil
    
    // 検索パラメタディクショナリ
    public var queryParams: [String: String] {
        get {
            var params = [String: String]()
            // キーワード
            if let unwrapped = query {
                params["query"] = unwrapped
            }
            // 店舗ID
            if let unwrapped = gid {
                params["gid"] = unwrapped
            }
            // ソート順
            switch sort {
            case .score:
                params["score"] = "score"
            case .geo:
                params["geo"] = "geo"
            }
            // 緯度
            if let unwrapped = lat {
                params["lat"] = "\(unwrapped)"
            }
            // 経度
            if let unwrapped = lon {
                params["lon"] = "\(unwrapped)"
            }
            // 距離
            if let unwrapped = dist {
                params["dist"] = "\(unwrapped)"
            }
            // デバイス: mobile固定
            params["device"] = "mobile"
            // グルーピング
            params["group"] = "gid"
            // 画像があるデータのみ検索する: true固定
            params["image"] = "true"
            // 業種コード
            params["gc"] = "01"
            
            return params
        }
    }
}

public class YahooLocalSearch {
    // YahooローカルサーチAPIのアプリケーションID
    let apiId = "dj00aiZpPVVzOVpweHBXVm5ncyZzPWNvbnN1bWVyc2VjcmV0Jng9MjE-"
    // APIベースのURL
    let apiUrl = "http://search.olp.yahooapis.jp/OpenLocalPlatform/V1/localSearch"
    let apiUrl2 = "https://map.yahooapis.jp/search/local/V1/localSearch"
    // 1ページのレコード数
    let perPage = 10
    // 読込済の店舗
    public var shops = [Shop]()
    // trueだと読込中
    var loading = false
    // 全何件か
    public var total = 0
    // 検索条件
    var condition: QueryCondition = QueryCondition() {
        // プロパティオブザーバ: 新しい値がセットされた後に読込済の店舗を捨てる
        didSet {
            shops = []
            total = 0
        }
    }
    // パラメータなしのイニシャライザ
    init(){}
    // 検索条件をパラメタとして持つイニシャライザ
    public init(condition: QueryCondition) {
        self.condition = condition
    }
    // APIからデータを読み込む
    //reset = trueならデータを捨てて最初から読み込む
    public func loadData(reset: Bool = false) {
        // 読込中なら何もしない
        if loading == true { return }
        // reset = trueなら今までの結果を捨てる
        if reset {
            shops = []
            total = 0
        }
        
        // API実行中フラグをON
        loading = true
        
        // 検索ディクショナリを取得
        var params = condition.queryParams
        // 検索条件以外のAPIパラメタを設定
        params["appid"] = apiId
        params["output"] = "json"
        params["start"] = String(shops.count + 1)
        params["results"] = String(perPage)
        
        // API実行開始を通知する
        NotificationCenter.default.post(name: .apiLoadStart, object: nil)
        // APIリクエスト実行
        let request = Alamofire.request(apiUrl2, method: .get, parameters: params).response {
            response in
            
            var json = JSON.null;
            if response.error == nil && response.data != nil {
                json = SwiftyJSON.JSON(data: response.data!)
            }
            // エラーがあれば終了
            if response.error != nil {
                // API実行中フラグをOFF
                self.loading = false
                // API実行終了を通知する
                var message = "Unknown error."
                if let error = response.error {
                    message = "\(error)"
                }
                NotificationCenter.default.post(name: .apiLoadComplete, object: nil, userInfo: ["error": message])
                return
            }
            // 店舗データをself.shopsに追加する
            for(key, item) in json["Feature"] {
                var shop = Shop()
                // 店舗ID
                shop.gid = item["Gid"].string
                // 店舗名: 'が&#39;という形でエンコードされているのでデコードする
                shop.name = item["Name"].string?.replacingOccurrences(of: "&#39;", with: "'")
                // 読み
                shop.yomi = item["Property"]["Yomi"].string
                // 電話
                shop.tel = item["Property"]["Tel1"].string
                // 住所
                shop.address = item["Property"]["Address"].string
                // 緯度&経度
                if let geometry = item["Geometry"]["Coordinates"].string {
                    let components = geometry.components(separatedBy: ",")
                    // 緯度
                    shop.lat = (components[1] as NSString).doubleValue
                    // 経度
                    shop.lon = (components[0] as NSString).doubleValue
                }
                // キャッチコピー
                shop.catchCopy = item["Property"]["CatchCopy"].string
                // 店舗写真
                shop.photoUrl = item["Property"]["LeadImage"].string
                // クーポン有無
                if item["Property"]["CouponFlag"].string == "true" {
                    shop.hasCoupon = true
                }
                // 駅
                if let stations = item["Property"]["Station"].array {
                    // 路線名は「/」で結合されているので最初の1つを使う
                    var line = ""
                    if let lineString = stations[0]["RailWay"].string {
                        let lines = lineString.components(separatedBy: "/")
                        line = lines[0]
                    }
                    if let station = stations[0]["Name"].string {
                        // 駅名と路線名があれば両方入れる。
                        shop.station = "\(line)\(station)"
                    } else {
                        shop.station = "\(line)"
                    }
                }
                print(shop)
                self.shops.append(shop)
            }
            if let total = json["ResultInfo"]["Total"].int {
                self.total = total
            } else {
                self.total = 0
            }
            
            // API実行中フラグをOFF
            self.loading = false
            
            // API実行終了を通知する
            NotificationCenter.default.post(name: .apiLoadComplete, object: nil)
        }
    }
    
    func sortByGid() {
        var newShops = [Shop]()
        // 検索条件の店舗ID(Gid)一覧文字列を「,」で分割して配列に戻す
        if let gids = self.condition.gid?.components(separatedBy: ",") {
            for gid in gids {
                let filtered = shops.filter{ $0.gid == gid }
                if filtered.count > 0 {
                    newShops.append(filtered[0])
                }
            }
        }
        shops = newShops
    }
}
