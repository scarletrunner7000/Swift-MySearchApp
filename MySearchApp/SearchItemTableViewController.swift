//
//  SearchItemTableViewController.swift
//  MySearchApp
//
//  Created by 稲垣悠一 on 2016/08/16.
//  Copyright © 2016年 稲垣悠一. All rights reserved.
//

import Foundation
import UIKit

class SearchItemTableViewController: UITableViewController, UISearchBarDelegate {
    
    var itemDataArray = [ItemData]()
    var imageCache = NSCache()
    let appid: String = "dj0zaiZpPUlsR1lSeXFrTXllQyZzPWNvbnN1bWVyc2VjcmV0Jng9ZDM-"
    let entryUrl: String = "http://shopping.yahooapis.jp/ShoppingWebService/V1/json/itemSearch"
    let priceFormat = NSNumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        priceFormat.numberStyle = .CurrencyStyle
        priceFormat.currencyCode = "JPY"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - search bar delegate
    // キーボードのサーチボタンが押された時に呼び出される
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        NSLog("searchBarSearchButtonClicked")
        let inputText = searchBar.text
        if inputText?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            itemDataArray.removeAll()
            let parameter = ["appid": appid, "query": inputText]
            let requestUrl = createRequestUrl(parameter)
            execRequest(requestUrl)
        }
        // キーボードを閉じる
        searchBar.resignFirstResponder()
    }
    
    // URL作成
    func createRequestUrl(parameter: [String:String?]) -> String {
        NSLog("createRequestUrl")
        var parameterString = ""
        for key in parameter.keys {
            if let value = parameter[key] {
                if parameterString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                    parameterString += "&"
                }
                
                if let escapedValue = value!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                    parameterString += "\(key)=\(escapedValue)"
                }
            }
        }
        
        let requestUrl = entryUrl + "?" + parameterString
        return requestUrl
    }
    
    // API にリクエストを投げる
    func execRequest(requestUrl: String) {
        let session = NSURLSession.sharedSession()
        
        if let url = NSURL(string: requestUrl) {
            let request = NSURLRequest(URL: url)
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if error != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let alert = UIAlertController(title: "エラー", message: error?.description, preferredStyle: UIAlertControllerStyle.Alert)
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                    return
                }
                
                // JSON で返されたデータをパースして格納する
                if let data = data {
                    let jsonData = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                    if let resultSet = jsonData["ResultSet"] as? [String:AnyObject] {
                        self.parseData(resultSet)
                    }
                    
                    // テーブルの描画処理を実施
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                }
            })
            task.resume()
        }
        
    }
    
    //検索結果をパースして商品リストを作成する
    func parseData(resultSet: [String:AnyObject]) {
        if let firstObject = resultSet["0"] as? [String:AnyObject] {
            if let results = firstObject["Result"] as? [String:AnyObject] {
                for key in results.keys.sort() {
                    
                    //Requestのキーは無視する
                    if key == "Request" {
                        continue
                    }
                    
                    //商品アイテム取得処理
                    if let result = results[key] as? [String:AnyObject] {
                        //商品データ格納オブジェクト作成
                        let itemData = ItemData()
                        
                        //画像を格納
                        if let itemImageDic = result["Image"] as? [String:AnyObject] {
                            let itemImageUrl = itemImageDic["Medium"] as? String
                            itemData.itemImageUrl = itemImageUrl
                        }
                        
                        //商品タイトルを格納
                        let itemTitle = result["Name"] as? String //商品名
                        itemData.itemTitle = itemTitle
                        
                        //商品価格を格納
                        if let itemPriceDic = result["Price"] as? [String:AnyObject] {
                            let itemPrice = itemPriceDic["_value"] as? String
                            itemData.itemPrice = itemPrice
                        }
                        
                        //商品のURLを格納
                        let itemUrl = result["Url"] as? String
                        itemData.itemUrl = itemUrl
                        
                        //商品リストに追加
                        self.itemDataArray.append(itemData)
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source
    // テーブルセルの取得処理
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! ItemTableViewCell
        let itemData = itemDataArray[indexPath.row]
        //商品タイトル設定処理
        cell.itemTitleLabel.text = itemData.itemTitle
        //商品価格設定処理（日本通貨の形式で設定する）
        let number = NSNumber(integer: Int(itemData.itemPrice!)!)
        cell.itemPriceLabel.text = priceFormat.stringFromNumber(number)
        //商品のURL設定
        cell.itemData = itemData
        //画像の設定処理
        //既にセルに判定されている画像と同じかどうかチェックする
        //画像がまだ設定されていない場合に処理を行なう
        if let itemImageUrl = itemData.itemImageUrl {
            if let cacheImage = imageCache.objectForKey(itemImageUrl) as? UIImage {
                // 画像がキャッシュされている時
                cell.itemImageView.image = cacheImage
            } else {
                // 画像がキャッシュされていない時
                let session = NSURLSession.sharedSession()
                if let url = NSURL(string: itemImageUrl) {
                    let request = NSURLRequest(URL: url)
                    let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                        if let data = data {
                            if let image = UIImage(data: data) {
                                self.imageCache.setObject(image, forKey: itemImageUrl)
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    cell.itemImageView.image = image
                                })
                            }
                        }
                    })
                    task.resume()
                }
            }
        }
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemDataArray.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let cell = sender as? ItemTableViewCell {
            if let webViewController = segue.destinationViewController as? WebViewController {
                webViewController.itemData = cell.itemData
            }
        }
    }
    
}




