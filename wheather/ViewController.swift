//
//  ViewController.swift
//  wheather
//
//  Created by 柘植俊之介 on 2024/05/27.
//

import UIKit

class ViewController: UIViewController {
    
    // TabBarの背景色を保存するためのUserdDefaults
    var tabBarColorData: UserDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // アプリ初回起動の際，現状のTabBarの背景色をUserDefaultsに保存する
        if let colorString = tabBarColorData.string(forKey: "tabBarColor"),
           let colorData = Data(base64Encoded: colorString),
           let barColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            changeTabBarColor(barColor)
        }
        
    }
    
    /**
     色ボタンをタップするとタブバーの背景色を変更する
     */
    @IBAction func changeColorButtonTapped(_ sender: UIButton!) {
        
        if let backgroundColor = sender.backgroundColor {
            changeTabBarColor(backgroundColor)
        } else {
            fatalError("ボタンの背景色を取得できませんでした．")
        }
        
    }
    
    /**
     タブバーの背景色を変更する関数
     */
    func changeTabBarColor(_ barColor: UIColor) {
        
        // UITabBarの外観を設定
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = barColor
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // タブバーアイテムの色
        UITabBar.appearance().tintColor = UIColor.white
        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray
        
        
        // 既存のタブバーに変更を反映させる
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            for view in window.subviews {
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
        
        // UIColorを文字列に変換
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: barColor, requiringSecureCoding: false) {
            let colorString = colorData.base64EncodedString()
            
            // UserDefaultsにタブバーの背景色を文字列で保存する
            tabBarColorData.set(colorString, forKey: "tabBarColor")
            
        }
    }
}
