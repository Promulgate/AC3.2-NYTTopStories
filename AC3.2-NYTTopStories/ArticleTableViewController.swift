//
//  ArticleTableViewController.swift
//  AC3.2-NYTTopStories
//
//  Created by Jason Gresh on 11/19/16.
//  Copyright © 2016 C4Q. All rights reserved.
//

import UIKit

class ArticleTableViewController: UITableViewController, UITextFieldDelegate {
    var allArticles = [Article]()
    var articles = [Article]()
    var sectionDict = [String:Int]()
    
    let identifier = "articleCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Home"
        
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension

        APIRequestManager.manager.getData(endPoint: "https://api.nytimes.com/svc/topstories/v2/home.json?api-key=f41c1b23419a4f55b613d0a243ed3243")  { (data: Data?) in
            if let validData = data {
                if let jsonData = try? JSONSerialization.jsonObject(with: validData, options:[]) {
                    if let wholeDict = jsonData as? [String:Any],
                        let records = wholeDict["results"] as? [[String:Any]] {
                        self.allArticles = Article.parseArticles(from: records)
                        
                        // start off with everything
                        self.articles = self.allArticles
                        self.updateSectionDictionary()

                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionDict.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let key = self.sectionDict.keys.sorted()[section]
        return self.sectionDict[key] ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier, for: indexPath) as! ArticleTableViewCell
        
        let key = self.sectionDict.keys.sorted()[indexPath.section]
        let predicate = NSPredicate(format: "section = %@", key)
        let article = self.articles.filter { predicate.evaluate(with: $0) }[indexPath.row]
        
        //let article = articles[indexPath.row]
        
        cell.titleLabel.text = article.title
        cell.abstractLabel.text = article.abstract + "PER: " + article.per_facet.joined(separator: " ")
        cell.bylineAndDateLabel.text = "\(article.byline)\n\(article.published_date)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let key = self.sectionDict.keys.sorted()[section]
        return key
    }
    
    func applyPredicate(search: String) {
        //let predicate = NSPredicate(format:"abstract contains[c] %@ or title contains[c] %@", search, search)
        let predicate = NSPredicate(format:"ANY per_facet contains[c] %@", search) // Trump, Donald J
        
        self.articles = self.allArticles.filter { predicate.evaluate(with: $0) }
        updateSectionDictionary()
        self.tableView.reloadData()
    }
    
    func updateSectionDictionary() {
        self.sectionDict.removeAll()
        for article in self.articles {
            self.sectionDict[article.section] = (self.sectionDict[article.section] ?? 0) + 1
        }
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if text.characters.count > 0 {
                applyPredicate(search: text)
            }
            else {
                self.articles = self.allArticles
                updateSectionDictionary()
                self.tableView.reloadData()
            }
        }
        return true
    }
}
