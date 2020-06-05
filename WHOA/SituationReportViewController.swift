//
//  SituationReportViewController.swift
//  WHOA
//
//  Created by Jim Hildensperger on 05/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import UIKit
import Foundation

class SituationReportViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var whoImageView: UIImageView!
    
    private struct Constants {
        static let logoSize = CGSize(width: 200, height: 179)
    }
    
    private lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.contents = UIImage(named: "logo_mask")?.cgImage
        layer.frame = view.frame
        layer.bounds = CGRect(origin: .zero, size: Constants.logoSize)
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = view.center
        layer.fillRule = .evenOdd
        contentView.layer.mask = layer
        return layer
    }()
    
    private var locationManager = LocationManager()
    private var country: Country?
    private var situation: Situation?
    private var didAccessibiltyScroll: Bool = true
    
    private var viewModel: CountrySituationViewModel? {
        didSet {
            pageControl.numberOfPages = numberOfItems
            collectionView.reloadData()
        }
    }
    
    var numberOfItems: Int {
        return viewModel == nil ? 1 : 2
    }
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = NSLocalizedString("Latest Situation Reports", comment: "")
        whoImageView.accessibilityLabel = NSLocalizedString("World Health Organization Logo", comment: "")
        
        view.accessibilityElements = [titleLabel!, collectionView!, pageControl!, whoImageView!]
        
        locationManager.currentCountryDidUpdate = { [weak self] country in
            self?.configureForCountry(country: country)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateAppearance { [weak self] in
            self?.locationManager.getCurrentLocation()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func pageControlValueChanged() {
        didAccessibiltyScroll = false
        collectionView.scrollToItem(at: IndexPath(item: pageControl.currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    // MARK: - Private
    
    private func animateAppearance(completion: @escaping () -> Void) {
        let animationKeyPath = "bounds"
        let initalBounds = NSValue(cgRect: maskLayer.bounds)
        let secondBounds = NSValue(cgRect: CGRect(origin: .zero, size: CGSize(width: Constants.logoSize.width * 0.9, height: Constants.logoSize.height * 0.9)))
        let finalBounds = NSValue(cgRect: CGRect(origin: .zero, size: CGSize(width: Constants.logoSize.width * 9, height: Constants.logoSize.height * 9)))
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.contentView.layer.mask = nil
            completion()
        }
        
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: animationKeyPath)
        keyFrameAnimation.duration = 0.85
        keyFrameAnimation.timingFunctions = [CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut), CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)]
        keyFrameAnimation.values = [initalBounds, secondBounds, finalBounds]
        keyFrameAnimation.keyTimes = [0, 0.4, 1]
        maskLayer.add(keyFrameAnimation, forKey: animationKeyPath)
        CATransaction.commit()
        maskLayer.bounds = finalBounds.cgRectValue
    }
    
    private func configureForCountry(country: Country?) {
        guard let country = country else {
            viewModel = nil
            situation = nil
            self.country = nil
            return
        }
        
        Situation.getSituation(country: country) { [weak self] Situation in
            self?.country = country
            self?.situation = Situation
            self?.viewModel = CountrySituationViewModel(country: country, data: Situation)
        }
    }
}

extension UICollectionViewCell {
    func render() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension SituationReportViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row == 1, let countrySituationCell: CountrySituationCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath) else {
            guard let introCell: IntroductionCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath) else {
                fatalError()
            }
            
            let introText = NSLocalizedString("Swipe right to continue", comment: "")
            introCell.isAccessibilityElement = true
            introCell.accessibilityLabel = introText
            introCell.accessibilityIdentifier = "introCell"
            introCell.titleLabel.text = introText
            return introCell
        }
        
        guard let viewModel = viewModel else {
            return countrySituationCell
        }
        
        countrySituationCell.titleLabel.text = viewModel.titleText
        countrySituationCell.casesNumberLabel.text = viewModel.casesNumberText
        countrySituationCell.casesTitleLabel.text = viewModel.casesTitleText
        countrySituationCell.deathsLabel.text = viewModel.deathsText
        
        countrySituationCell.isAccessibilityElement = true
        countrySituationCell.accessibilityHint = NSLocalizedString("Share on social media.", comment: "")
        countrySituationCell.accessibilityLabel = viewModel.sentenceText
        countrySituationCell.accessibilityIdentifier = "countrySituationCell"
        
        return countrySituationCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row == 1 else {
            return
        }
        
        guard let viewModel = viewModel,
            let iso = country?.isoCode,
            let url = URL(string: "https://covid19.who.int/region/emro/country/\(iso)"),
            let image = collectionView.cellForItem(at: indexPath)?.render() else {
                return
        }
        
        let items: [Any] = [viewModel.sentenceText, url, image]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

extension SituationReportViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageControl()
        didAccessibiltyScroll = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updatePageControl()
        didAccessibiltyScroll = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if didAccessibiltyScroll {
            updatePageControl()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        didAccessibiltyScroll = false
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        didAccessibiltyScroll = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        didAccessibiltyScroll = false
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        didAccessibiltyScroll = false
    }
    
    private func updatePageControl() {
        var point = collectionView.contentOffset
        point.x += collectionView.frame.width/2.0
        pageControl.currentPage = collectionView.indexPathForItem(at: point)?.row ?? 0
    }
}
