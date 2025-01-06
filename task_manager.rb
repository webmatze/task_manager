#!/usr/bin/env ruby

require 'json'
require 'time'
require 'fileutils'

# Create a TaskManager class to handle core functionality
class TaskManager
  def initialize(use_global_storage = false)
    @tasks = []
    @storage_path = determine_storage_path(use_global_storage)
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
      total_time = task[:total_time] || 0
      
      # Calculate current session time if task is being tracked
      if task[:current_entry]
        current_session_time = Time.now - task[:current_entry]
        current_time_str = " + #{format_duration(current_session_time)}"
        time_status = "[🕒 Active]"
      else
        current_time_str = ""
        time_status = ""
      end

      puts "#{task[:id]}. #{status} #{task[:description]} - Total time: #{format_duration(total_time)}#{current_time_str} #{time_status}"
    end
  end

  def complete_task(id)
    task = @tasks.find { |t| t[:id] == id }
    if task
      # Stop timing if task is currently being tracked
      stop_time(id) if task[:current_entry]
      
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

  def show_task(id)
    task = @tasks.find { |t| t[:id] == id }
    if task
      status = task[:completed] ? "[✓]" : "[ ]"
      puts "\nTask #{task[:id]}: #{status} #{task[:description]}"
      
      if task[:current_entry]
        current_session_time = Time.now - task[:current_entry]
        puts "Currently tracking: #{format_duration(current_session_time)} [🕒 Active]"
      end
      
      puts "\nTotal time: #{format_duration(task[:total_time] || 0)}"
      
      if task[:time_entries]&.any?
        puts "\nTime entries:"
        task[:time_entries].each_with_index do |entry, index|
          duration = format_duration(entry[:duration])
          start_time = entry[:start].strftime("%Y-%m-%d %H:%M")
          end_time = entry[:end].strftime("%Y-%m-%d %H:%M")
          puts "#{index + 1}. #{start_time} to #{end_time} (#{duration})"
        end
      else
        puts "\nNo time entries recorded."
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
    FileUtils.mkdir_p(File.dirname(@storage_path)) unless File.directory?(File.dirname(@storage_path))
    File.write(@storage_path, JSON.generate(@tasks))
  end

  def determine_storage_path(use_global_storage)
    if use_global_storage
      File.join(Dir.home, '.task_manager', 'tasks.json')
    else
      'tasks.json'
    end
  end

  def load_tasks
    @tasks = if File.exist?(@storage_path)
               tasks = JSON.parse(File.read('tasks.json'), symbolize_names: true)
               tasks.map do |task|
                 # Convert current_entry back to Time object if it exists
                 task[:current_entry] = Time.parse(task[:current_entry]) if task[:current_entry]
                 
                 # Convert time entries timestamps back to Time objects
                 if task[:time_entries]
                   task[:time_entries].map! do |entry|
                     entry[:start] = Time.parse(entry[:start])
                     entry[:end] = Time.parse(entry[:end])
                     entry
                   end
                 end
                 task
               end
             else
               []
             end
  end
end

# CLI interface

def show_usage
  puts "\nUsage: task_manager [--global] <command> [arguments]"
  puts "\nOptions:"
  puts "  --global                  - Use global tasks file (~/.task_manager/tasks.json)"
  puts "\nCommands:"
  puts "  add, a <task description>  - Add a new task"
  puts "  list, l, ls               - List all tasks"
  puts "  show, v <task id>         - Show detailed task information"
  puts "  complete, c <task id>     - Mark a task as complete"
  puts "  delete, d, del <task id>  - Delete a task"
  puts "  start, s <task id>        - Start time tracking for a task"
  puts "  stop, p <task id>         - Stop time tracking for a task"
  puts "  help, h                   - Show this help message"
end

def process_command(args)
  # Extract global flag if present
  global_flag_index = args.index('--global')
  use_global_storage = false
  
  if global_flag_index
    use_global_storage = true
    args.delete_at(global_flag_index)
  end

  task_manager = TaskManager.new(use_global_storage)
  
  command = args[0]
  rest = args[1..]

  case command
  when 'add', 'a'
    if rest.empty?
      puts "Please provide a task description"
    else
      task_manager.add_task(rest.join(' '))
    end
  when 'list', 'l', 'ls'
    task_manager.list_tasks
  when 'complete', 'c'
    if rest[0]
      task_manager.complete_task(rest[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'delete', 'd', 'del'
    if rest[0]
      task_manager.delete_task(rest[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'start', 's'
    if rest[0]
      task_manager.start_time(rest[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'stop', 'p'
    if rest[0]
      task_manager.stop_time(rest[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'show', 'v'
    if rest[0]
      task_manager.show_task(rest[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'help', 'h', '?', nil
    show_usage
  else
    puts "Unknown command. Type 'task_manager help' for usage."
  end
end

if __FILE__ == $PROGRAM_NAME
  process_command(ARGV)
end
