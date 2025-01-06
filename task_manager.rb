# Create a TaskManager class to handle core functionality
class TaskManager
  def initialize
    @tasks = []
    load_tasks
  end

  def add_task(description)
    task = { id: next_id, description: description, completed: false }
    @tasks << task
    save_tasks
    puts "Task added: #{description}"
  end

  def list_tasks
    if @tasks.empty?
      puts "No tasks found."
      return
    end

    puts "\nTasks:"
    @tasks.each do |task|
      status = task[:completed] ? "[✓]" : "[ ]"
      puts "#{task[:id]}. #{status} #{task[:description]}"
    end
  end

  def complete_task(id)
    task = @tasks.find { |t| t[:id] == id }
    if task
      task[:completed] = true
      save_tasks
      puts "Task #{id} marked as complete!"
    else
      puts "Task not found."
    end
  end

  def delete_task(id)
    if @tasks.reject! { |t| t[:id] == id }
      save_tasks
      puts "Task #{id} deleted!"
    else
      puts "Task not found."
    end
  end

  private

  def next_id
    (@tasks.map { |t| t[:id] }.max || 0) + 1
  end

  def save_tasks
    File.write('tasks.json', JSON.generate(@tasks))
  end

  def load_tasks
    @tasks = if File.exist?('tasks.json')
               JSON.parse(File.read('tasks.json'), symbolize_names: true)
             else
               []
             end
  end
end

# CLI interface
require 'json'

def show_usage
  puts "\nUsage:"
  puts "  add <task description> - Add a new task"
  puts "  list                   - List all tasks"
  puts "  complete <task id>     - Mark a task as complete"
  puts "  delete <task id>       - Delete a task"
  puts "  help                   - Show this help message"
  puts "  exit                   - Exit the program"
end

task_manager = TaskManager.new

puts "Welcome to Task Manager! Type 'help' for commands."

loop do
  print "\nEnter command: "
  input = gets.chomp
  command, *args = input.split(' ')

  case command
  when 'add'
    if args.empty?
      puts "Please provide a task description"
    else
      task_manager.add_task(args.join(' '))
    end
  when 'list'
    task_manager.list_tasks
  when 'complete'
    if args[0]
      task_manager.complete_task(args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'delete'
    if args[0]
      task_manager.delete_task(args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'help'
    show_usage
  when 'exit'
    puts "Goodbye!"
    break
  else
    puts "Unknown command. Type 'help' for usage."
  end
end
