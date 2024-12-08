from flask_socketio import SocketIO
from flask import Flask, render_template
import logging
import threading
import importlib
import os

# Initialize Flask app and SocketIO for real-time communication
app = Flask(__name__)
socketio = SocketIO(app)

# Logging configuration
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s]: %(message)s")

# Load agents dynamically
agents = {}
agents_dir = "./agents"
for filename in os.listdir(agents_dir):
    if filename.endswith(".py"):
        module_name = filename[:-3]  # Remove '.py' extension
        module = importlib.import_module(f"agents.{module_name}")
        # Attempt to find the first valid class in the module dynamically
class_name = None
for attr_name in dir(module):
    if attr_name.lower() == module_name.lower():  # Match class to filename (case insensitive)
        class_name = attr_name
        break

if class_name is None:
    raise AttributeError(f"No matching class found in {module_name}")
agent_class = getattr(module, class_name)


# Load modules dynamically
modules = {}
modules_dir = "./modules"
for filename in os.listdir(modules_dir):
    if filename.endswith(".py"):
        module_name = filename[:-3]  # Remove '.py' extension
        module = importlib.import_module(f"modules.{module_name}")
        # Convert module_name to CamelCase dynamically (e.g., quantum_computing -> QuantumComputing)
        class_name = ''.join(word.capitalize() for word in module_name.split('_'))
        module_class = getattr(module, class_name)
        modules[module_name] = module_class()

# Self-healing and optimization daemon
def self_healing_daemon():
    while True:
        for agent in agents.values():
            if hasattr(agent, "self_diagnose"):
                logging.info(agent.self_diagnose())
            if hasattr(agent, "optimize_resources"):
                logging.info(agent.optimize_resources())
            if hasattr(agent, "self_improve"):
                logging.info(agent.self_improve())
        for module in modules.values():
            if hasattr(module, "run_background_tasks"):
                logging.info(module.run_background_tasks())
            if hasattr(module, "self_improve"):
                logging.info(module.self_improve())

# Trigger agent tasks via SocketIO
@socketio.on("trigger_agent")
def trigger_agent(data):
    agent_name = data["agent"]
    task = data["task"]
    if agent_name in agents:
        agent = agents[agent_name]
        if hasattr(agent, "execute_task"):
            result = agent.execute_task(task)
            socketio.emit("status_update", {"agent": agent_name, "result": result})
        else:
            socketio.emit("status_update", {"agent": agent_name, "result": "Task execution not supported"})
    else:
        socketio.emit("status_update", {"agent": agent_name, "result": "Agent not found"})

# Main dashboard route
@app.route("/")
def dashboard():
    return render_template("dashboard.html")

# Run the system
if __name__ == "__main__":
    threading.Thread(target=self_healing_daemon, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=5000)
