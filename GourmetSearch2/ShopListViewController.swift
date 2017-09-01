//
//  ViewController.swift
//  GourmetSearch2
//
//  Created by HideakiTouhara on 2017/08/23.
//  Copyright © 2017年 HideakiTouhara. All rights reserved.
//

import UIKit

class ShopListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var yls: YahooLocalSearch = YahooLocalSearch()
    var loadDataObserver: NSObjectProtocol?
    var refreshObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pull to Refreshコントロール初期化
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ShopListViewController.onRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /*
        var qc = QueryCondition()
        qc.query = "ラーメン"
        yls = YahooLocalSearch(condition: qc)
        */
        
        // 読み込み完了通知を受信したときの通知
        loadDataObserver = NotificationCenter.default.addObserver(forName: .apiLoadComplete, object: nil, queue: nil, using: {
            (notification) in
            
            self.tableView.reloadData()
            
            // エラーがあればダイアログを開く
            if notification.userInfo != nil {
                if let userInfo = notification.userInfo as? [String: String] {
                    if userInfo["error"] != nil {
                        let alertView = UIAlertController(title: "通信エラー", message: "通信エラーが発生しました。", preferredStyle: .alert)
                        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                            action in return
                            })
                        )
                        self.present(alertView, animated: true, completion: nil)
                    }
                }
            }
        })
        yls.loadData(reset: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self.loadDataObserver!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // セルの数は店舗数
            return yls.shops.count
        }
        
        // 通常ここには達しない
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row < yls.shops.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ShopListItem") as! ShopListItemTableViewCell
                cell.shop = yls.shops[indexPath.row]
                
                // まだ残りがあって、現在の列の下の店舗が3つ以下になったら追加取得
                if yls.shops.count < yls.total {
                    if yls.shops.count - indexPath.row <= 4 {
                        yls.loadData()
                    }
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    // MARK: - アプリケーションロジック
    
    // Pull to Refresh
    func onRefresh(_ refreshControl: UIRefreshControl) {
        // UIRefreshControlを読込中状態にする
        refreshControl.beginRefreshing()
        // 終了通知を受信したらUIRefreshControlを停止する
        refreshObserver = NotificationCenter.default.addObserver(forName: .apiLoadComplete, object: nil, queue: nil, using: {
            notification in
            // 通知の待ち受けを終了
            NotificationCenter.default.removeObserver(self.refreshObserver!)
            // UIRefreshControlを停止する
            refreshControl.endRefreshing()
        })
        // 再取得
        yls.loadData(reset: true)
    }


}

