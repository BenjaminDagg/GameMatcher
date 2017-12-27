//
//  NewMessageViewController.swift
//  final
//
//  Created by Ronny Håland on 11/20/17.
//  Copyright © 2017 Benjamin Dagg. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseAuth

class NewMessageViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var Contacts:[String] = ["No Contacts, add through posts"]

    @IBOutlet weak var recipientField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    var user:User?
    var loggedInUser:String = "unknown"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround()
        let pickerView = UIPickerView()
        pickerView.delegate = self
        recipientField.inputView = pickerView
        messageTextView.layer.cornerRadius = 5
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let email = Auth.auth().currentUser?.email
        DatabaseHelper.getUsername(email: email!) { name in
            self.loggedInUser = name
            DatabaseHelper.getContacts(username: name){ contactlist in
                if contactlist.count > 0 {
                    self.Contacts = ["Choose a contact"]
                    self.Contacts.append(contentsOf: contactlist)
                }
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Contacts.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Contacts[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if Contacts[row] == "Choose a contact" {
            return
        }
        else {
            recipientField.text = Contacts[row]
        }
    }

    @IBAction func sendMessageAction(_ sender: Any) {
        let ref = Database.database().reference()
        let sender = loggedInUser
        let reciever = recipientField.text
        let content = messageTextView.text
        let msgTime = String(Int(Date().timeIntervalSince1970 * 10))
        if reciever != nil && reciever != "No Contacts, add through posts" && reciever != "Chose a contact" && content != nil{
            print("Trying to post message from \(sender) to \(reciever!), with content \(content!) at time \(msgTime)")
            let postDB = ["sender":sender, "reciever":reciever!, "content":content!, "date":msgTime]
            var child = ["/users/\(sender)/messages/\(msgTime)/": postDB]
            ref.updateChildValues(child)
            child = ["/users/\(reciever!)/messages/\(msgTime)/": postDB]
            ref.updateChildValues(child)
            // Just adds a copy of the message to both people involved
            
            if let navController = self.navigationController{
                navController.popViewController(animated: true)
            }
            
        } else {
        }
        
    }
}
