# Ruby Task Manager with Time Tracking

A command-line task management application built in Ruby that helps you manage tasks and track time spent on each task.

## Features

- Create and manage tasks
- Mark tasks as complete
- Delete tasks
- Track time spent on tasks
  - Start/stop time tracking
  - Multiple time entries per task
  - Total time tracking
  - Visual indicator for active timing
- Flexible storage options
  - Local tasks per project/directory
  - Global tasks accessible from anywhere
- Persistent storage using JSON
- Simple command-line interface

## Installation

1. Ensure you have Ruby installed on your system
2. Clone this repository:
   ```bash
   git clone [repository-url]
   cd [repository-name]
   ```
3. Make the script executable:
   ```bash
   chmod +x task_manager.rb
   ```
4. Create a symbolic link to make it available system-wide:
   ```bash
   sudo ln -s "$(pwd)/task_manager.rb" /usr/local/bin/task_manager
   ```

Now you can use the `task_manager` command from anywhere in your terminal!

## Usage

The following commands are available:

- `task_manager add "task description"` - Add a new task
- `task_manager list` - Show all tasks
- `task_manager show <task id>` - Show detailed task information
- `task_manager complete <task id>` - Mark a task as complete
- `task_manager delete <task id>` - Remove a task
- `task_manager start <task id>` - Start timing a task
- `task_manager stop <task id>` - Stop timing a task
- `task_manager help` - Display available commands

### Local vs Global Tasks

The task manager supports two storage modes:

1. **Local Tasks** (default)
   - Stored in `tasks.json` in the current directory
   - Perfect for project-specific tasks
   - Can be committed to version control
   - Different task lists for different projects

2. **Global Tasks**
   - Stored in `~/.task_manager/tasks.json`
   - Accessible from any directory
   - Perfect for personal tasks
   - Single task list across all locations

Use the `--global` flag with any command to access global tasks:

```bash
# Local task examples
task_manager add "Project specific task"
task_manager list

# Global task examples
task_manager --global add "Call dentist"
task_manager --global list
```

### Example Usage

```bash
$ task_manager add "Write documentation"
New Task added: Write documentation

$ task_manager list
Tasks:
1. [ ] Write documentation - Total time: 0h 0m

$ task_manager start 1
Started time tracking for task 1

$ task_manager stop 1
Stopped time tracking for task 1. Duration: 0h 5m

$ task_manager show 1
Task 1: [ ] Write documentation

Total time: 0h 5m

Time entries:
1. 2023-05-20 14:30 to 2023-05-20 14:35 (0h 5m)

$ task_manager complete 1
Task 1 marked as complete!

$ task_manager list
Tasks:
1. [✓] Write documentation - Total time: 0h 5m
```

## Data Storage

Tasks are automatically saved to one of two locations:

- Local tasks: `tasks.json` in the current directory
- Global tasks: `~/.task_manager/tasks.json` in your home directory

The storage location is determined by the presence of the `--global` flag when running commands.
Local storage is perfect for project-specific tasks that you might want to commit to version control,
while global storage is ideal for personal tasks that you want to access from anywhere.

## Requirements

- Ruby (version 2.0 or higher)
- JSON gem (included in Ruby standard library)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
