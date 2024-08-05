//
//  ViewController.swift
//  videoPlayer
//
//  Created by Chandra Hasan on 02/08/24.
//

import UIKit
import AVKit
import AVFoundation

import Network

class ViewController: UIViewController {
    var indexVal = 0
    var isCollectionViewDisplayed: Bool = true
    var isSectionInProgress: Bool = true
    var isAllCellsLoaded: Bool = false
    var isconnectivity: Bool = false
    var reelsData: Reels?
    var reels_arr = [ReelsDict]()
    var index_section = 0
    var observer: NSKeyValueObservation?
    @IBOutlet weak var videosListView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if(self.isconnectivity) {
                    DispatchQueue.main.async {
                        self.videosListView.reloadSections(NSIndexSet(index: self.index_section) as IndexSet, with: .none)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isconnectivity = true
                    let alert = UIAlertController(title: "No Internet Connection", message: "", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default)
                    alert.addAction(action)
                    self.present(alert, animated: true)
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        self.fecthDataAndLoadTable()
        videosListView.sectionHeaderTopPadding = 120
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        index_section += 1
        if(index_section <= ((reelsData?.reels)!.count - 1)) {
            isSectionInProgress = true
            DispatchQueue.main.async {
                self.videosListView.reloadSections(NSIndexSet(index: self.index_section) as IndexSet, with: .none)
            }
        }
        
    }
    
    func fecthDataAndLoadTable() {
        reelsData = loadJson(filename: "reels")
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("goForNextSection"), object: nil)
    }
    
    ///MARK: Data load function
    func loadJson(filename fileName: String) -> Reels? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(Reels.self, from: data)
                return jsonData
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return reelsData?.reels.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! TableCell
        if(isSectionInProgress) {
            let arr = reelsData?.reels[indexPath.section].arr
            cell.current_section = index_section
            cell.section_index = indexPath.section
            cell.reels_arr = arr!
        }
        if(indexPath.section == reelsData?.reels.count) {
            isAllCellsLoaded = true
        }
        return cell;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        600
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if(isAllCellsLoaded) {
            isSectionInProgress = false
        }
    }
}
