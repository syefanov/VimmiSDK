//
//  VMMPlayerUI.swift
//  VimmiSDK
//
//  Created by Serhii Yefanov on 6/8/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation

enum VMMPlayerUITimePresentationMode {
    case spent
    case left
}

protocol VMMPlayerUIDelegate: class {
    func didTapPlayButton()
    func didTapSoundButton()
    func didTapFullScreenButton()
    func didChangeProgressSliderValue(time: Double)
}

class VMMPlayerUI : UIView {
    
    static let defaultProgressMinColor: UIColor = UIColor(red: 26.0/255.0, green: 76.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    static let defaultProgressMaxColor: UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    static let defaultProgressThumbColor: UIColor = UIColor(red: 26.0/255.0, green: 76.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    weak var delegate: VMMPlayerUIDelegate?
    
    @IBOutlet private weak var contentView: UIView!
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var buttonPlay: UIButton!
    @IBOutlet weak var buttonPlayBig: UIButton!
    @IBOutlet weak var buttonSound: UIButton!
    @IBOutlet weak var buttonFullScreen: UIButton!
    @IBOutlet weak var sliderProgress: UISlider!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelError: UILabel!
    
    var timePresentationMode: VMMPlayerUITimePresentationMode = .spent
    
    private var timerControlView: Timer?
    private var shouldShowControlView: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        let bundle = Bundle(for: VMMPlayerUI.self)
        bundle.loadNibNamed(String(describing: VMMPlayerUI.self), owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sliderProgress.value = 0.0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onContentViewTap(sender:)))
        self.contentView.addGestureRecognizer(tapGesture)
        self.runControlViewTimer()
        
        self.labelError.text = ""
        self.labelError.isHidden = true
        
        if let image = UIImage(named: "dot_image", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate) {
            self.sliderProgress.setThumbImage(image, for: .normal)
            self.sliderProgress.setThumbImage(image, for: .highlighted)
        }
        
        self.controlView.isHidden = !shouldShowControlView
    }
    
    //MARK: - UI customization
    
    func showError(_ error: Error) {
        self.labelError.isHidden = false
        self.labelError.text = error.localizedDescription
    }
    
    func setShouldShowControls(_ show: Bool) {
        self.shouldShowControlView = show
        if show && self.controlView.isHidden {
            self.toggleControlView()
        }
    }
    
    func updatePlayButtonImage(isPlaying: Bool) {
        var imageName = ""
        if isPlaying {
            imageName = "pause"
        }
        else {
            imageName = "play_arrow"
        }
        let bundle = Bundle(for: type(of: self))
        if let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal) {
            self.buttonPlay.setImage(image, for: .normal)
        }
    }
    
    func updateSoundButtonImage(soundEnabled: Bool) {
        var imageName = ""
        if soundEnabled {
            imageName = "volume_up"
        }
        else {
            imageName = "volume_off"
        }
        let bundle = Bundle(for: type(of: self))
        if let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal) {
            self.buttonSound.setImage(image, for: .normal)
        }
    }
    
    func updateFullScreenButtonImage(isFullScreen: Bool) {
        var imageName = ""
        if isFullScreen {
            imageName = "fullscreen_exit"
        }
        else {
            imageName = "fullscreen"
        }
        let bundle = Bundle(for: type(of: self))
        if let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal) {
            self.buttonFullScreen.setImage(image, for: .normal)
        }
    }
    
    func setProgressBarColor(min: UIColor, max: UIColor, thumb: UIColor) {
        self.sliderProgress.minimumTrackTintColor = min
        self.sliderProgress.maximumTrackTintColor = max
        
        if let image = self.sliderProgress.thumbImage(for: .normal) {
            let newImage = image.imageWithColor(thumb)
            self.sliderProgress.setThumbImage(newImage, for: .normal)
            self.sliderProgress.setThumbImage(newImage, for: .highlighted)
        }
    }
    
    //MARK: - Public methods
    
    func setUIEnabled(_ enabled: Bool) {
        self.buttonPlay.isUserInteractionEnabled = enabled
        self.buttonSound.isUserInteractionEnabled = enabled
        self.buttonPlayBig.isUserInteractionEnabled = enabled
        self.buttonFullScreen.isUserInteractionEnabled = enabled
        self.sliderProgress.isUserInteractionEnabled = enabled
    }
    
    func setBigPlayButtonHidden(_ hidden: Bool) {
        self.buttonPlayBig.isHidden = hidden
    }
    
    func setMaximumDuration(_ duration: Double) {
        self.sliderProgress.maximumValue = Float(duration)
    }
    
    func updatePlaybackTime(_ time: Double) {
        self.sliderProgress.value = Float(time)
        
        if self.timePresentationMode == .spent {
            self.labelTime.text = time.vmm_timeString()
        }
        else {
            let leftTime = Double(self.sliderProgress.maximumValue) - time
            self.labelTime.text = "-\(leftTime.vmm_timeString())"
        }
    }
    
    //MARK: - Private methods
    
    @objc private func toggleControlView() {
        if shouldShowControlView {
            let animationDuration = 0.25
            if self.controlView.isHidden {
                self.controlView.isHidden = false
                UIView.animate(withDuration: animationDuration, animations: {
                    self.controlView.alpha = CGFloat(1.0)
                }) { [weak self] _ in
                    self?.runControlViewTimer()
                }
            }
            else {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.controlView.alpha = CGFloat(0.0)
                }) { [weak self] _ in
                    self?.controlView.isHidden = true
                }
            }
        }
    }
    
    private func runControlViewTimer() {
        if self.timerControlView != nil {
            self.timerControlView?.invalidate()
            self.timerControlView = nil
        }
        if !self.controlView.isHidden {
            self.timerControlView = Timer.scheduledTimer(timeInterval: 5.0, target:self , selector: #selector(self.toggleControlView), userInfo: nil, repeats: false)
        }
    }
    
    //MARK: - Actions
    
    @objc private func onContentViewTap(sender: UITapGestureRecognizer) {
        self.toggleControlView()
    }
    
    @IBAction func onButtonPlay(sender: UIButton) {
        self.delegate?.didTapPlayButton()
        self.runControlViewTimer()
    }
    
    @IBAction func onButtonPlayBig(sender: UIButton) {
        self.delegate?.didTapPlayButton()
        self.runControlViewTimer()
    }
    
    @IBAction func onButtonTimePresentation(sender: UIButton) {
        if self.timePresentationMode == .spent {
            self.timePresentationMode = .left
        }
        else {
            self.timePresentationMode = .spent
        }
        
        self.updatePlaybackTime(Double(self.sliderProgress.value))
        self.runControlViewTimer()
    }
    
    @IBAction func onButtonSound(sender: UIButton) {
        self.delegate?.didTapSoundButton()
        self.runControlViewTimer()
    }
    
    @IBAction func onButtonFullScreen(sender: UIButton) {
        self.delegate?.didTapFullScreenButton()
    }
    
    @IBAction func sliderEndedTracking(sender: UISlider) {
        self.delegate?.didChangeProgressSliderValue(time: Double(self.sliderProgress.value))
        self.runControlViewTimer()
    }
}
