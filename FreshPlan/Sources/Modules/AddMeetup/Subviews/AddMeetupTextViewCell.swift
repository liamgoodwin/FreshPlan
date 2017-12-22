//
//  AddMeetupTextViewCell.swift
//  FreshPlan
//
//  Created by Johnny Nguyen on 2017-12-22.
//  Copyright © 2017 St Clair College. All rights reserved.
//

import Foundation
import RxSwift
import SnapKit
import MaterialComponents
import UIKit
import RxCocoa

public final class AddMeetupTextViewCell: UITableViewCell {
  //MARK: Subjects
  public var title: PublishSubject<String> = PublishSubject()
  private var placeholder: Variable<String> = Variable("")
  
  //MARK: Views
  private var textView: UITextView!
  
  //MARK: DisposeBag
  public let disposeBag: DisposeBag = DisposeBag()
  
  //MARK: Events
  public var textChanged: ControlEvent<Void> {
    return textView.rx.didChange
  }
  
  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    prepareView()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  private func prepareView() {
    selectionStyle = .none
    prepareTextView()
  }
  
  private func prepareTextView() {
    textView = UITextView()
    textView.font = MDCTypography.body1Font()
    textView.isScrollEnabled = false
    
    contentView.addSubview(textView)
    
    textView.snp.makeConstraints { make in
      make.edges.equalTo(contentView)
    }
    
    // create an initial placetext
    textView.textColor = .lightGray
    
    title.asObservable()
      .bind(to: textView.rx.text)
      .disposed(by: disposeBag)
    
    title.asObservable()
      .bind(to: placeholder)
      .disposed(by: disposeBag)
    
    textView.rx.didBeginEditing
      .subscribe(onNext: { [weak self] in
        guard let this = self else { return }
        if this.textView.textColor == .lightGray {
          this.textView.text = nil
          this.textView.textColor = .black
        }
      })
      .disposed(by: disposeBag)
    
    textView.rx.didEndEditing
      .subscribe(onNext: { [weak self] in
        guard let this = self else { return }
        if this.textView.text.isEmpty {
          this.textView.textColor = .lightGray
          this.textView.text = this.placeholder.value
        }
      })
      .disposed(by: disposeBag)
  }
}
