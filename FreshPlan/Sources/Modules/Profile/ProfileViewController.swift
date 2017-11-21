//
//  ProfileViewController.swift
//  FreshPlan
//
//  Created by Johnny Nguyen on 2017-11-16.
//  Copyright © 2017 St Clair College. All rights reserved.
//

import Foundation
import RxSwift
import RxOptional
import RxDataSources
import MaterialComponents

public final class ProfileViewController: UIViewController {
	//: MARK - Profile View Model and Router
	private var viewModel: ProfileViewModelProtocol!
	private var router: ProfileRouter!
	
	//: MARK - AppBar
	fileprivate let appBar: MDCAppBar = MDCAppBar()
	
	//: MARK - DisposeBag
	private let disposeBag: DisposeBag = DisposeBag()
	
	//: MARK - TableView
	private var profileTableView: UITableView!
	private var dataSource: RxTableViewSectionedReloadDataSource<ProfileViewModel.SectionModel>!
	
	public convenience init(viewModel: ProfileViewModel, router: ProfileRouter) {
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
		prepareProfileTableView()
		prepareNavigationBar()
		appBar.addSubviewsToParent()
	}
	
	private func prepareNavigationBar() {
		appBar.headerViewController.headerView.backgroundColor = MDCPalette.blue.tint700
		appBar.headerViewController.headerView.trackingScrollView = self.profileTableView
		appBar.navigationBar.tintColor = UIColor.white
		appBar.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white ]
		
		Observable.just("Profile")
			.bind(to: navigationItem.rx.title)
			.disposed(by: disposeBag)
		
		appBar.navigationBar.observe(navigationItem)
	}
	
	private func prepareProfileTableView() {
		profileTableView = UITableView()
		profileTableView.rowHeight = 80
		profileTableView.estimatedRowHeight = UITableViewAutomaticDimension
		profileTableView.rx.setDelegate(self).disposed(by: disposeBag)
		profileTableView.registerCell(ProfileUserHeaderCell.self)
	
		view.addSubview(profileTableView)
		
		profileTableView.snp.makeConstraints { $0.edges.equalTo(view) }
		
		// set up data sources
		dataSource = RxTableViewSectionedReloadDataSource<ProfileViewModel.SectionModel>(configureCell: { (dataSource, table, index, _) in
			switch dataSource[index] {
			case let .profile(_, profileURL, fullName):
				let cell = table.dequeueCell(ofType: ProfileUserHeaderCell.self, for: index)
				cell.fullName.on(.next(fullName))
				cell.profileURL.on(.next(profileURL))
				return cell
//			case let .displayName(_, name):
//				guard let cell = table.dequeueReusableCell(withIdentifier: "defaultCell") else { fatalError() }
//				cell.textLabel?.text = name
//				return cell
//			case let .email(_, description):
//				guard let cell = table.dequeueReusableCell(withIdentifier: "defaultCell") else { fatalError() }
//				cell.textLabel?.text = description
//				return cell
			default:
				return UITableViewCell()
			}
		})
		
		dataSource.titleForHeaderInSection = { _, _ in
			return ""
		}
		
		viewModel.profileItems
			.asObservable()
			.bind(to: profileTableView.rx.items(dataSource: dataSource))
			.disposed(by: disposeBag)
	}
}

// MARK: UIScrollViewDelegate
extension ProfileViewController: UITableViewDelegate {
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView == appBar.headerViewController.headerView.trackingScrollView {
			appBar.headerViewController.headerView.trackingScrollDidScroll()
		}
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if scrollView == appBar.headerViewController.headerView.trackingScrollView {
			appBar.headerViewController.headerView.trackingScrollDidEndDecelerating()
		}
	}

	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		let headerView = appBar.headerViewController.headerView
		if scrollView == headerView.trackingScrollView {
			headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
		}
	}

	public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		let headerView = appBar.headerViewController.headerView
		if scrollView == headerView.trackingScrollView {
			headerView.trackingScrollWillEndDragging(withVelocity: velocity, targetContentOffset: targetContentOffset)
		}
	}
}
