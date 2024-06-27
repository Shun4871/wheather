import UIKit

class ViewController: UIViewController {

    // TabBarの背景色を保存するためのUserDefaults
    var tabBarColorData: UserDefaults = UserDefaults.standard

    // Apple Weatherの商標と法的ソースリンクを表示するためのラベル
    let attributionLabel: UILabel = {
        let label = UILabel()
        label.text = " Weather"
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let attributionLinkLabel: UILabel = {
        let label = UILabel()
        label.text = "Apple Weather Legal Attribution"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .blue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // アプリ初回起動の際，現状のTabBarの背景色をUserDefaultsに保存する
        if let colorString = tabBarColorData.string(forKey: "tabBarColor"),
           let colorData = Data(base64Encoded: colorString),
           let barColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            changeTabBarColor(barColor)
        }
        
        setupAttributionLabels()
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

    /**
     Apple Weatherの商標と法的ソースリンクを設定する関数
     */
    func setupAttributionLabels() {
        view.addSubview(attributionLabel)
        view.addSubview(attributionLinkLabel)
        
        // Apple Weather商標のラベルの制約を設定
        NSLayoutConstraint.activate([
            attributionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            attributionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40)
        ])
        
        // 法的ソースリンクのラベルにタップジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openLegalAttribution))
        attributionLinkLabel.isUserInteractionEnabled = true
        attributionLinkLabel.addGestureRecognizer(tapGesture)
        
        // 法的ソースリンクのラベルの制約を設定
        NSLayoutConstraint.activate([
            attributionLinkLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            attributionLinkLabel.topAnchor.constraint(equalTo: attributionLabel.bottomAnchor, constant: 8)
        ])
    }
    
    @objc func openLegalAttribution() {
        if let url = URL(string: "https://weatherkit.apple.com/legal-attribution.html") {
            UIApplication.shared.open(url)
        }
    }
}
