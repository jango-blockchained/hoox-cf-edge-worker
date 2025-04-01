import blessed from 'blessed';
import { WorkerService } from './services/WorkerService.js'; // Assuming WorkerService can be used

// --- Blessed TUI Setup ---
const screen = blessed.screen({
    smartCSR: true,
    title: 'Hoox Worker TUI (Blessed)',
    fullUnicode: true // Important for box drawing characters
});

// --- Worker State ---
let workers = {
    d1: { name: 'D1 Worker', status: 'stopped', port: 8787, extraArgs: '--local' },
    trade: { name: 'Trade Worker', status: 'stopped', port: 8788, extraArgs: '' },
    webhook: { name: 'Webhook Receiver', status: 'stopped', port: 8789, extraArgs: '' },
    telegram: { name: 'Telegram Worker', status: 'stopped', port: 8790, extraArgs: '' }
};
let selectedWorkerId = 'd1';
let logs = {}; // Store logs { workerId: [log lines] }
let statusMessage = '';

// --- Service Initialization ---
// Dummy state setters for WorkerService compatibility (blessed updates manually)
const setWorkersState = (newWorkers) => { workers = newWorkers; updateStatusList(); };
const setLogsState = (newLogs) => { logs = newLogs; updateLogView(); };
const setStatusMessageState = (msg) => { statusMessage = msg; updateStatusBar(); };

const workerService = new WorkerService(setWorkersState, setLogsState, setStatusMessageState);

// --- UI Elements ---

// Status Pane (Left)
const statusPane = blessed.box({
    parent: screen,
    top: 0,
    left: 0,
    width: '30%',
    height: '100%',
    label: ' Worker Status ',
    border: { type: 'line' },
    style: { border: { fg: 'blue' } }
});

const statusList = blessed.list({
    parent: statusPane,
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    padding: 1,
    keys: true,
    vi: true,
    mouse: true,
    tags: true,
    style: {
        selected: { bg: 'gray' },
        item: { fg: 'white' }
    }
});

// Controls/Logs Pane (Middle)
const mainPane = blessed.box({
    parent: screen,
    top: 0,
    left: '30%',
    width: '50%',
    height: '100%',
    label: ' Controls / Logs ',
    border: { type: 'line' },
    style: { border: { fg: 'green' } }
});

const controlBox = blessed.box({
    parent: mainPane,
    top: 0,
    left: 0,
    right: 0,
    height: '20%', // Allocate space for controls
    padding: 1,
    content: 'Controls will appear here.',
    tags: true
});

const logView = blessed.log({
    parent: mainPane,
    top: '20%', // Position below controls
    left: 0,
    right: 0,
    bottom: 0,
    padding: 1,
    scrollable: true,
    alwaysScroll: true,
    scrollbar: { ch: ' ', track: { bg: 'cyan' }, style: { inverse: true } },
    label: ' Logs ',
    border: { type: 'line' },
    keys: true,
    vi: true,
    mouse: true
});

// Actions Pane (Right)
const actionsPane = blessed.box({
    parent: screen,
    top: 0,
    left: '80%',
    width: '20%',
    height: '100%-1', // Leave space for status bar
    label: ' Actions ',
    padding: 1,
    border: { type: 'line' },
    style: { border: { fg: 'magenta' } }
});

const actionsText = blessed.text({
    parent: actionsPane,
    content: 'Loading actions...',
    top: 0, left: 0, right: 0, bottom: 0,
    tags: true
});

// Status Bar (Bottom)
const statusBar = blessed.box({
    parent: screen,
    bottom: 0,
    left: 0,
    width: '100%',
    height: 1,
    style: { bg: 'gray' }
});

const statusText = blessed.text({
    parent: statusBar,
    content: ' Status: Ready | Ctrl+q: Exit',
    tags: true,
    style: { fg: 'white' }
});

// --- UI Update Functions ---

function getStatusDisplayBlessed(status) {
    switch (status) {
        case 'running': return '{green-fg}✔ Running{/}';
        case 'starting': return '{yellow-fg}→ Starting{/}';
        case 'stopping': return '{yellow-fg}← Stopping{/}';
        case 'error': return '{red-fg}✖ Error{/}';
        case 'stopped': default: return '{gray-fg}○ Stopped{/}';
    }
}

