import UIKit
import CoreData

class ToDoTVC: UITableViewController
{
    var tasks: [Task] = []
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let context = getContext()
        //Создаем запрос по которому можем получиться все объекты
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            tasks = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    @IBAction func addListAction(_ sender: Any)
    {
        let alertController = UIAlertController(title: "New task", message: "Please add a new task", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            let tf = alertController.textFields?.first
            
            if let newTaskTitle = tf?.text {
                self.saveTask(withTitle: newTaskTitle)
                self.tableView.reloadData()
            }
        }
        alertController.addTextField { _ in }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func deleteAllTasks(_ sender: Any)
    {
        let context = getContext()
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        if let objects = try? context.fetch(fetchRequest) {
            for i in objects {
                context.delete(i)
            }
        }
        
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        tableView.reloadData()
    }
    
    private func getContext() -> NSManagedObjectContext
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    private func saveTask(withTitle title: String)
    {
        let context = getContext()
        //Добираем до нашей сущьности. Описание сущности
        guard let entity = NSEntityDescription.entity(forEntityName: "Task", in: context) else { return }
        let taskObject = Task(entity: entity, insertInto: context)
        taskObject.title = title
        
        do {
            try context.save()
            //Добавляем в массив и сразу видем отображение нового списка
            //добовляем не в конец списка, а в начало - так лучше
            tasks.insert(taskObject, at: 0)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.title
        return cell
    }
}
