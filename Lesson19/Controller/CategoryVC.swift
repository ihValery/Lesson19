import UIKit
import CoreData

class CategoryViewController: UITableViewController
{
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    
    var categories: [Category] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.title = "Списки"
        loadCategories()
        designBackground()
    }

    // MARK: - TableView Delegate

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCategory", for: indexPath)
        cell.textLabel?.text = categories[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "goToItems", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let destinationVC = segue.destination as? TodoListTVC {
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedCategory = categories[indexPath.row]
            }
        }
    }
    
    //Core Data сохранение и загрузка
    private func saveCategories()
    {
        do {
            try context.save()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
    
    //with request: -> Запрос выборки из базы по ключу Category
    private func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest())
    {
        //Присваем результат выборки константе categories
        do {
            categories = try context.fetch(request)
        } catch {
            print("Ошибка при получении: \(error)")
        }
        tableView.reloadData()
    }
    
/*
    //MARK: -  Перемещение ячеек
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        let moveCell = categories.remove(at: sourceIndexPath.row)
        categories.insert(moveCell, at: destinationIndexPath.row)
        tableView.reloadData()
        self.saveCategories()
    }
*/
    
    func update(at index: Int)
    {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            let tasks = try context.fetch(fetchRequest)
            let deleteCell = tasks[index] as NSManagedObject
            self.categories[index].name = categories[0].name
            
            tableView.reloadData()
//            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)

            
            
            // Сохраняем
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
            
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    //MARK: -  Свайпы
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let edit = editCategory(at: indexPath)
        return UISwipeActionsConfiguration(actions: [edit])
    }

    func editCategory(at indexPath: IndexPath) -> UIContextualAction
    {
        let edit = UIContextualAction(style: .normal, title: "edit") { (action, view, completion) in
            
            let itemToMove = self.categories.remove(at: indexPath.row)
            self.categories.insert(itemToMove, at: 0)
            let destinationindexPath = NSIndexPath(row: 0, section: indexPath.section)
            self.tableView.moveRow(at: indexPath, to: destinationindexPath as IndexPath)
//            self.tableView.reloadRows(at: [indexPath], with: .fade)
            
            self.saveCategories()
            completion(true)
        }
        edit.backgroundColor = .systemGray
        edit.image = UIImage(systemName: "shift.fill")
        return edit
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete {
            
            //Чтобы удалить из core date, нам нужно получить объект, который мы ищем.
            if let category = categories[indexPath.row].name {
                
                let request: NSFetchRequest<Category> = Category.fetchRequest()
                request.predicate = NSPredicate(format: "name MATCHES %@", category)
                // request.predicate = NSPredicate(format: "name==\(category)")
                
                if let results = try? context.fetch(request) {
                    for object in results {
                        context.delete(object)
                    }
                    //Сохраняем контекст, чтобы наши изменения сохранялись, также должны удалить локальную копию данных
                    categories.remove(at: indexPath.row)
                    tableView.reloadData()
                    saveCategories()
                }
            }
        }
    }
    
    //MARK: -  Добавление новой категории
    
    @IBAction func addBarButtonPressed(_ sender: UIBarButtonItem)
    {
        let alert = UIAlertController(title: "Новая категория", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Отмена", style: .cancel) { _ in }
        let action = UIAlertAction(title: "Добавить", style: .default) { _ in
            
            if let tf = alert.textFields?.first {
                if tf.text != "" && tf.text != nil {
                    let newCategory = Category(context: self.context)
                    newCategory.name = tf.text
                    
                    self.categories.append(newCategory)
                    self.tableView.reloadData()
                    self.saveCategories()
                }
            }
        }
        alert.addTextField { tf in
            let list = ["Список покупок", "Список задач"]
            tf.placeholder = list.randomElement()
        }
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    //MARK: - Design
    
    func designBackground()
    {
        navigationController?.navigationBar.barTintColor = UIColor(red: 224 / 255, green: 224 / 255, blue: 224 / 255, alpha: 1)
        
        let backgroundImage = UIImage(named: "backGroundWB")
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = .scaleAspectFill
        tableView.backgroundView = imageView
        
        //Убираем лишнии линии в таблице
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        cell.backgroundColor = .clear
//        cell.backgroundColor = UIColor(white: 1, alpha: 0.3)
    }
}
