//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        title = K.appName
        navigationItem.hidesBackButton = true
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = true
        
        loadData()
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let message = messageTextfield.text, let user = Auth.auth().currentUser?.email {
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField: user,
                                                                      K.FStore.bodyField: message,
                                                                      K.FStore.dateField: Date.timeIntervalSinceReferenceDate]) { (error) in
                if let e = error {
                    print(e)
                } else {
                    print("Saved data!")
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    func loadData() {
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, error) in
            self.messages = []
            
            if let err = error {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if let sender = document.data()[K.FStore.senderField] as? String,
                       let body = document.data()[K.FStore.bodyField] as? String {
                        self.messages.append(Message(sender: sender, body: body))
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
}

extension ChatViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageTableViewCell
        cell.label.text = "\(messages[indexPath.row].body)"
        return cell
    }
}
