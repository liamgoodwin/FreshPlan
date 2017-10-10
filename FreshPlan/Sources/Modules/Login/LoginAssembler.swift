//
//  LoginAssembler.swift
//  FreshPlan
//
//  Created by Johnny Nguyen on 2017-10-05.
//  Copyright © 2017 St Clair College. All rights reserved.
//

import UIKit
import Moya

public final class LoginAssembler: AssemblerProtocol {
	public static func make() -> UIViewController {
		let viewModel = LoginViewModel(provider: provider)
		let router = LoginRouter()
		return LoginViewController(viewModel: viewModel, router: router)
	}
	
	private static var provider: RxMoyaProvider<FreshPlan> {
		return RxMoyaProvider<FreshPlan>()
	}
}
