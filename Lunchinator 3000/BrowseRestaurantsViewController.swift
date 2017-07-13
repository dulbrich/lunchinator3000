//
//  BrowseRestaurants.swift
//  Lunchinator 3000
//
//  Created by David Ulbrich on 7/11/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import UIKit
import Retrolux

class BrowseRestaurants: UITableViewController {
    
    var listedRestaurants: [Restaurants]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Browse Restaurants"
        self.navigationItem.backBarButtonItem?.title = ""
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.getRestaurants()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = self.listedRestaurants?.count else {
            return 0 // should return zero if no restaurants are shown.
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        guard let r = listedRestaurants else {
            fatalError("No restaurants")
        }
        let restaurantName = r[indexPath.row].name
        let waitTimeMinutes = r[indexPath.row].waitTimeMinutes ?? NSNumber(integerLiteral: 0)
        cell.textLabel?.text = "\(String(describing: restaurantName)) - \(waitTimeMinutes)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "viewRestaurant", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        if let indexPath = tableView.indexPathForSelectedRow{
            let selectedRow = indexPath.row
            currentRestaurantName = self.listedRestaurants?[selectedRow].name ?? "Unknown"
            currentRestaurantWaitTime = self.listedRestaurants?[selectedRow].waitTimeMinutes ?? NSNumber(integerLiteral: 0)
            currentRestaurantImage = self.listedRestaurants?[selectedRow].image ?? "Arbys.jpeg"
        }
    }
    
    //Retrolux networking implementation.
    func getRestaurants() {
        let builder = Builder(base: URL(string: apiEndpoint)!)
        let getRestaurants = builder.makeRequest(
            method: .get,
            endpoint: "restaurants",
            args: (),
            response: [Restaurants].self)
        getRestaurants().enqueue { response in
            switch response.interpreted {
            case .success(var restaurants):
                print("Got \(restaurants.count) restaurants!")
                restaurants.sort {
                    let waitTimeZero = $0.waitTimeMinutes ?? NSNumber(integerLiteral: 0)
                    let waitTimeOne = $1.waitTimeMinutes ?? NSNumber(integerLiteral: 0)
                    return waitTimeZero.compare(waitTimeOne) == .orderedAscending
                }
                self.listedRestaurants = restaurants
                self.tableView.reloadData()
            case .failure(let error):
                print("Failed to get restaurants: \(error)")
            }
        }
    }
}