function updateStatusList() {
    const items = Object.entries(workers).map(([id, worker], index) => {
        const statusStr = getStatusDisplayBlessed(worker.status);
        // Pad name for alignment
        const name = worker.name.padEnd(20, ' ');
        return `${name} ${statusStr.padEnd(25)} Port: ${worker.port}`;
    });
    statusList.setItems(items);
    // Select the current worker
    const selectedIndex = Object.keys(workers).indexOf(selectedWorkerId);
    if (selectedIndex !== -1) {
        statusList.select(selectedIndex);
    }
    screen.render();
}

function updateControlBox() {
    const worker = workers[selectedWorkerId];
    if (!worker) return;
    const isRunning = worker.status === 'running';
    const isBusy = worker.status === 'starting' || worker.status === 'stopping';

    let content = `{bold}Controls for: ${worker.name}{/}\n`;
    content += `Port: ${worker.port} | Status: ${getStatusDisplayBlessed(worker.status)}\n\n`;
    content += `[s] {${isRunning || isBusy ? 'gray-fg' : 'green-fg'}}Start{/}   `;
    content += `[k] {${!isRunning || isBusy ? 'gray-fg' : 'red-fg'}}Stop{/}    `;
    content += `[r] {${!isRunning || isBusy ? 'gray-fg' : 'yellow-fg'}}Restart{/} `;
    content += `[l] {cyan-fg}Logs{/}`; // Logs always available

    controlBox.setContent(content);
    screen.render();
}

function updateLogView() {
    logView.setLabel(` Logs: ${selectedWorkerId} `);
    const workerLogs = logs[selectedWorkerId] || ['No logs yet.'];
    // Blessed log expects lines, clear first
    logView.setContent('');
    workerLogs.forEach(line => logView.log(line));
    logView.setScrollPerc(100); // Scroll to bottom
    screen.render();
}

function updateActionsPane() {
    let content = '{bold}Actions{/}\n---\n';
    content += `(s) Start ${selectedWorkerId}\n`;
    content += `(k) Stop ${selectedWorkerId}\n`;
    content += `(r) Restart ${selectedWorkerId}\n`;
    content += `(l) View Logs\n---\n`;
    content += `(S) Start All\n`;
    content += `(K) Stop All\n`;
    content += `(R) Restart All\n---\n`;
    content += `(↑/↓) Select Worker\n`;
    content += `(Ctrl+q) Exit`;
    actionsText.setContent(content);
    screen.render();
}

function updateStatusBar() {
    statusText.setContent(` Status: ${statusMessage || 'Ready'} | Ctrl+q: Exit`);
    screen.render();
}

// --- Event Handling ---

screen.key(['C-q', 'q'], () => {
    workerService.stopAllWorkers().then(() => process.exit(0));
});

statusList.on('select item', (item, index) => {
    selectedWorkerId = Object.keys(workers)[index];
    updateControlBox();
    updateLogView();
    updateActionsPane();
});

// Basic key handling for actions
screen.key('s', () => { if (selectedWorkerId) workerService.startWorker(selectedWorkerId); });
screen.key('k', () => { if (selectedWorkerId) workerService.stopWorker(selectedWorkerId); });
screen.key('r', () => { if (selectedWorkerId) workerService.restartWorker(selectedWorkerId); });
screen.key('l', () => { updateLogView(); mainPane.focus(); }); // Switch focus to logs
screen.key('S', () => workerService.startAllWorkers());
screen.key('K', () => workerService.stopAllWorkers());
screen.key('R', () => workerService.restartAllWorkers());

// Initial focus
statusList.focus();

// --- Initial Render & Status Check ---

function initializeUI() {
    updateStatusList();
    updateControlBox();
    updateLogView();
    updateActionsPane();
    updateStatusBar();
    screen.render();

    // Initial status check
    workerService.checkAllStatus();

    // Periodic status check
    setInterval(() => workerService.checkAllStatus(), 5000);
}

initializeUI(); 