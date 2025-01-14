#!/usr/bin/env ruby

require 'json'
require 'time'
require 'fileutils'
require 'optparse'

def parse_global_options(args)
  options = { global: false }
  global_index = args.index('--global')
  if global_index
    options[:global] = true
    args.delete_at(global_index)
  end
  [options, args]
end

def parse_report_options(args)
  options = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: task_manager report [options]"
    
    opts.on("-d", "--date DATE", "Show report for specific date (YYYY-MM-DD)") do |date|
      options[:date] = Date.parse(date)
    end
    
    opts.on("-t", "--today", "Show report for today only") do
      options[:date] = Date.today
    end
    
    opts.on("-w", "--week", "Show report for this week") do
      options[:week] = true
    end
  end
  
  parser.parse!(args)
  options
end

def parse_list_options(args)
  options = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: task_manager list [options]"
    
    opts.on("-a", "--active", "Show only active tasks") do
      options[:active_only] = true
    end
    
    opts.on("-c", "--completed", "Show only completed tasks") do
      options[:completed_only] = true
    end
  end
  
  parser.parse!(args)
  options
end

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

  def list_tasks(options = {})
    if @tasks.empty?
      puts "No tasks found."
      return
    end

    filtered_tasks = @tasks
    if options[:active_only]
      filtered_tasks = filtered_tasks.reject { |t| t[:completed] }
    elsif options[:completed_only]
      filtered_tasks = filtered_tasks.select { |t| t[:completed] }
    end

    puts "\nTasks:"
    filtered_tasks.each do |task|
      status = task[:completed] ? "[✓]" : "[ ]"
      total_time = task[:total_time] || 0
      
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

  def generate_report(options = {})
    all_entries = @tasks.flat_map do |task|
      (task[:time_entries] || []).map do |entry|
        {
          task_id: task[:id],
          description: task[:description],
          start: entry[:start],
          end: entry[:end],
          duration: entry[:duration]
        }
      end
    end

    return puts "No time entries found." if all_entries.empty?

    # Filter entries based on options
    all_entries = filter_entries_by_date(all_entries, options)
    return puts "No entries found for the specified time period." if all_entries.empty?

    # Group entries by date
    entries_by_date = all_entries.group_by { |entry| entry[:start].to_date }
    sorted_dates = entries_by_date.keys.sort.reverse

    puts "\nTime Report:"
    puts "------------"

    sorted_dates.each do |date|
      daily_entries = entries_by_date[date]
      total_daily_time = daily_entries.sum { |entry| entry[:duration] }
      
      puts "\n#{date.strftime('%A, %B %d, %Y')}:"
      puts "Total: #{format_duration(total_daily_time)}"
      
      daily_entries.sort_by { |entry| entry[:start] }.each do |entry|
        start_time = entry[:start].strftime("%H:%M")
        end_time = entry[:end].strftime("%H:%M")
        puts "  [#{entry[:task_id]}] #{entry[:description]}"
        puts "      #{start_time} - #{end_time} (#{format_duration(entry[:duration])})"
      end
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

  def filter_entries_by_date(entries, options)
    return entries unless options[:date] || options[:week]

    entries.select do |entry|
      if options[:date]
        entry[:start].to_date == options[:date]
      elsif options[:week]
        entry[:start].to_date.cweek == Date.today.cweek
      end
    end
  end

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
    File.write(@storage_path, JSON.pretty_generate(@tasks))
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
               tasks = JSON.parse(File.read(@storage_path), symbolize_names: true)
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
  puts "  add, a <task description> - Add a new task"
  puts "  list, l, ls [options]     - List all tasks"
  puts "    -a, --active            - Show only active tasks"
  puts "    -c, --completed         - Show only completed tasks"
  puts "  show, v <task id>         - Show detailed task information"
  puts "  complete, c <task id>     - Mark a task as complete"
  puts "  delete, d, del <task id>  - Delete a task"
  puts "  start, s <task id>        - Start time tracking for a task"
  puts "  stop, p <task id>         - Stop time tracking for a task"
  puts "  report, r [options]       - Show time entries grouped by day"
  puts "    -d, --date DATE         - Show report for specific date (YYYY-MM-DD)"
  puts "    -t, --today             - Show report for today only"
  puts "    -w, --week              - Show report for this week"
  puts "  help, h                   - Show this help message"
end

def process_command(args)
  global_options, remaining_args = parse_global_options(args)
  command = remaining_args.shift
  
  task_manager = TaskManager.new(global_options[:global])
  
  case command
  when 'add', 'a'
    if remaining_args.empty?
      puts "Please provide a task description"
    else
      task_manager.add_task(remaining_args.join(' '))
    end
  when 'list', 'l', 'ls'
    options = parse_list_options(remaining_args)
    task_manager.list_tasks(options)
  when 'complete', 'c'
    if remaining_args[0]
      task_manager.complete_task(remaining_args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'delete', 'd', 'del'
    if remaining_args[0]
      task_manager.delete_task(remaining_args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'start', 's'
    if remaining_args[0]
      task_manager.start_time(remaining_args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'stop', 'p'
    if remaining_args[0]
      task_manager.stop_time(remaining_args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'show', 'v'
    if remaining_args[0]
      task_manager.show_task(remaining_args[0].to_i)
    else
      puts "Please provide a task ID"
    end
  when 'report', 'r'
    options = parse_report_options(remaining_args)
    task_manager.generate_report(options)
  when 'help', 'h', '?', nil
    show_usage
  else
    puts "Unknown command. Type 'task_manager help' for usage."
  end
end

if __FILE__ == $PROGRAM_NAME
  process_command(ARGV)
end
