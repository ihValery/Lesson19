import UIKit
import CoreData

class TodoListTVC: UITableViewController
{
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var itemArray: [Item] = []
    
    var selectedCategory: Category? {
    //Наблюдатель didSet вызывается после установки нового значения
        didSet {
            loadItems()
            self.title = selectedCategory?.name
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        designBackground()
    }
    
    // MARK: - TableView Delegate
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return itemArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        cell.textLabel?.text = itemArray[indexPath.row].title
        //Задаем тип, что бы по нажатию можно было чекать
        cell.accessoryType = itemArray[indexPath.row].done ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
//        itemArray[indexPath.row] = itemArray[indexPath.last!]
        self.saveItems()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
//    {
//        return true
//    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete {
            
            //Чтобы удалить из core date, нам нужно получить объект, который мы ищем.
            if let categoryName = selectedCategory?.name, let itemName = itemArray[indexPath.row].title {
                
                //Запрос выборки из базы по ключу Item
                let request: NSFetchRequest<Item> = Item.fetchRequest()
                let categoryPredicate: NSPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", categoryName)
                let itemPredicate: NSPredicate = NSPredicate(format: "title MATCHES %@", itemName)
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, itemPredicate])
                
                if let results = try? context.fetch(request) {
                    for object in results {
                        context.delete(object)
                    }
                    //Сохраняем контекст, чтобы наши изменения сохранялись, и также должны удалить локальную копию данных
                    itemArray.remove(at: indexPath.row)
                    saveItems()
                    tableView.reloadData()
                }
            }
        }
    }

    @IBAction func addItemPressed(_ sender: UIBarButtonItem)
    {
        let alert = UIAlertController(title: "Новый элемент", message: "Пожалуйста, добавьте новый элемент", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Отмена", style: .cancel) { _ in }
        let action = UIAlertAction(title: "Добавить", style: .default) { _ in
            if let tf = alert.textFields?.first {
                if tf.text != "" && tf.text != nil {
                    let newItem = Item(context: self.context)
                    newItem.title = tf.text!
                    newItem.done = false
                    newItem.parentCategory = self.selectedCategory
                    
                    self.itemArray.append(newItem)
                    self.tableView.reloadData()
                    self.saveItems()
                }
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Молоко"
        }
        
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    // Marker: Save and load from core data
    //
    private func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context: \(error)")
        }
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// Marker: SearchBar Delegate
//
extension TodoListTVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        // [cd] makes the search case and diacritic insensitive http://nshipster.com/nspredicate/
        //
        let searchPredicate: NSPredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        loadItems(with: request, predicate: searchPredicate)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            // User just cleared the search bar reload everything so their previous search is gone
            //
            loadItems()
            searchBar.resignFirstResponder()
        }
    }
    
    //MARK: - Design
    
    func designBackground()
    {
        navigationController?.navigationBar.barTintColor = UIColor(red: 224 / 255, green: 224 / 255, blue: 224 / 255, alpha: 1)
        
//        clearsSelectionOnViewWillAppear = true

        let backgroundImage = UIImage(named: "backGroundWB")
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = .scaleAspectFill
        tableView.backgroundView = imageView
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = imageView.bounds
        blurView.alpha = 1
        imageView.addSubview(blurView)
        
        //Убираем лишнии линии в таблице
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
//        cell.backgroundColor = UIColor(white: 1, alpha: 0.3)
    }
}
