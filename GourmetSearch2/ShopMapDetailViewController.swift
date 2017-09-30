//
//  ShopMapDetailViewController.swift
//  GourmetSearch2
//
//  Created by HideakiTouhara on 2017/09/03.
//  Copyright © 2017年 HideakiTouhara. All rights reserved.
//

import UIKit
import MapKit

class ShopMapDetailViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var showHereButton: UIBarButtonItem!
    
    let ls = LocationService()
    let nc = NotificationCenter.default
    var observers = [NSObjectProtocol]()
    var shop: Shop = Shop()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 店舗所在地を地図に反映
        if let lat = shop.lat {
            if let lon = shop.lon {
                // 地図の表示範囲を設定する
                let cllc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let mkcr = MKCoordinateRegionMakeWithDistance(cllc, 500, 500)
                map.setRegion(mkcr, animated: false)
                // ピンを設定
                let pin = MKPointAnnotation()
                pin.coordinate = cllc
                pin.title = shop.name
                map.addAnnotation(pin)
            }
        }
        self.navigationItem.title = shop.name

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 位置情報取得を禁止している場合
        observers.append(
            nc.addObserver(forName: .authDenied, object: nil, queue: nil, using: {
                notification in
                
                // 位置情報がONになっていないダイアログ表示
                self.present(self.ls.locaionServiceDisabledAlert, animated: true, completion: nil)
                // 現在地を表示ボタンを非アクティブにする
                self.showHereButton.isEnabled = false
            })
        )
        
        // 位置情報取得を制限している場合
        observers.append(
            nc.addObserver(forName: .authRestricted, object: nil, queue: nil, using:  {
                notification in
                // 位置情報が制限されているダイアログ
                self.present(self.ls.locationServiceRestrictedAlert, animated: true, completion: nil)
                // 現在地を表示ボタンを非アクティブにする
                self.showHereButton.isEnabled = false
            })
        )
        
        // 位置情報取得に失敗した場合
        observers.append(
            nc.addObserver(forName: .didFailLocation, object: nil, queue: nil, using: {
                notification in
                // 位置情報取得に失敗したダイアログ
                self.present(self.ls.locationServiceDidFailAlert, animated: true, completion: nil)
                // 現在地を表示ボタンを非アクティブにする
                self.showHereButton.isEnabled = false
            })
        )
        
        // 位置情報を取得した場合
        observers.append(
            nc.addObserver(forName: .didUpdateLocation, object: nil, queue: nil, using: {
                notification in
                
                // [現在地を表示]ボタンをアクティブにする
                self.showHereButton.isEnabled = true
                
                // 位置情報が渡されていなければ早期離脱
                guard let userInfo = notification.userInfo as? [String: CLLocation] else {
                    return
                }
                
                // userInfoがキーlocation を持っていなければ早期離脱
                guard let clloc = userInfo["location"] else {
                    return
                }
                
                // 店舗が位置情報を持っていなければ早期離脱
                guard let lat = self.shop.lat else {
                    return
                }
                guard let lon = self.shop.lon else {
                    return
                }
                
                // 地図の表示範囲を設定する
                let center = CLLocationCoordinate2D(latitude: (lat + clloc.coordinate.latitude) / 2, longitude: (lon + clloc.coordinate.longitude) / 2)
                let diff = (
                    lat: abs(clloc.coordinate.latitude - lat),
                    lon: abs(clloc.coordinate.longitude - lon))
                
                // 表示範囲を設定する
                let mkcs = MKCoordinateSpanMake(diff.lat * 1.4, diff.lon * 1.4)
                let mkcr = MKCoordinateRegionMake(center, mkcs)
                self.map.setRegion(mkcr, animated: true)
                
                self.map.showsUserLocation = true
            })
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Notificationの待受を解除する
        for observer in observers {
            nc.removeObserver(observer)
        }
        observers = []
    }
    

    // MARK: - IBAction
    @IBAction func showHereButtonTapped(_ sender: UIBarButtonItem) {
        ls.startUpdatingLocation()
    }

}
