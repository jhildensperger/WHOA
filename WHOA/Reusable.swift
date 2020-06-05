//
//  Reusable.swift
//  WHOA
//
//  Created by Jim Hildensperger on 06/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import Foundation
import UIKit

protocol Reusable: class {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String { return String(describing: self) }
}

extension UICollectionReusableView: Reusable { }

extension UICollectionView {
    func dequeueReusableCell<Cell: UICollectionViewCell>(for indexPath: IndexPath) -> Cell? {
        return self.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath as IndexPath) as? Cell
    }
}
