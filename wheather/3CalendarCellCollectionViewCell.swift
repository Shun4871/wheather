import UIKit

// Custom colors for calendar days
extension UIColor {
    static let lightBlue = UIColor(red: 92.0 / 255, green: 192.0 / 255, blue: 210.0 / 255, alpha: 1.0)
    static let lightRed = UIColor(red: 195.0 / 255, green: 123.0 / 255, blue: 175.0 / 255, alpha: 1.0)
    static let customOrange = UIColor(red: 251.0 / 255, green: 186.0 / 255, blue: 68.0 / 255, alpha: 1.0) // Custom orange color
    static let customRed = UIColor(red: 71 / 255, green: 162 / 255, blue: 222 / 255, alpha: 1.0) // Custom red color
}

// Date formatting extension
extension Date {
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

final class CalendarCell: UICollectionViewCell {
    private var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    private let selectionIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(selectionIndicator)
        contentView.addSubview(label)
        contentView.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionIndicator.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            selectionIndicator.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            timeLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        selectionIndicator.layer.cornerRadius = 20 // 初期サイズに対して円形に設定
        selectionIndicator.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 角の丸みをサイズに基づいて調整
        selectionIndicator.layer.cornerRadius = selectionIndicator.frame.size.width / 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(model: Model) {
        label.text = model.text
        label.textColor = model.textColor
        timeLabel.text = model.time
    }

    func updateAppearanceForReservation(isReserved: Bool, isWeekday: Bool = false) {
        selectionIndicator.backgroundColor = isReserved ? (isWeekday ? UIColor.customRed : UIColor.customOrange) : .clear
    }

    func setSelectionIndicatorSize(size: CGFloat) {
        NSLayoutConstraint.deactivate(selectionIndicator.constraints) // 既存の制約を無効化
        NSLayoutConstraint.activate([
            selectionIndicator.widthAnchor.constraint(equalToConstant: size),
            selectionIndicator.heightAnchor.constraint(equalToConstant: size),
            selectionIndicator.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            selectionIndicator.centerYAnchor.constraint(equalTo: label.centerYAnchor)
        ])
        selectionIndicator.layer.cornerRadius = size / 2
        layoutIfNeeded() // 変更を即座に反映
    }
}

// Model structure for CalendarCell
extension CalendarCell {
    struct Model {
        var text: String = ""
        var textColor: UIColor = .black
        var time: String? = nil // 予約時間を表示するためのプロパティ

        init(text: String, textColor: UIColor, time: String? = nil) {
            self.text = text
            self.textColor = textColor
            self.time = time
        }

        init(date: Date, time: String? = nil) {
            let weekday = Calendar.current.component(.weekday, from: date)
            textColor = (weekday == 1) ? UIColor.red : (weekday == 7) ? UIColor.lightRed : UIColor.lightBlue
            text = date.string(format: "d")
            self.time = time
        }
    }
}
