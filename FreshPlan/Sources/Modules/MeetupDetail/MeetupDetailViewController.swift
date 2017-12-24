//
//  MeetupDetailViewController.swift
//  FreshPlan
//
//  Created by Johnny Nguyen on 2017-12-17.
//  Copyright © 2017 St Clair College. All rights reserved.
//

import Foundation
import RxOptional
import RxSwift
import RxDataSources
import SnapKit
import MaterialComponents

public class MeetupDetailViewController: UIViewController {
  //MARK: UIView
  private var viewModel: MeetupDetailViewModelProtocol!
  private var router: MeetupDetailRouter!
  
  //MARK: AppBar
  private let appBar: MDCAppBar = MDCAppBar()
  private var backButton: UIBarButtonItem!
  private var deleteButton: UIBarButtonItem!
  
  //MARK: TableView
  private var tableView: UITableView!
  private var dataSource: RxTableViewSectionedReloadDataSource<MeetupDetailViewModel.Section>!
  private var refreshControl: UIRefreshControl!
  
  private let disposeBag: DisposeBag = DisposeBag()
  
  public convenience init(viewModel: MeetupDetailViewModel, router: MeetupDetailRouter) {
    self.init(nibName: nil, bundle: nil)
    self.viewModel = viewModel
    self.router = router
    
    addChildViewController(appBar.headerViewController)
  }
  
  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setNeedsStatusBarAppearanceUpdate()
    
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }
  
  public override var childViewControllerForStatusBarStyle: UIViewController? {
    return appBar.headerViewController
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    prepareView()
  }
  
  private func prepareView() {
    prepareRefreshControl()
    prepareTableView()
    prepareNavigationBar()
    prepareNavigationBackButton()
    prepareNavigationDeleteButton()
    appBar.addSubviewsToParent()
  }
  
  private func prepareRefreshControl() {
    refreshControl = UIRefreshControl()
    
    refreshControl.rx.controlEvent(.valueChanged)
      .asObservable()
      .subscribe(onNext: { [weak self] in
        guard let this = self else { return }
        this.viewModel.refreshContent.on(.next(()))
      })
      .disposed(by: disposeBag)
    
    viewModel.refreshSuccess
      .asObservable()
      .subscribe(onNext: { [weak self] in
        guard let this = self else { return }
        this.refreshControl.endRefreshing()
      })
      .disposed(by: disposeBag)
  }
  
  private func prepareTableView() {
    tableView = UITableView()
    tableView.refreshControl = refreshControl
    tableView.separatorInset = .zero
    tableView.estimatedRowHeight = 44
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.tableFooterView = UIView(frame: .zero)
    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    tableView.registerCell(MeetupTitleCell.self)
    tableView.registerCell(MeetupDescriptionCell.self)
    tableView.registerCell(MeetupLocationCell.self)
    tableView.registerCell(MeetupDirectionCell.self)
    tableView.registerCell(MeetupInviteCell.self)
    
    view.addSubview(tableView)
    
    tableView.snp.makeConstraints { make in
      make.edges.equalTo(view)
    }
    
    // configure dataSource
    dataSource = RxTableViewSectionedReloadDataSource<MeetupDetailViewModel.Section>(
      configureCell: { (dataSource, tableView, index, section) in
      switch dataSource[index] {
      case let .title(_, startDate, endDate):
        let cell = tableView.dequeueCell(ofType: MeetupTitleCell.self, for: index)
        cell.startDate.on(.next(startDate))
        cell.endDate.on(.next(endDate))
        return cell
      case let .desc(_, description):
        let cell = tableView.dequeueCell(ofType: MeetupDescriptionCell.self, for: index)
        cell.descriptionText.on(.next(description))
        return cell
      case let .location(_, title, latitude, longitude):
        let cell = tableView.dequeueCell(ofType: MeetupLocationCell.self, for: index)
        cell.title.on(.next(title))
        cell.latitude.on(.next(latitude))
        cell.longitude.on(.next(longitude))
        return cell
      case let .directions(_, text, _, _):
        let cell = tableView.dequeueCell(ofType: MeetupDirectionCell.self, for: index)
        cell.title.on(.next(text))
        return cell
      case let .invitations(_, _, invitee, email, accepted):
        let cell = tableView.dequeueCell(ofType: MeetupInviteCell.self, for: index)
        cell.displayName.on(.next(invitee))
        cell.email.on(.next(email))
        cell.accepted.on(.next(accepted))
        return cell
      default:
        return UITableViewCell()
      }
    })
    
    dataSource.titleForHeaderInSection = { dataSource, index in
      return index == 0 ? "" : dataSource[index].title
    }
    
    tableView.rx.modelSelected(MeetupDetailViewModel.SectionItem.self)
      .subscribe(onNext: { [weak self] item in
        guard let this = self else { return }
        switch item {
        case let .directions(_, _, latitude, longitude):
          try? this.router.route(
            from: this,
            to: MeetupDetailRouter.Routes.googlemaps.rawValue,
            parameters: [
              "latitude": latitude,
              "longitude": longitude
            ]
          )
        case let .invitations(_, inviteeId, _, _, _):
          try? this.router.route(
            from: this,
            to: MeetupDetailRouter.Routes.invitee.rawValue,
            parameters: [
              "inviteeId": inviteeId
            ]
          )
        default:
          return
        }
      })
      .disposed(by: disposeBag)
    
    viewModel.section
      .asObservable()
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
  }
  
  private func prepareNavigationBar() {
    appBar.headerViewController.headerView.backgroundColor = MDCPalette.blue.tint700
    appBar.navigationBar.tintColor = UIColor.white
    appBar.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white ]
    
    appBar.headerViewController.headerView.trackingScrollView = tableView
    
    viewModel.title
      .asObservable()
      .bind(to: navigationItem.rx.title)
      .disposed(by: disposeBag)
    
    appBar.navigationBar.observe(navigationItem)
  }
  
  private func prepareNavigationBackButton() {
    backButton = UIBarButtonItem(
      image: UIImage(named: "ic_arrow_back")?.withRenderingMode(.alwaysTemplate),
      style: .plain,
      target: nil,
      action: nil
    )
    
    backButton.rx.tap
      .asObservable()
      .subscribe(onNext: { [weak self] in
        guard let this = self else { return }
        try? this.router.route(
          from: this,
          to: MeetupDetailRouter.Routes.meetup.rawValue
        )
      })
      .disposed(by: disposeBag)
    
    navigationItem.leftBarButtonItem = backButton
  }
  
  private func prepareNavigationDeleteButton() {
    deleteButton = UIBarButtonItem(
      image: UIImage(named: "ic_delete")?.withRenderingMode(.alwaysTemplate),
      style: .plain,
      target: nil,
      action: nil
    )
    
    viewModel.canDelete
      .bind(to: deleteButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    viewModel.deleteHandler = deleteButton.rx.tap.asObservable()
    
    viewModel.bindButtons()
    
    viewModel.deleteSuccess
      .asObservable()
      .filter { $0 }
      .subscribe(onNext: { [weak self] _ in
        guard let this = self else { return }
        this.navigationController?.popViewController(animated: true)
        let message = MDCSnackbarMessage(text: "Successfully deleted meetup!")
        MDCSnackbarManager.show(message)
      })
      .disposed(by: disposeBag)
    
    viewModel.deleteSuccess
      .asObservable()
      .filter { !$0 }
      .subscribe(onNext: { _ in
        let message = MDCSnackbarMessage(text: "Cannot delete meetup. Are you sure you're the host?")
        MDCSnackbarManager.show(message)
      })
      .disposed(by: disposeBag)
    
    navigationItem.rightBarButtonItem = deleteButton
  }
  
  deinit {
    appBar.navigationBar.unobserveNavigationItem()
  }
}

//MARK: TableViewDelegate
extension MeetupDetailViewController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch dataSource[indexPath] {
    case .location:
      return 325
    default:
      return UITableViewAutomaticDimension
    }
  }
}

