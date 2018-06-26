//
//  VMMPlayerOverlayView.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 4/19/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit

class VMMPlayerOverlayView: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var overlayImage: UIImageView!
    @IBOutlet weak var labelText: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        let bundle = Bundle(for: VMMPlayerOverlayView.self)
        bundle.loadNibNamed(String(describing: VMMPlayerOverlayView.self), owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

}
