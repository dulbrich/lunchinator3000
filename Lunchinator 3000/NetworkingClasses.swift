//
//  Networking.swift
//  Lunchinator 3000
//
//  Created by David Ulbrich on 7/12/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import Foundation
import Retrolux

let apiEndpoint = "https://interview-project-17987.herokuapp.com/api/"
let imageEndpoint = "https://interview-project-17987.herokuapp.com/images/"

class Restaurants: Reflection {
    var id = 0
    var name = ""
    var waitTimeMinutes: NSNumber?
    var types: [String]?
    var image: String?
    //var description = "" not sure what to do here because description is a used else where...
}

class Reviews: Reflection {
    var id = 0
    var restaurant = ""
    var reviewer = ""
    var rating = ""
    var review = ""
    var reviewerImage = ""
}

class Networking {
    
    func testGetRestaurants() -> Bool {
        var isSorted = false
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
                    let WaitTimeOne = $1.waitTimeMinutes ?? NSNumber(integerLiteral: 0)
                    return waitTimeZero.compare(WaitTimeOne) == .orderedAscending
                }
                for (index, restaurant) in restaurants.enumerated() {
                    let waitTime = restaurant.waitTimeMinutes ?? NSNumber(integerLiteral: 0)
                    print("\(restaurant.name) - Wait Time = \(String(describing: waitTime))")
                    if index+1 < restaurants.count {
                        let waitTimeZero = restaurant.waitTimeMinutes ?? NSNumber(integerLiteral: 0)
                        let WaitTimeOne = restaurants[index+1].waitTimeMinutes ?? NSNumber(integerLiteral: 0)
                        if waitTimeZero.compare(WaitTimeOne) == .orderedAscending || waitTimeZero.compare(WaitTimeOne) == .orderedSame {
                            isSorted = true
                            print("IS SORTED IS NOW TRUE")
                        } else {
                            isSorted = false
                            print("IS SORTED IS NOW FALSE")
                            break
                        }
                    }
                }
            case .failure(let error):
                print("Failed to get restaurants: \(error)")
            }
        }
        sleep(2)
        return isSorted
    }
    
}

