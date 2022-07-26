//
//  MenuController.swift
//  OrderApp
//
//  Created by Joao Gripp on 25/07/22.
//

import Foundation
import UIKit

class MenuController {
    // Singleton
    static let shared = MenuController()
    //share order data
    var order = Order() {
        didSet {
            NotificationCenter.default.post(name: MenuController.orderUpatedNotification, object: nil)
            userActivity.order = order
        }
    }
    
    //Notification for follow change on order
    static let orderUpatedNotification = Notification.Name("MenuController.orderUpdated")
    
    // Save user activity
    var userActivity = NSUserActivity(activityType: "com.CRG.OrderApp.order")
    
    
    let baseURL = URL(string: "http://localhost:8080/")!
    
    func fetchCategories() async throws -> [String] {
        let categoriesURL = baseURL.appendingPathComponent("categories")
        let (data, response) = try await URLSession.shared.data(from: categoriesURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MenuControllerError.categoriesNotFound
        }
        
        let decoder = JSONDecoder()
        let categoriesResponse = try decoder.decode(CategoriesResponse.self, from: data)
        
        return categoriesResponse.categories
    }
    
    func fetchMenuItems(forCategory categoryName: String) async throws -> [MenuItem] {
        let initialMenuURL = baseURL.appendingPathComponent("menu")
        var compoments = URLComponents(url: initialMenuURL, resolvingAgainstBaseURL: true)!
        compoments.queryItems = [URLQueryItem(name: "category", value: categoryName)]
        let menuURL = compoments.url!
        let (data, response) = try await URLSession.shared.data(from: menuURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MenuControllerError.menuItemsNotFound
        }
        
        let decoder = JSONDecoder()
        let menuResponse = try decoder.decode(MenuResponse.self, from: data)
        
        return menuResponse.items
        
    }
    
    func submitOrder(forMenuIDs menuIDs: [Int]) async throws -> MinutesToPrepare {
        let orderURL = baseURL.appendingPathComponent("order")
        var request = URLRequest(url: orderURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let menuIdsDict = ["menuIds": menuIDs]
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(menuIdsDict)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MenuControllerError.orderRequestFailed
        }
        
        let decoder = JSONDecoder()
        let orderResponse = try decoder.decode(OrderResponse.self, from: data)
        
        return orderResponse.prepTime
    }
    
//    MARK: - Fetch Image
    func fetchImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MenuControllerError.imageDataMissing
        }
        
        guard let image = UIImage(data: data) else {
            throw MenuControllerError.imageDataMissing
        }
        
        return image
    }
    
    //MARK: - Update User Activity
    func updateUserActivity(with controller: StateRestorationController) {
        switch controller {
        case .menu(let category):
            userActivity.menuCategory = category
        case .menuItemDetail(let menuItem):
            userActivity.menuItem = menuItem
        case .categories, .order:
            break
        }
        
        userActivity.controllerIdentifier = controller.identifier
    }
}

//MARK: - API Errors
enum MenuControllerError: Error, LocalizedError {
    case categoriesNotFound
    case menuItemsNotFound
    case orderRequestFailed
    case imageDataMissing
}

//MARK: - Type aliases to make code more clear
typealias MinutesToPrepare = Int
