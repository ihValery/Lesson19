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
//        let itemToMove = itemArray.remove(at: indexPath.row)
//        itemArray.insert(itemToMove, at: itemArray.count)
//        let destinationindexPath = NSIndexPath(row: 0, section: indexPath.section)
//        tableView.moveRow(at: indexPath, to: destinationindexPath as IndexPath)
//        tableView.reloadData()
        self.saveItems()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
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
        let alert = UIAlertController(title: "Новый элемент", message: nil, preferredStyle: .alert)
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
        alert.addTextField { tf in
            let itemList = ["Яйцо", "Молоко", "Печенька", "Вкусняшка"]
            tf.placeholder = itemList.randomElement()
        }
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    //Core Data сохранение и загрузка
    private func saveItems() {
        do {
            try context.save()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
    
    private func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil)
    {
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Ошибка при получении: \(error)")
        }
        tableView.reloadData()
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
    
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = imageView.bounds
//    blurView.alpha = 1
    imageView.addSubview(blurView)
    
    //Убираем лишнии линии в таблице
    tableView.tableFooterView = UIView()
}

override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
{
    cell.backgroundColor = .clear
//        cell.backgroundColor = UIColor(white: 1, alpha: 0.3)
    }
}

//MARK: -  SearchBar Delegate
extension TodoListTVC: UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        //Делает поисковый регистр и диакритические знаки нечувствительными
        let searchPredicate: NSPredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        loadItems(with: request, predicate: searchPredicate)
        
        if searchBar.text?.count == 0 {
            //Пользователь только что очистил панель поиска, перезагрузите все, поэтому предыдущий поиск исчез.
            loadItems()
            searchBar.resignFirstResponder()
        }
    }
}
