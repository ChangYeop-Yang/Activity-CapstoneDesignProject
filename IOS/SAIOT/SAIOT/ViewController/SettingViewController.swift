//
//  SettingViewController.swift
//  SAIOT
//
//  Created by 양창엽 on 2018. 4. 4..
//  Copyright © 2018년 Yang-Chang-Yeop. All rights reserved.
//

import UIKit
import MessageUI
import AudioToolbox

// MARK: - Enum
fileprivate enum TabelRowAt: Int {
    case Email = 10
    case Introduce = 11
    case OpenSource = 12
    case PrivacyPolicy = 13
    case HueReset = 17
    case AppHelp = 16
    case SmartBoxAddress = 30
    case SocketAddress = 31
}
fileprivate enum SwitchCellAt: Int {
    case AppAlarm = 1000
    case HuePower = 3000
    case MonitorAlarm = 2000
    case NetworkInfoHue = 4000
}

class SettingViewController: UIViewController {
    
    // MARK: - Variable
    private let SmartBoxKey: String = "SMART_BOX_KEY"
    
    // MARK: - Outlet Variables
    private var settingTable: UITableView!
    private let settingTableIndexPaths: [(index: IndexPath, cellAt: SwitchCellAt)] = [
        (IndexPath(row: 0, section: 1), .AppAlarm),
        (IndexPath(row: 1, section: 1), .MonitorAlarm),
        (IndexPath(row: 1, section: 2), .HuePower),
        (IndexPath(row: 2, section: 2), .NetworkInfoHue)
    ]
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let settingTableVC = segue.destination as? UITableViewController {
            settingTableVC.tableView.delegate = self
            settingTable = settingTableVC.tableView
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()
        
        // Setting Detail Cell
        let userDefaults: UserDefaults = UserDefaults.standard
        for cell in settingTableIndexPaths {
            
            if let cellAt: UITableViewCell = settingTable.cellForRow(at: cell.index), let cellSwitch: UISwitch = cellAt.accessoryView as? UISwitch {
                
                switch cell.cellAt {
                    case .AppAlarm:
                        if let value = userDefaults.object(forKey: DefaultsKey.AlarmKey.rawValue) {
                            cellSwitch.isOn = value as! Bool
                        }
                    case .HuePower:
                        if let value = userDefaults.object(forKey: DefaultsKey.HuePowerKey.rawValue) {
                            cellSwitch.isOn = value as! Bool
                        }
                    case .MonitorAlarm:
                        if let value = userDefaults.object(forKey: DefaultsKey.MonitorKey.rawValue) {
                            cellSwitch.isOn = value as! Bool
                        }
                    default: break
                }
                
                cellSwitch.addTarget(self, action: #selector(changeUISwitch), for: UIControlEvents.valueChanged)
            }
        }
    }
    
    // MARK: - Method
    @objc private func changeUISwitch(switchView: UISwitch) {
        
        let defaults = UserDefaults.standard
        
        if let type: SwitchCellAt = SwitchCellAt(rawValue: switchView.tag) {
            switch type {
                case .AppAlarm:
                    defaults.set(switchView.isOn, forKey: DefaultsKey.AlarmKey.rawValue)
                    showWhisperToast(title: "Occur AppAlarm Change Value Event", background: .moss, textColor: .white)
                    print("- Occur AppAlarm UISwitch Change Value Event.")
                case .HuePower:
                    defaults.set(switchView.isOn, forKey: DefaultsKey.HuePowerKey.rawValue)
                    showWhisperToast(title: "Occur HuePower Change Value Event", background: .moss, textColor: .white)
                    print("- Occur HuePower UISwitch Change Value Event.")
                case .MonitorAlarm:
                    defaults.set(switchView.isOn, forKey: DefaultsKey.MonitorKey.rawValue)
                    showWhisperToast(title: "Occur Monitor Change Value Event", background: .moss, textColor: .white)
                    print("- Occur Monitor UISwitch Change Value Event.")
                
                    let repeatNotification: LocalNotification = LocalNotification(title: "Smart Post Box", subTitle: "Detection", body: "스마트 우편 상자에서 사진을 촬영하였습니다.", repeat: true)
                    
                    switchView.isOn ? repeatNotification.occurRepeatNotification(id: SmartBoxKey) : repeatNotification.removeNotification(id: SmartBoxKey)
                default: break
            }
        }
    }
}

// MARK: - TableView Delegate Extension
extension SettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let tag: Int = tableView.cellForRow(at: indexPath)?.tag, let cell: TabelRowAt = TabelRowAt(rawValue: tag) {
            
            switch cell {
                case .Introduce:
                    if let url: URL = URL(string: "http://yeop9657.blog.me") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                case .Email:
                    if MFMailComposeViewController.canSendMail() {
                        let mail: MFMailComposeViewController = MFMailComposeViewController()
                        mail.mailComposeDelegate = self
                        mail.setSubject("Inquiry SAIOT inconvenient comment")
                        mail.setToRecipients(["yeop9657@outlook.com"])
                        mail.setMessageBody("Please, Input inconvenient comment.", isHTML: false)
                        present(mail, animated: true, completion: nil)
                    }
                case .OpenSource:
                    if let url: URL = URL(string: "http://yeop9657.blog.me/221270349222") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                case .PrivacyPolicy:
                    if let url: URL = URL(string: "http://yeop9657.blog.me/221270338767") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                case .HueReset:
                    userDefaults.removeObject(forKey: "HUE_BRIDGE_KEY")
                    showWhisperToast(title: "Success delete hue bridge configuration.", background: .moss, textColor: .white)
                case .SmartBoxAddress:
                    let inputAlert: UIAlertController = UIAlertController(title: "SMART BOX SERVER ADDRESS", message: "스마트 박스 서버 주소를 입력해주세요.", preferredStyle: .alert)
                    inputAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [unowned self] _ in
                        if let text = inputAlert.textFields?.first?.text, text.isEmpty == false {
                            userDefaults.set(text, forKey: DefaultsKey.SmartBoxAddressKey.rawValue)
                            showWhisperToast(title: "APPLY SMART BOX ADDRESS", background: .moss, textColor: .white)
                        }
                    }))
                    inputAlert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                    inputAlert.addTextField(configurationHandler: nil)
                    present(inputAlert, animated: true, completion: nil)
                
                case .SocketAddress:
                    let inputAlert: UIAlertController = UIAlertController(title: "SOCKET SERVER ADDRESS", message: "통신 서버 주소를 입력해주세요.", preferredStyle: .alert)
                    inputAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [unowned self] _ in
                        if let text = inputAlert.textFields?.first?.text , text.isEmpty == false {
                            userDefaults.set(text, forKey: DefaultsKey.SocketAddressKey.rawValue)
                            showWhisperToast(title: "APPLY SOCKET ADDRESS", background: .moss, textColor: .white)
                        }
                    }))
                    inputAlert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                    inputAlert.addTextField(configurationHandler: nil)
                    present(inputAlert, animated: true, completion: nil)
                
                default: break
            }
        }
    }
}

// MARK: - MFMailComposeViewController Delegate
extension SettingViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
            case .sent:
                print("Success E-mail send to developer.")
            case .cancelled:
                print("Cancel E-mail send to developer.")
            case .saved:
                print("Save E-mail content into disk.");
            case .failed:
                print("Fail E-mail send to developer.")
        }
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
}

