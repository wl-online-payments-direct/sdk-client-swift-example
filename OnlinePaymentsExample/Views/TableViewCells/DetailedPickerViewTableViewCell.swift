//
// Do not remove or alter the notices in this preamble.
// This software code is created for Online Payments on 04/08/2020
// Copyright © 2020 Global Collect Services. All rights reserved.
//

import UIKit
import OnlinePaymentsKit

class DetailedPickerViewTableViewCell: PickerViewTableViewCell, UIPickerViewDelegate {
    var labelView = UITextView()
    override class var reuseIdentifier: String {
        return "detailed-picker-view-cell"
    }
    var transitiveDelegate: UIPickerViewDelegate?
    var currencyFormatter: NumberFormatter!
    var percentFormatter: NumberFormatter!
    var fieldIdentifier: String!
    let errorLabel = Label()
    private var labelNeedsUpdate = true

    override var delegate: UIPickerViewDelegate? {
        get {
            return transitiveDelegate
        }
        set {
            transitiveDelegate = newValue
        }
    }

    override var items: [ValueMappingItem]? {
        didSet {
            pickerView.content = items?.map { $0.displayName! } ?? []
        }
    }

    override var selectedRow: Int? {
        get {
            return pickerView.selectedRow(inComponent: 0)
        }
        set {
            pickerView.selectRow(newValue ?? 0, inComponent: 0, animated: false)
            if labelNeedsUpdate {
                self.updateLabel(row: newValue ?? 0)
            }

        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(pickerView)
        addSubview(labelView)
        addSubview(errorLabel)

        pickerView.delegate = self
        labelView.isEditable = false
        labelView.isScrollEnabled = false
        labelView.dataDetectorTypes = UIDataDetectorTypes.link

        errorLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        errorLabel.numberOfLines = 0
        errorLabel.textColor = .red

        self.clipsToBounds = true
        self.setNeedsLayout()
        contentView.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func pickerView(
        _ pickerView: UIPickerView,
        attributedTitleForRow row: Int,
        forComponent component: Int
    ) -> NSAttributedString? {
        return delegate?.pickerView!(_: pickerView, attributedTitleForRow: row, forComponent: component)
    }

    func updateLabel(row: Int) {
        self.labelNeedsUpdate = false

        self.labelView.attributedText = label(row: row)
        labelView.sizeToFit()

    }

    func label(row: Int) -> NSAttributedString {
        if (self.items?[row].displayElements.count ?? 0) < 2 {
            return NSAttributedString()
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops =
            [
                NSTextTab(
                    textAlignment: NSTextAlignment.right,
                    location: self.accessoryAndMarginCompatibleWidth() - 10,
                    options: [:]
                )
            ]

        let attributedString = self.items?[self.selectedRow ?? 0].displayElements
            .map({(element) in self.attributedStringFromDisplayElement(element: element)})
            .reduce(NSMutableAttributedString()) {(old, new) in
                if old.length > 0 {
                    old.append(NSAttributedString(string: "\n"))
                }
                old.append(new)
                return old}
        attributedString?.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: (attributedString?.length)!)
        )
        return attributedString ?? NSAttributedString()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.updateLabel(row: row)
        delegate?.pickerView!(_: pickerView, didSelectRow: row, inComponent: component)
    }

    func attributedStringFromDisplayElement(element: DisplayElement) -> NSAttributedString {
        let returnValue = NSMutableAttributedString()
        let left: NSAttributedString
        let right: NSAttributedString?
        let elementId = element.id

        switch element.type {
        case .currency:
            left = NSAttributedString(string: elementId)
            right =
                NSAttributedString(string: currencyFormatter.string(from: NSNumber(value: Double(element.value)!/100))!)
        case .percentage:
            left = NSAttributedString(string: elementId)
            right =
                NSAttributedString(string: percentFormatter.string(from: NSNumber(value: Double(element.value)!/100))!)
        case .string:
            left = NSAttributedString(string: elementId)
            right = NSAttributedString(string: element.value)
        case .uri:
            left = NSAttributedString(string: elementId, attributes: [NSAttributedString.Key.link: element.value])
            right = nil
        case .integer:
            left = NSAttributedString(string: elementId)
            right = NSAttributedString(string: element.value)
        }
        returnValue.append(left)
        if let right = right {
            returnValue.append(NSAttributedString(string: "\t"))
            returnValue.append(right)

        }
        return returnValue
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = self.accessoryAndMarginCompatibleWidth()
        let leftMargin = self.accessoryCompatibleLeftMargin()

        errorLabel.frame =
            CGRect(x: leftMargin, y: DetailedPickerViewTableViewCell.pickerHeight + 5, width: width, height: 500)
        errorLabel.preferredMaxLayoutWidth = width - 20
        errorLabel.sizeToFit()

        var labelFrame =
            CGRect(
                x: leftMargin,
                y: DetailedPickerViewTableViewCell.pickerHeight + 10 + errorLabel.frame.size.height,
                width: width,
                height: DatePickerTableViewCell.pickerHeight
            )
        labelFrame.size.height =
            self.labelView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
        self.labelView.frame = labelFrame

        if labelNeedsUpdate {
            updateLabel(row: selectedRow ?? 0)
        }
    }

    override func prepareForReuse() {
        dataSource = nil
        selectedRow = nil
        items = []
    }
}
