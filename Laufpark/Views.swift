//
//  Views.swift
//  Laufpark
//
//  Created by Chris Eidhof on 17.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit
import Incremental
import MapKit

final class TrackInfoView {
    private var lineView: IBox<LineView>
    var view: UIView! = nil
    var disposables: [Any] = []
    
    // 0...1.0
    var pannedLocation: I<CGFloat> {
        return _pannedLocation.i
    }
    private var _pannedLocation: Input<CGFloat> = Input(0)
    
    init(position: I<CGFloat?>, points: I<[CGPoint]>, pointsRect: I<CGRect>, track: I<Track?>, darkMode: I<Bool>) {
        let blurredViewForeground: I<UIColor> = if_(darkMode, then: I(constant: .white), else: I(constant: .black))
        self.lineView = buildLineView(position: position, points: points, pointsRect: pointsRect, strokeColor: blurredViewForeground)

        
        // Lineview
        lineView.unbox.heightAnchor.constraint(equalToConstant: 100).isActive = true
        lineView.unbox.backgroundColor = .clear
        lineView.unbox.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(linePanned(sender:))))
        
        let formatter = MKDistanceFormatter()
        let formattedDistance = track.map { track in
            track.map { formatter.string(fromDistance: $0.distance) }
        } ?? ""
        let formattedAscent = track.map { track in
            track.map { "↗ \(formatter.string(fromDistance: $0.ascent))" }
        } ?? ""
        let name = label(text: track.map { $0?.name ?? "" }, textColor: blurredViewForeground.map { $0 })
        let totalDistance = label(text: formattedDistance, textColor: blurredViewForeground.map { $0 })
        let totalAscent = label(text: formattedAscent, textColor: blurredViewForeground.map { $0 })
        // Track information
        let trackInfo = IBox<UIStackView>(arrangedSubviews: [name, totalDistance, totalAscent])
        trackInfo.unbox.axis = .horizontal
        trackInfo.unbox.distribution = .equalCentering
        trackInfo.unbox.heightAnchor.constraint(equalToConstant: 20)
        trackInfo.unbox.spacing = 10
        disposables.append(trackInfo) // need to keep a reference
        
        let blurEffect = if_(darkMode, then: UIBlurEffect(style: .dark), else: UIBlurEffect(style: .light))
        let blurredView = UIVisualEffectView(effect: nil)
        disposables.append(blurEffect.observe { effect in
            UIView.animate(withDuration: 0.2) {
                blurredView.effect = effect
            }
        })
        blurredView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [trackInfo.unbox, lineView.unbox])
        blurredView.contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.addConstraintsToSizeToParent(spacing: 10)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view = blurredView
    }
    
    @objc func linePanned(sender: UIPanGestureRecognizer) {
        let normalizedLocation = (sender.location(in: lineView.unbox).x /
            lineView.unbox.bounds.size.width).clamped(to: 0.0...1.0)
        _pannedLocation.write(normalizedLocation)
    }
}


extension UIView {
    func addConstraintsToSizeToParent(spacing: CGFloat = 0) {
        guard let view = superview else { fatalError() }
        let top = topAnchor.constraint(equalTo: view.topAnchor)
        let bottom = bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let left = leftAnchor.constraint(equalTo: view.leftAnchor)
        let right = rightAnchor.constraint(equalTo: view.rightAnchor)
        view.addConstraints([top,bottom,left,right])
        if spacing != 0 {
            top.constant = spacing
            left.constant = spacing
            right.constant = -spacing
            bottom.constant = -spacing
        }
    }
}




func buildMapView() -> IBox<MKMapView> {
    let box = IBox(MKMapView())
    let view = box.unbox
    view.showsCompass = true
    view.showsScale = true
    view.showsUserLocation = true
    view.mapType = .standard
    view.isRotateEnabled = false
    view.isPitchEnabled = false
    return box
}

func polygonRenderer(polygon: MKPolygon, strokeColor: I<UIColor>, fillColor: I<UIColor?>, alpha: I<CGFloat>, lineWidth: I<CGFloat>) -> IBox<MKPolygonRenderer> {
    let renderer = MKPolygonRenderer(polygon: polygon)
    let box = IBox(renderer)
    box.bind(strokeColor, to: \.strokeColor)
    box.bind(alpha, to : \.alpha)
    box.bind(lineWidth, to: \.lineWidth)
    box.bind(fillColor, to: \.fillColor)
    return box
}

func annotation(location: I<CLLocationCoordinate2D>) -> IBox<MKPointAnnotation> {
    let result = IBox(MKPointAnnotation())
    result.bind(location, to: \.coordinate)
    return result
}

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

func buildLineView(position: I<CGFloat?>, points: I<[CGPoint]>, pointsRect: I<CGRect>, strokeColor: I<UIColor>) -> IBox<LineView> {
    let box = IBox(LineView())
    box.bind(position, to: \LineView.position)
    box.bind(points, to: \.points)
    box.bind(pointsRect, to: \.pointsRect)
    box.bind(strokeColor, to: \.strokeColor)
    return box
}
