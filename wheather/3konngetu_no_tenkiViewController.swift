//
//  konngetu-no-tenkiViewController.swift
//  wheather
//
//  Created by 柘植俊之介 on 2024/05/30.
//

import UIKit


final class konngetu_no_tenkiViewController: UIViewController {

    private let dateManager = MonthDateManager()
    private let weeks = ["日","月", "火", "水", "木", "金", "土"]
    private let itemSize: CGFloat = (UIScreen.main.bounds.width - 60) / 7

    private lazy var calenderCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: itemSize, height: 50)
        let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    private func setUpNavigationBar() {
        navigationController?.navigationBar.barTintColor = UIColor(red: 255/255, green: 132/255, blue: 214/255, alpha: 1)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "next",
            style: .plain,
            target: self,
            action: #selector(actionNext)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "back",
            style: .plain,
            target: self,
            action: #selector(actionBack)
        )
        title = dateManager.monthString
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        calenderCollectionView.frame.size.width = view.bounds.width
        calenderCollectionView.frame.size.height = 500
        view.addSubview(calenderCollectionView)
        setUpNavigationBar()
    }

    @objc private func actionNext() {
        dateManager.nextMonth()
        calenderCollectionView.reloadData()
        title = dateManager.monthString
    }

    @objc private func actionBack() {
        dateManager.prevMonth()
        calenderCollectionView.reloadData()
        title = dateManager.monthString
    }
}

extension konngetu_no_tenkiViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? weeks.count : dateManager.days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarCell
        if indexPath.section == 0 {
            let day = weeks[indexPath.row]
            let model = CalendarCell.Model(text: day, textColor: .black)
            cell.configure(model: model)
        } else {
            let date = dateManager.days[indexPath.row]
            cell.configure(model: CalendarCell.Model(date: date))
        }
        return cell
    }
}

extension konngetu_no_tenkiViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        title = dateManager.days[indexPath.row].string(format: "YYYY/MM/dd")
    }
}

