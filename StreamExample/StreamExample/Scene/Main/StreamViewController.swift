//
//  StreamViewController.swift
//  StreamExample
//
//  Created by Jo JANGHUI on 2020/06/14.
//  Copyright © 2020 Jo JANGHUI. All rights reserved.
//

import UIKit

final class StreamViewController: UIViewController {

    @IBOutlet private weak var downloadButton: UIButton!
    
    @IBOutlet private weak var streamFileImageView: UIImageView!
    @IBOutlet private weak var appendBufferImageView: UIImageView!
    @IBOutlet private weak var streamMemoryImageView: UIImageView!
    
    private var imageDatas: [Data] = []
    private var chunkIndex = 0
    
    private var fileOutputStream: OutputStream?
    private var streamFileBufferCount = 0
    private var streamFileSaveURL: URL?
    
    private var memoryOutputStream: OutputStream?
    private var streamMemoryBufferCount = 0
        
    private var appendBufferCount = 0
    private var appendBufferImageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        streamFileSaveURL = url.appendingPathComponent("saveFile")
        
        if FileManager.default.fileExists(atPath: streamFileSaveURL!.path) {
            try! FileManager.default.removeItem(at: streamFileSaveURL!)
        }
        
        fileOutputStream = OutputStream(toFileAtPath: streamFileSaveURL!.path, append: true)
        memoryOutputStream = OutputStream(toMemory: ())
        
        createImageDatas()
    }
    
    @IBAction func tapDownloadStartButton(_ sender: Any) {
        DispatchQueue.global().async {
            self.fileOutputStream?.open()
            self.imageDatas.forEach{ [weak self] data in
                guard let self = self else { return }
                self.fileOutputStream?.write(data: data)
                self.streamFileBufferCount += 1
                
                if self.chunkIndex == self.streamFileBufferCount {
                    self.fileOutputStream?.close()
                    DispatchQueue.main.async {
                        self.streamFileImageView.image = UIImage(contentsOfFile: self.streamFileSaveURL!.path)
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            self.imageDatas.forEach{ [weak self] data in
                guard let self = self else { return }
                self.appendBufferCount += 1
                
                if self.appendBufferImageData == nil {
                    self.appendBufferImageData = data
                } else {
                    self.appendBufferImageData?.append(data)
                }
                
                if self.chunkIndex == self.appendBufferCount {
                    if let data = self.appendBufferImageData {
                        DispatchQueue.main.async {
                            self.appendBufferImageView.image = UIImage(data: data)
                        }
                        
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            self.memoryOutputStream?.open()
            self.imageDatas.forEach{ [weak self] data in
                guard let self = self else { return }
                self.memoryOutputStream?.write(data: data)
                self.streamMemoryBufferCount += 1
                
                if self.chunkIndex == self.streamMemoryBufferCount {
                    self.memoryOutputStream?.close()
                    DispatchQueue.main.async {
                        self.streamMemoryImageView.image = UIImage(data: self.memoryOutputStream?.property(forKey: .dataWrittenToMemoryStreamKey) as! Data)
                    }
                }
            }
        }
    }
    
    private func createImageDatas() {
        let path = Bundle.main.path(forResource: "Image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let imageData = try! Data(contentsOf: url)
        
        let sendChunk = 10
        
        chunkIndex = imageData.count / sendChunk
        let capacity = imageData.count % sendChunk
        
        if capacity > 0 {
            chunkIndex += 1
        }
        
        for idx in 0..<chunkIndex {
            let targetLength = idx == chunkIndex - 1 ? capacity : sendChunk
            if let range = Range(NSRange(location: idx * sendChunk, length: targetLength)) {
                imageDatas.append(imageData.subdata(in: range))
            }
        }
    }
    
}

