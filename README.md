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
- Persistent storage using JSON
- Simple command-line interface

## Installation

1. Ensure you have Ruby installed on your system
2. Clone this repository:
   ```bash
   git clone [repository-url]
   cd [repository-name]
   ```
3. Run the application:
   ```bash
   ruby task_manager.rb
   ```

## Usage

The following commands are available (with shortcuts):

- `add` or `a <task description>` - Add a new task
- `list` or `l` or `ls` - Show all tasks
- `complete` or `c <task id>` - Mark a task as complete
- `delete` or `d` or `del <task id>` - Remove a task
- `start` or `s <task id>` - Start timing a task
- `stop` or `p <task id>` - Stop timing a task ('p' for pause)
- `help` or `h` or `?` - Display available commands
- `exit` or `q` or `quit` - Close the application

### Example Usage

```bash
Enter command: add Write documentation
New Task added: Write documentation

Enter command: list
Tasks:
1. [ ] Write documentation - Total time: 0h 0m

Enter command: start 1
Started time tracking for task 1

Enter command: stop 1
Stopped time tracking for task 1. Duration: 0h 5m

Enter command: complete 1
Task 1 marked as complete!

Enter command: list
Tasks:
1. [✓] Write documentation - Total time: 0h 5m
```

## Data Storage

Tasks are automatically saved to a `tasks.json` file in the application directory. This ensures your tasks and time tracking data persist between sessions.

## Requirements

- Ruby (version 2.0 or higher)
- JSON gem (included in Ruby standard library)

## License

[Add your chosen license here]
