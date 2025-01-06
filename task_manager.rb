# Create a TaskManager class to handle core functionality
class TaskManager
  def initialize
    @tasks = []
    load_tasks
  end

  def add_task(description)
    task = {
      id: next_id,
      description: description,
      completed: false,
      time_entries: [],  # Array to store multiple time entries
      total_time: 0      # Total time spent in seconds
    }
    @tasks << task
    save_tasks
    puts "Task added: [#{task[:id]}] #{description}"
  end

  def list_tasks
    if @tasks.empty?
      puts "No tasks found."
      return
    end

    puts "\nTasks:"
    @tasks.each do |task|
      status = task[:completed] ? "[✓]" : "[ ]"
      time_status = task[:current_entry] ? "[🕒 Tracking]" : ""
      total_time = format_duration(task[:total_time] || 0)
      puts "#{task[:id]}. #{status} #{task[:description]} - Total time: #{total_time} #{time_status}"
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

  def start_time(id)
    task = @tasks.find { |t| t[:id] == id }
    if task
      if task[:current_entry]
        puts "Time tracking already started for this task!"
      else
        task[:current_entry] = Time.now
        save_tasks
        puts "Started time tracking for task #{id}"
      end
    else
      puts "Task not found."
    end
  end

  def stop_time(id)
    task = @tasks.find { |t| t[:id] == id }
    if task
      if task[:current_entry]
        end_time = Time.now
        duration = end_time - task[:current_entry]
        task[:time_entries] ||= []
        task[:time_entries] << {
          start: task[:current_entry],
          end: end_time,
          duration: duration
        }
        task[:total_time] = (task[:total_time] || 0) + duration
        task.delete(:current_entry)
        save_tasks
        puts "Stopped time tracking for task #{id}. Duration: #{format_duration(duration)}"
      else
        puts "Time tracking not started for this task!"
      end
    else
      puts "Task not found."
    end
  end

  private

  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours.to_i}h #{minutes.to_i}m"
  end

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
  puts "  add, a <task description>  - Add a new task"
  puts "  list, l, ls               - List all tasks"
  puts "  complete, c <task id>     - Mark a task as complete"
  puts "  delete, d, del <task id>  - Delete a task"
  puts "  start, s <task id>        - Start time tracking for a task"
  puts "  stop, p <task id>         - Stop time tracking for a task"
  puts "  help, h, ?               - Show this help message"
  puts "  exit, q, quit            - Exit the program"
end

task_manager = TaskManager.new

puts "Welcome to Task Manager! Type 'help' for commands."

loop do
  print "\nEnter command: "
  input = gets.chomp
  command, *args = input.split(' ')

  case command
  when 'add', 'a'
    if args.empty?
      puts "Please provide a task description"
    else
      task_manager.add_task(args.join(' '))
    end
  when 'list', 'l', 'ls'
    task_manager.list_tasks
  when 'complete', 'c'
    if args[0]
      task_manager.complete_task(args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'delete', 'd', 'del'
    if args[0]
      task_manager.delete_task(args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'start', 's'
    if args[0]
      task_manager.start_time(args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'stop', 'p'  # 'p' for pause
    if args[0]
      task_manager.stop_time(args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'help', 'h', '?'
    show_usage
  when 'exit', 'q', 'quit'
    puts "Goodbye!"
    break
  else
    puts "Unknown command. Type 'help' for usage."
  end
end
