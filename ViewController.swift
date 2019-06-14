//
//  ViewController.swift
//  webMPlayer
//
//  Created by Rigel Mac 9 on 13/06/19.
//  Copyright © 2019 Rigel Mac 9. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var collectionview: UICollectionView!
    
    // MARK: - Properties
    private let reuseIdentifier = "PlayerCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0,
                                             left: 20.0,
                                             bottom: 50.0,
                                             right: 20.0)
    private let urls = ["https://rigelportalapp.s3.amazonaws.com/PortalScreenVideo/3241/838_Simultaneously%20Portal2.webm", "https://grins.upc.edu/en/shared/videos/demo.webm/@@download/file/demo.webm", "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm"]
    private var thumbnails = [UIImage]() {
        didSet {
            collectionview.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for url in urls {
            setThumbnail(for: url)
        }
        collectionview.delegate = self
        collectionview.dataSource = self
        collectionview.register(UINib(nibName: "PlayerCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        collectionview.reloadData()
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlayerCell
        cell.backgroundColor = .lightGray
        cell.layer.cornerRadius = 5
        cell.layer.masksToBounds = true
        if thumbnails.count > indexPath.item {
            cell.imgThumbnail.image = thumbnails[indexPath.item]
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
        } else {
            cell.imgThumbnail.image = nil
            cell.activityIndicator.startAnimating()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 2 - 5, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playerVC = self.storyboard?.instantiateViewController(withIdentifier: "PlaybackViewController") as! PlaybackViewController
        playerVC.mediaURL = urls[indexPath.item]
        self.navigationController?.pushViewController(playerVC, animated: true)
    }
}


extension ViewController: VLCMediaPlayerDelegate, VLCMediaThumbnailerDelegate, VLCMediaDelegate {
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer!) {
        //stop animating
    }
    
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer!, didFinishThumbnail thumbnail: CGImage!) {
        //stop animating
        let image = UIImage.init(cgImage: thumbnail)
        thumbnails.append(image)
    }
    
    func setThumbnail(for url: String) {
        let library = VLCLibrary.shared()
        library.debugLogging = true
        
        let media = VLCMedia.init(url: URL(string: url)!)
        media.delegate = self
        
        let thumbnailer = VLCMediaThumbnailer.init(media: media, delegate: self, andVLCLibrary: library)
        thumbnailer?.fetchThumbnail()
    }
}
