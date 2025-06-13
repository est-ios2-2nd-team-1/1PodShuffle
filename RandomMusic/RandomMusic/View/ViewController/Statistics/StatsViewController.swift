//
//  StatsViewController.swift
//  RandomMusic
//
//  Created by 이유정 on 6/13/25.
//


import UIKit
import Charts

class StatisticsViewController: UIViewController, UITableViewDataSource {
//    @IBOutlet weak var chartView: PieChartView! // 또는 BarChartView
    @IBOutlet weak var artistTableView: UITableView!
    @IBOutlet weak var songTableView: UITableView!

    var topArtists: [String] = ["아티스트1", "아티스트2", "아티스트3"]
    var topSongs: [String] = ["노래1", "노래2", "노래3"]
    var genreRatios: [String: Double] = ["Pop": 40, "Rock": 30, "Jazz": 30]

    override func viewDidLoad() {
        super.viewDidLoad()
//        setupChart()
        artistTableView.dataSource = self
        songTableView.dataSource = self
    }

//    func setupChart() {
//        var entries = [PieChartDataEntry]()
//        for (genre, ratio) in genreRatios {
//            entries.append(PieChartDataEntry(value: ratio, label: genre))
//        }
//        let dataSet = PieChartDataSet(entries: entries, label: "선호장르")
//        dataSet.colors = ChartColorTemplates.material()
//        chartView.data = PieChartData(dataSet: dataSet)
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == artistTableView {
            return topArtists.count
        } else {
            return topSongs.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if tableView == artistTableView {
            cell.textLabel?.text = topArtists[indexPath.row]
        } else {
            cell.textLabel?.text = topSongs[indexPath.row]
        }
        return cell
    }
}
