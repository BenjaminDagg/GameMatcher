//
//  PostDetailViewController.swift
//  final
//
//  Created by Benjamin Dagg on 12/3/17.
//  Copyright © 2017 Benjamin Dagg. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseAuth

class PostDetailViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var tapToViewLabel: UILabel!
    @IBOutlet weak var gameTitleLabel: UILabel!
    @IBOutlet weak var gameImg: UIImageView!
    @IBOutlet weak var propertiesStackView: UIStackView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var platformImg: UIImageView!
    @IBOutlet weak var gamertagLabel: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContainer: UIView!
    @IBOutlet weak var contactBtn: UIButton!
    
    
    
    
    var user:User?
    var post:Post?
    var postInfo = Dictionary<String,Any>()
    let recognizer = UITapGestureRecognizer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup scrolview
        self.scrollView.delegate = self
        
        //make message field un-editable by user
        self.messageTextView.isEditable = false
        
        //setup tap gesture recognizer to trigger when progile img clicked
        self.profileImg.isUserInteractionEnabled = true
        recognizer.addTarget(self, action: #selector(showUserProfile))
        profileImg.addGestureRecognizer(recognizer)
        
        self.contactBtn.addTarget(self, action: #selector(addContact), for: .touchUpInside)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        //download post info from database
        getPostInfo( completin: {
            
            //download user profile image with the given username
            if let username = self.postInfo["user"] as? String {
                self.getUserProfileImgifExists(username: username)
                self.getUser(username: username)
            }
            if let message = self.postInfo["message"] as? String {
                self.messageTextView.text = message
                if message != "" && message != "none" {
                    self.messageTextView.isHidden = false
                }else {
                    self.messageTextView.isHidden = true
                }
            }else {
                self.messageTextView.isHidden = true
            }
            
            if let properties = self.postInfo["properties"] as? Dictionary<String,Any> {
                if let level = properties["level"] as? String {
                    self.levelLabel.text = "Level: \(level)"
                    self.levelLabel.isHidden = false
                }else {
                    self.levelLabel.isHidden = true
                }
                if let rank = properties["rank"] as? String {
                    self.rankLabel.text = "Rank: \(rank)"
                    self.rankLabel.isHidden = false
                }else {
                    self.rankLabel.isHidden = true
                }
                if let role = properties["role"] as? String {
                    self.roleLabel.text = "Role: \(role)"
                    self.roleLabel.isHidden = false
                }else {
                    self.roleLabel.isHidden = true
                }
            }
        })
        
        //set the views to the info passed in from the pst
        if let post = self.post {
            if let img = post.gameImg {
                self.gameImg.image = img
            }
            self.gamertagLabel.text = "Gamertag: \(post.gamertag)"
            self.gameTitleLabel.text = post.gameTitle
            self.regionLabel.text = "Region \(post.region.rawValue)"
            switch post.platform {
            case .PC:
                self.platformImg.image = UIImage(named: "steamlogo")
            case .PS3:
                 self.platformImg.image = UIImage(named: "ps3logo")
            case .PS4:
                self.platformImg.image = UIImage(named: "ps4logo")
            case .Xbox360:
                self.platformImg.image = UIImage(named: "xbox360logo")
            case .XboxOne:
                self.platformImg.image = UIImage(named: "xboxonelogo")
            //default: break
                
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //setup scrollview content size
        self.scrollView.frame = self.view.frame
        self.scrollView.contentSize = CGSize(width: self.view.frame.width, height:800)
    }
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPostUserProfile" {
            if let destinationVC = segue.destination as? ProfileViewController {
                if let user = self.user {
                    destinationVC.targetUser = user
                    destinationVC.profilePermission = ProfilePermission.VIEW_ONLY
                }
            }else {
                return
            }
        }
    }
    
    
    
    /*
    Gets the post info from the database and puts it into a dictionary
    */
    func getPostInfo(completin: @escaping (Void) -> Void) {
        
        //get post info from database
        if let post = self.post {
            //parse a string from the date
            let postDate = post.postDate
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
            let dateStr = formatter.string(from: postDate)
            
            //lookup post in database
            let ref = Database.database().reference()
            ref.child("Posts").child(dateStr).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    if let value = snapshot.value as? NSDictionary {
                        print("saved post info")
                        self.postInfo = value as! Dictionary<String, Any>
                        completin()
                    }
                }
            })
        }
    }
    
    
    
    /*
     Searches Daatabase for the proifle image of the user who posted this post. If it exists then sets the profile img to their profile. If doesnt exists, leaved image as the default profile image
    */
    func getUserProfileImgifExists(username: String) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            let ref = Database.database().reference()
            ref.child("users").child(username).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.hasChild("userPhoto") {
                    let value = snapshot.value as? NSDictionary
                    if let value = value {
                        if let filePath = value["userPhoto"] as? String{
                            storageRef.child(filePath).getData(maxSize: 10 * 1024 * 1024, completion: {(data, error) in
                                
                                if let error = error {
                                    print(error.localizedDescription)
                                    return
                                }else {
                                    let userPhoto = UIImage(data: data!)
                                    
                                    DispatchQueue.main.async {
                                        self.profileImg.image = userPhoto
                                    }
                                }
                            })
                            
                        }
                    }
                }
            })
        }
        
    }
    
    
    
    /*
    Looks up posts author in the database and returns it in the user object
    */
    func getUser(username: String) {
        let ref = Database.database().reference()
        ref.child("users").observeSingleEvent(of: .value, with: { snapshot in
            
            let enumerator = snapshot.children
            while let child = enumerator.nextObject() as? DataSnapshot {
                if let value = child.value as? NSDictionary {
                    if let usernameDB = value["username"] as? String {
                        if usernameDB == username {
                         
                            guard let email = value["email"] as? String, let name = value["name"] as? String, let region = value["region"] as? String, let id = value["uid"] as? String else {
                                return
                            }
                            self.user = User(userName: usernameDB, name: name, email: email, userID: id, games: nil, region: Region.stringToCase(string: region))
                            print("got user from database")
                        }
                    }
                }
            }
        })
        
    }
    
    
    
    //disable horizontal scrolling on scroll view
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 || scrollView.contentOffset.x < 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    
    
    /*
    When profile image is clicked, segue to the users profile
    */
    func showUserProfile() {
        
        if self.user != nil {
            performSegue(withIdentifier: "showPostUserProfile", sender: self)
        }
        
    }
    
    func addContact(sender: UIButton) {
        print("clicked contacts button")
        /*
         if let posterUsername = user?.userName{
         let email = Auth.auth().currentUser?.email
         print("trying to add \(email)")
         
         DatabaseHelper.getUsername(email: email!) { name in
         print(name)
         DatabaseHelper.getContacts(username: name) {contacts in
         print(contacts)
         print(posterUsername)
         if name != posterUsername && !contacts.contains(posterUsername){
         let ref = Database.database().reference()
         let postDB = [posterUsername:self.user?.userID ?? "unknown ID"]
         let child = ["/users/\(name)/contacts/": postDB]
         ref.updateChildValues(child)
         print("added to contacts")
         }
         }
         }
         */
        
        guard let postUser = self.user else {
            print("postuser was nil")
            return
        }
        //get email
        if let currentEmail = Auth.auth().currentUser?.email {
            print("current email is \(currentEmail)")
            //find username associated with the email
            let ref = Database.database().reference()
            ref.child("users").observeSingleEvent(of: .value, with: { snapshot in
                
                let enumerator = snapshot.children
                while let child = enumerator.nextObject() as? DataSnapshot {
                    if let value = child.value as? NSDictionary {
                        if let email = value["email"] as? String {
                            if currentEmail == email {
                                if let username = value["username"] as? String {
                                    if username == postUser.userName {
                                        let alert = UIAlertController(title: "Error", message: "Cannot add yourself as a contact", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                        self.present(alert, animated:true,completion:nil)
                                        return
                                    }
                                    else {
                                        let testRef = Database.database().reference()
                                        testRef.child("users").child(username).child(postUser.userName).observeSingleEvent(of: .value, with: {snapshot in
                                            if snapshot.exists() {
                                                let alert = UIAlertController(title: "Error", message: "Contact already exists", preferredStyle: .alert)
                                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                                self.present(alert, animated:true,completion:nil)
                                            }
                                            else {
                                                let ref = Database.database().reference()
                                                let postDB = [postUser.userName:postUser.userID] as [String:Any]
                                                let child = ["/users/\(username)/contacts/\(postUser.userName)": postDB]
                                                ref.updateChildValues(child)
                                                let alert = UIAlertController(title: "Success", message: "Contact added", preferredStyle: .alert)
                                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                                self.present(alert, animated:true,completion:nil)
                                            }
                                        })
                                    }
                                }
                                
                            }
                        }
                    }
                }
            })
        }
    }
    
}
