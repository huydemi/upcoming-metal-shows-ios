//
//  ViewController.swift
//  UpcomingMetalShows
//
//  Created by Sam Agnew on 7/25/16.
//  Copyright © 2016 Sam Agnew. All rights reserved.
//

import UIKit
import Kanna
import Alamofire

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  var shows: [Show] = []
  
  let showConcertInfoSegueIdentifier = "ShowConcertInfoSegue"
  let textCellIdentifier = "ShowCell"
  
  @IBOutlet var metalShowTableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    metalShowTableView.delegate = self
    metalShowTableView.dataSource = self
    scrapeNYCMetalScene()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // Grabs the HTML from nycmetalscene.com for parsing.
  func scrapeNYCMetalScene() -> Void {
    Alamofire.request("http://nycmetalscene.com", method: .get).responseString { response in
      print("Success: \(response.result.isSuccess)")
      if let html = response.result.value {
        self.parseHTML(html)
      }
    }
  }
  
  func parseHTML(_ html: String) -> Void {
    if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
      shows = []
      
      // Search for nodes by CSS selector
      for show in doc.css("td[id^='Text']") {
        
        // Get the link associated with this show.
        let link = show.css("a").first?["href"]
        
        // Strip the string of surrounding whitespace.
        let showString = show.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        
        if showString.count > 2 {
          // All text involving shows on this page currently start with the weekday.
          // Weekday formatting is inconsistent, but the first three letters are always there.
          let regex = try! NSRegularExpression(pattern: "^(mon|tue|wed|thu|fri|sat|sun)", options: [.caseInsensitive])
          
          if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.count)) != nil {
            let showSplit = showString.components(separatedBy: ":")
            let date = showSplit[0]
            
            let venueSplit = showSplit.last!.components(separatedBy: " at ")
            var venue = ""
            
            let trimCharacterSet = NSMutableCharacterSet()
            trimCharacterSet.formUnion(with: NSCharacterSet.whitespacesAndNewlines)
            trimCharacterSet.addCharacters(in: "-")
            
            if venueSplit.count > 1 {
              venue = venueSplit.last!.trimmingCharacters(in: trimCharacterSet as CharacterSet)
            }
            
            let description = venueSplit[0].trimmingCharacters(in: trimCharacterSet as CharacterSet)
            
            if link != nil {
              shows.append(Show(date: date, description: description, venue: venue, link: link!))
            } else {
              shows.append(Show(date: date, description: description, venue: venue, link: ""))
            }
          }
        }
      }
      self.metalShowTableView.reloadData()
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if  segue.identifier == showConcertInfoSegueIdentifier,
      let destination = segue.destination as? ShowWebViewController,
      let showIndex = metalShowTableView.indexPathForSelectedRow?.row {
      
      destination.url = shows[showIndex].link
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // Pass any object as parameter, i.e. the tapped row.
    performSegue(withIdentifier: showConcertInfoSegueIdentifier, sender: indexPath.row)
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return shows.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath)
    
    let row = indexPath.row
    let show = shows[row]
    
    cell.detailTextLabel?.text = show.date + "\n" + show.venue
    cell.textLabel?.text = show.description
    
    return cell
  }
  
}
