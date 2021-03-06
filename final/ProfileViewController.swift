//
//  ProfileViewController.swift
//  final
//
//  Created by Benjamin Dagg on 10/24/17.
//  Copyright © 2017 Benjamin Dagg. All rights reserved.
//

/*
 Displays the profle info for the passed in User object
 */

/*
 TODO
 1. title of nav bar is messed up not detecting if the profile
 is the current users profile
 2. implement search bar
 3. implement deleting game from list
 4. implement edit profile

 */


import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseAuth
import CoreData
 

//reference to storage on Firebase databse
let storage = Storage.storage()
let storageRef = storage.reference()



class ProfileViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UITabBarControllerDelegate {
    
    
    @IBOutlet weak var favGameLabel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var gameNavBar: UINavigationItem!
    @IBOutlet weak var gamesTableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImg: UIImageView!

    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredGames:[Game] = []
    var profilePermission:ProfilePermission = ProfilePermission.EDIT_AND_VIEW
    
    
    //user object for this users profile
    //passed in from viewcontroller that seegued to this VC
    var targetUser: User?
        
    
    
    override func viewDidLoad() {
        
        self.tabBarController?.delegate = self
        
        if (self.targetUser?.games) != nil {
            
        }
        
        super.viewDidLoad()
        print("user username ===== \(targetUser?.userName ?? "none")")
        
       //set up table view
        self.gamesTableView.delegate = self
        self.gamesTableView.dataSource = self
        
        //set nav bars title depending on whos profile it is
        title = "Profile"
        
        if let user = targetUser {
            self.nameLabel.adjustsFontSizeToFitWidth = true
            self.usernameLabel.adjustsFontSizeToFitWidth = true
            self.nameLabel.text = "Name: \(user.name)"
            self.usernameLabel.text = user.userName
            self.regionLabel.text = "Region: \(user.region.rawValue)"
        }
        
        //add logout button to navigation bar if this is users profile
        if self.profilePermission == .EDIT_AND_VIEW {
            let logoutBtn = UIBarButtonItem(title:  "Logout" as String, style: .plain, target: self, action: #selector(logout))
            self.navigationItem.leftBarButtonItem = logoutBtn
        }
        
        
        
        //hides keyboard when usr click out
        hideKeyboardWhenTappedAround()
        
        //setup search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.barStyle = UIBarStyle.black
        self.gamesTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search Games"
        definesPresentationContext = true
        
        if self.profilePermission == .EDIT_AND_VIEW {
            //add edit btn to nav controller
            let editBtn = UIBarButtonItem(title: "Edit", style: .done, target: self, action:#selector(editProfile))
            editBtn.tintColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)
            self.navigationItem.rightBarButtonItem = editBtn
            
            //add delete button to games nav controller
            let deleteBtn = UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(enableEditing))
            deleteBtn.tintColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)
            self.gameNavBar.leftBarButtonItem = deleteBtn
            
            if let user = self.targetUser {
                if let CDUser = CoreDataHelper.getUser(email: user.email){
                    print("got user from CD")
                    print("core data getUser = \(CDUser.userName)")
                }else{
                    print(")failed to get user from CD")
                }
            }

        }else {
            self.gameNavBar.rightBarButtonItem = nil
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.favGameLabel.isHidden = true
        
        updateUserInfo()
        
        //check for updates on users games
        if let username = self.targetUser?.userName{
            DatabaseHelper.getUserGames(username: username) { result in
                self.targetUser?.games = result
                self.gamesTableView.reloadData()
                
            }
            //get user profile image
            getUserProfileImgifExists()
        }
        
        if self.profilePermission == .EDIT_AND_VIEW {
            //make table view not in edit mode
            self.gamesTableView.isEditing = false
            self.gameNavBar.leftBarButtonItem?.title = "Delete"
            
            if let user = self.targetUser {
                _ = CoreDataHelper.loadUserFromCD(username: user.userName)
            }
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.profilePermission == .EDIT_AND_VIEW {
            //save users info to core data
            if let user = self.targetUser {
                CoreDataHelper.saveUserToCD(user: user)
            }
        }
        
    }
    
    
    
    
    func logout(sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        //if hit cancel button do nothing
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
            //do nothing and close
        }))
        //ok button logs out user then goes back to login screen
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
            
            //logout
            do {
                try Auth.auth().signOut()
                print("user logged out")
                
                //unwind to logout view controller
                self.performSegue(withIdentifier: "logoutUnwind", sender: self)
            } catch {
                let failedAlert = UIAlertController(title: "Logout Failed", message: "Something went wrong trying to logout", preferredStyle: .alert)
                //if hit cancel button do nothing
                failedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
                    //do nothing and close
                }))
                self.present(failedAlert,animated: true,completion: nil)
            }
            
        }))
        //show alert
        present(alert,animated:true,completion:nil)
        
    }
    
    
    
    
    /*
     Called when delete button pressed. Puts game table view in editing mode
    */
    func enableEditing(sender: UIBarButtonItem) {
        if self.gamesTableView.isEditing == true {
            self.gamesTableView.isEditing = false
            self.gameNavBar.leftBarButtonItem?.title = "Delete"
        }else{
            self.gamesTableView.isEditing = true
            self.gameNavBar.leftBarButtonItem?.title = "Done"
        }
    }
    
    
    func getUserProfileImgifExists() {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let user = self.targetUser {
                let ref = Database.database().reference()
                ref.child("users").child(user.userName).observeSingleEvent(of: .value, with: { snapshot in
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
        
    }

    
    func editProfile(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "ShowEditProfileVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //send array of users games to AddGameVC before segue so it can see which games the user already has
        if segue.identifier == "ShowAddGameVC" {
            if let destinationVC = segue.destination as? AddGameViewController {
                if let user = self.targetUser {
                    if let games = user.games {
                        destinationVC.usersGames = games
                        
                        print("sent users games to add VC")
                    }
                    destinationVC.user = user
                }
            }
        }
        if segue.identifier == "ShowGameDetailsSegue" {
            let destination = segue.destination as? EditGameViewController
            //find which row was selected
            guard let index = gamesTableView.indexPathForSelectedRow?.row else{
                return
            }
            //send the info for the selected game depending on if user is filtering or not
            if isFiltering() {
                destination?.title = filteredGames[index].title
                if let user = self.targetUser{
                    destination?.user = user
                }
                destination?.game = filteredGames[index]
            }else{
                destination?.title = self.targetUser?.games?[index].title
                if let user = self.targetUser{
                    destination?.user = user
                }
                destination?.game = self.targetUser?.games?[index]
                
            }
            destination?.profilePermissions = self.profilePermission
        }
        if segue.identifier == "ShowEditProfileVC" {
            if let destination = segue.destination as? EditProfileViewController {
                
                if let user = self.targetUser {
                    destination.user = user
                }
                
            }
            
        }
        
    }
    
    
    func updateUserInfo() {
        
        if let passedUser = self.targetUser {
            let ref = Database.database().reference()
            ref.child("users").child(passedUser.userName).observeSingleEvent(of: .value, with: {snapshot in
                
                if snapshot.exists(){
                    let value = snapshot.value as? NSDictionary
                    if let value = value {
                        if let username = value["username"] as? String {
                            self.targetUser?.userName = username
    
                        }
                        if let favGame = value["favGame"] as? String {
                            DispatchQueue.main.async {
                                self.favGameLabel.adjustsFontSizeToFitWidth = true
                                self.favGameLabel.isHidden = false
                                self.favGameLabel.text = "Favorite Game: \(favGame)"
                            }
                        }
                        if let uid = value["uid"] as? String {
                            self.targetUser?.userID = uid
                        }
                        if let name = value["name"] as? String {
                            self.targetUser?.name = name
                        }
                        if let region = value["region"] as? String{
                            self.targetUser?.region = Region.stringToCase(string: region)
                        }
                        if let email = value["email"] as? String {
                            self.targetUser?.email = email
                        }
                        print("updated values")
                        DispatchQueue.main.async {
                            if let user = self.targetUser {
                                self.regionLabel.adjustsFontSizeToFitWidth = true
                                self.regionLabel.text = "Region: \(user.region.rawValue)"
                                
                            }
                        }

                    }
                }
            })
            
        }
    }
    
    //==================== Table View Funcs ====================
    //required method for tableview tells number of sections
    //in the tabble
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    //required method for table view tells the number of rows
    //to display
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //check if user has any games
        if let games = self.targetUser?.games {
            //if user is searching use the filtered games array
            if isFiltering(){
                return self.filteredGames.count
            }
            //if not filtering then use the regular games aray
            else{
                return games.count
            }
        }
        //if users games are nil return 0
        else{
            return 0
        }
    }
    
    
    
    
    //required tableview method. Tells table view which
    //cell to draw
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //m custom cell ID
        let cellIdentifier = "GameCell"
        
        //get a cell from the queue
        //and cast it as my cutsom cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GameTableViewCell else{
            fatalError("dequeue cell not instance of CrimeCell")
        }
        
        //crime objy.nect to display the crime info for this cell
        let game:Game
        
        if isFiltering(){
            game = filteredGames[indexPath.row]
        }
        else{
            game = (self.targetUser?.games?[indexPath.row])!
        }
        
        cell.gameTitleLabel.adjustsFontSizeToFitWidth = true
        
        switch game.platform{
        case .PC:
            cell.gamePlatformImg.image = UIImage(named: "steamlogo")
        case .PS3:
            cell.gamePlatformImg.image = UIImage(named: "ps3logo")
        case .PS4:
            cell.gamePlatformImg.image = UIImage(named: "ps4logo")
        case .Xbox360:
            cell.gamePlatformImg.image = UIImage(named: "xbox360logo")
        case .XboxOne:
            cell.gamePlatformImg.image = UIImage(named: "xboxonelogo")
        //default: break
            
        }
        
        cell.gameImgLabel.image = game.icon
        cell.gameTitleLabel.text = game.title
        cell.gameTitleLabel.sizeToFit()

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "ShowGameDetailsSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if let user = self.targetUser {
                if let games = user.games {
                    if games.count > 0 && games.count >= indexPath.row {
                        
                        if isFiltering() == false {
                            let gameTitle = games[indexPath.row].title
                            let ref = Database.database().reference()
                            ref.child("users").child(user.userName).child("games").child(gameTitle).setValue(nil)
                        
                            self.targetUser?.games?.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                        else {
                            if self.filteredGames.count >= indexPath.row {
                                let ref = Database.database().reference()
                                let gameTitle = self.filteredGames[indexPath.row].title
                                
                                ref.child("users").child(user.userName).child("games").child(gameTitle).setValue(nil)
                                self.filteredGames.remove(at: indexPath.row)
                                for i in 0..<games.count {
                                    if games[i].title == gameTitle {
                                        self.targetUser?.games?.remove(at: i)
                                    }
                                }
                                tableView.deleteRows(at: [indexPath], with: .fade)
                            }
                        }
                        
                    }
                }
            }
            
            
        }
        else if editingStyle == .insert {
            
        }
    }
    //==========================================================
    
    /*
    Lets views in other view controllers unwind back to this VC
    */
    @IBAction func unwindToProfileVC(segue: UIStoryboardSegue){
        
    }
    
    /* ================= SearchBar stuff =======================*/
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }

    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        
        if let games = self.targetUser?.games {
            filteredGames = games.filter({(game: Game) -> Bool in
                return game.title.lowercased().contains(searchText.lowercased())
            })
        }
        self.gamesTableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    
    
    //when tab bar item is selected, transfer the user to that controller
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        UserTransfer.sharedInstance.currentUser = self.targetUser
    }
    
    
    
}
extension String {
    func convertHTMLSymbol() throws -> String? {
        guard let data = data(using: .utf8) else {return nil}
        return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:String.Encoding.utf8.rawValue], documentAttributes: nil).string
    }
}
