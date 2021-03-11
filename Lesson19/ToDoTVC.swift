import UIKit
import CoreData

class ToDoTVC: UITableViewController
{
    var tasks: [Task] = []
    
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
                //добовляем не в конец списка, а в начало так лучше
               // self.tasks.insert(newTask, at: 0)
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
    
    private func saveTask(withTitle title: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //Добираем до нашей сущьности. Описание сущности
        guard let entity = NSEntityDescription.entity(forEntityName: "Task", in: context) else { return }
        let taskObject = Task(entity: entity, insertInto: context)
        taskObject.title = title
        
        do {
            try context.save()
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
