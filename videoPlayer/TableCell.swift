//
//  TableCell.swift
//  videoPlayer
//
//  Created by Chandra Hasan on 04/08/24.
//

import UIKit
import AVKit
import AVFoundation

class TableCell: UITableViewCell {
    
    @IBOutlet weak var videoCollection: UICollectionView!
    var reels_arr = [ReelsDict]()
    var indexVal = 0
    var section_index = Int()
    var current_section = Int()
    var isCollectionViewDisplayed: Bool = true
    var observer: NSKeyValueObservation?
    var playerLayer = AVPlayerLayer()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupCollectionView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    private func setupCollectionView() {
        videoCollection.dataSource = self
        videoCollection.delegate = self
        videoCollection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionCell")
    }
    
}

///MARK: GIRD view setup section
extension TableCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reels_arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as? MyCell else {
            // we failed to get a PersonCell – bail out!
            fatalError("Unable to dequeue PersonCell.")
        }
        let dict = reels_arr[indexPath.row]
        cell.thumbImg.loadImage(from: URL(string: dict.thumbnail)!, placeholder: UIImage(named: "noImage"))
        cell.activityInd.isHidden = true
        if(section_index == current_section) {
            if isCollectionViewDisplayed && indexVal == indexPath.row {
                isCollectionViewDisplayed = false
                cell.thumbImg.isHidden = true
                cell.activityInd.isHidden = false
                cell.activityInd.startAnimating()
                cell.colView.dropShadow(color: UIColor.gray, offSet: CGSize(width: -1, height: 1))
                Task {
                    do {
                        let videoData = try await fetchVideoData(from: URL(string: dict.video)!)
                        let localURL = try saveVideoDataToTempFile(videoData)
                        cell.colView = loadVideo(view: cell.colView, videoURL: localURL)
                        cell.activityInd.stopAnimating()
                        cell.activityInd.isHidden = true
                    } catch {
                        print("Failed to fetch and play video: \(error)")
                    }
                }
            } else if indexVal == indexPath.row {
                cell.colView.removeAllSubviews()
                cell.thumbImg.isHidden = false
                cell.activityInd.isHidden = true
                cell.contentView.bringSubviewToFront(cell.thumbImg)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
        let size:CGFloat = (collectionView.frame.size.width - space) / 2.0
        return CGSize(width: size, height: self.videoCollection.frame.height/2 - 20)
    }
    
    ///MARK: Play video from save data file
    func loadVideo(view: UIView, videoURL: URL) -> UIView {
        let asset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration"])
        var videoPlayer = AVPlayer()
        videoPlayer = AVPlayer(playerItem: playerItem)
        videoPlayer.rate = 20.0
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.frame = view.bounds
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        view.layer.addSublayer(playerLayer)
        
        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
            if playerItem.status == .readyToPlay {
                // Do your work here.
              
                self.playerLayer.player!.play()
            }
            
        })
        return view
    }
    
    ///MARK: Fetch video data from url
    func fetchVideoData(from url: URL) async throws -> Data {
        let ddata = Data()
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("\(error.localizedDescription)")
            return ddata
        }
        
    }
    ///MARK: Sava video data from URL into local storage
    func saveVideoDataToTempFile(_ data: Data) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        try data.write(to: tempFileURL)
        return tempFileURL
    }
    
    ///MARK: After a video is completed here it call's for next one
    @objc func playerDidFinishPlaying(_ note: NSNotification) {
        let indexPath = IndexPath(item: indexVal, section: 0)
        videoCollection.reloadItems(at: [indexPath])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.playerLayer.removeFromSuperlayer()
            self.indexVal += 1
            if(self.indexVal <= self.reels_arr.count-1) {
                self.isCollectionViewDisplayed = true
                NotificationCenter.default.removeObserver(self)
                let indexPath = IndexPath(item: self.indexVal, section: 0)
                self.videoCollection.reloadItems(at: [indexPath])
            } else if(self.indexVal == 4) {
                NotificationCenter.default.post(name: Notification.Name("goForNextSection"), object: nil, userInfo: ["goForNextSection":true])
            }
        }
    }
}

extension UIImageView {
    ///MARK: User URL showing image else placeholder image
    func loadImage(from url: URL, placeholder: UIImage? = nil) {
        
        if let placeholder = placeholder {
            self.image = placeholder
        }
        
      
        URLSession.shared.dataTask(with: url) { data, response, error in
           
            if let error = error {
                print("Error loading image: \(error)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            
            // Update the UIImageView on the main thread
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}

extension UIView {
    func removeAllSubviews() {
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
    }
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 20, scale: Bool = true) {
      layer.masksToBounds = false
      layer.shadowColor = color.cgColor
      layer.shadowOpacity = opacity
      layer.shadowOffset = offSet
      layer.shadowRadius = radius
      layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
      layer.shouldRasterize = true
      layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

