#!/usr/bin/env bun
import React, { useState, useEffect } from 'react';
import { render, Box, Text, useApp, useInput, useStdout } from 'ink';
import Spinner from 'ink-spinner';
import TextInput from 'ink-text-input';
import figures from 'figures';
import boxen from 'boxen';
import chalk from 'chalk';

// Components
import WorkerStatus from './components/WorkerStatus.jsx';
import ActionMenu from './components/ActionMenu.jsx';
import CommandBar from './components/CommandBar.jsx';
import Header from './components/Header.jsx';
import WorkerControls from './components/WorkerControls.jsx';
import LogsViewer from './components/LogsViewer.jsx';

// Worker service
import { WorkerService } from './services/WorkerService.js';

// Helper to determine pane layout based on width
const getLayout = (width) => {
    if (width < 100) { // Smaller screens
        return { direction: 'column', statusWidth: '100%', mainWidth: '100%', actionsWidth: '100%' };
    }
    // Larger screens
    return { direction: 'row', statusWidth: '30%', mainWidth: '50%', actionsWidth: '20%' };
};

// Function to check if stdin is available and TTY
const isInteractive = () => {
    try {
        // First check if stdin exists and is a TTY
        if (process.stdin && process.stdin.isTTY) {
            return true;
        }

        // Some environments might have stdin but not properly configured
        // Try to access stdin but catch and ignore errors
        try {
            // Attempt a non-blocking read
            process.stdin.setRawMode(false);
            return true;
        } catch (err) {
            console.error('TTY mode not available:', err.message);
            return false;
        }
    } catch (error) {
        console.error('TTY check error:', error.message);
        return false;
    }
};

const AppPanes = () => {
    const { exit } = useApp();
    const { width } = useStdout(); // Get terminal width
    const layout = getLayout(width); // Determine layout based on width

    const [workers, setWorkers] = useState({
        d1: { name: 'D1 Worker', status: 'stopped', port: 8787, extraArgs: '--local' },
        trade: { name: 'Trade Worker', status: 'stopped', port: 8788, extraArgs: '' },
        webhook: { name: 'Webhook Receiver', status: 'stopped', port: 8789, extraArgs: '' },
        telegram: { name: 'Telegram Worker', status: 'stopped', port: 8790, extraArgs: '' }
    });

    const [selectedTab, setSelectedTab] = useState('workers'); // Default to workers view
    const [selectedWorker, setSelectedWorker] = useState('d1'); // Default selected worker
    const [logs, setLogs] = useState({});
    const [isLoading, setIsLoading] = useState(false);
    const [statusMessage, setStatusMessage] = useState('');
    const [inputAvailable, setInputAvailable] = useState(true);

    const workerService = new WorkerService(setWorkers, setLogs, setStatusMessage);

    // Initialize and check worker status
    useEffect(() => {
        const checkStatus = async () => {
            setIsLoading(true);
            await workerService.checkAllStatus();
            setIsLoading(false);
        };

        // Check if input is available
        setInputAvailable(isInteractive());

        checkStatus();

        // Set up interval to check status periodically
        const interval = setInterval(checkStatus, 5000);

        // Clean up on unmount
        return () => clearInterval(interval);
    }, []);

    // Handle keyboard input - wrap in try/catch
    useInput((input, key) => {
        try {
            // Basic navigation (simplified for panes)
            if (key.tab) {
                // Cycle through workers or other focusable areas
                const workerIds = Object.keys(workers);
                const currentIndex = workerIds.indexOf(selectedWorker);
                const nextIndex = (currentIndex + 1) % workerIds.length;
                setSelectedWorker(workerIds[nextIndex]);
            }

            if (input === 'q' && key.ctrl) {
                handleExit();
            }

            // Actions based on selected worker
            const workerId = selectedWorker;
            if (input === 's') handleStartWorker(workerId);
            if (input === 'k') handleStopWorker(workerId);
            if (input === 'r') handleRestartWorker(workerId);
            if (input === 'l') setSelectedTab('logs'); // Show logs for selected worker

            // Global actions
            if (input === 'S') handleStartAll();
            if (input === 'K') handleStopAll();
            if (input === 'R') handleRestartAll();

        } catch (error) {
            console.error("Input handling error:", error.message);
            setInputAvailable(false);
        }
    });

    const handleStartWorker = async (workerId) => {
        setIsLoading(true);
        await workerService.startWorker(workerId);
        setIsLoading(false);
    };

    const handleStopWorker = async (workerId) => {
        setIsLoading(true);
        await workerService.stopWorker(workerId);
        setIsLoading(false);
    };

    const handleRestartWorker = async (workerId) => {
        setIsLoading(true);
        await workerService.restartWorker(workerId);
        setIsLoading(false);
    };

    const handleStartAll = async () => {
        setIsLoading(true);
        await workerService.startAllWorkers();
        setIsLoading(false);
    };

    const handleStopAll = async () => {
        setIsLoading(true);
        await workerService.stopAllWorkers();
        setIsLoading(false);
    };

    const handleRestartAll = async () => {
        setIsLoading(true);
        await workerService.restartAllWorkers();
        setIsLoading(false);
    };

    const handleViewLogs = (workerId) => {
        setSelectedTab('logs');
        setSelectedWorker(workerId);
    };

    const handleExit = async () => {
        setStatusMessage('Stopping all workers and exiting...');
        await workerService.stopAllWorkers();
        exit();
    };

    const renderMainPane = () => {
        // Always show WorkerControls, or LogsViewer if selectedTab is 'logs'
        if (selectedTab === 'logs' && selectedWorker) {
            return (
                <LogsViewer
                    logs={logs}
                    selectedWorker={selectedWorker}
                    workers={workers}
                    height="100%" // Take full height of pane
                />
            );
        }
        // Default to WorkerControls
        return (
            <WorkerControls
                workers={workers}
                selectedWorker={selectedWorker} // Pass selected worker
                onStart={handleStartWorker}
                onStop={handleStopWorker}
                onRestart={handleRestartWorker}
                onViewLogs={() => setSelectedTab('logs')} // Simple toggle to logs
                height="100%"
            />
        );
    };

    // If input is not available, show a simplified version
    if (!inputAvailable) {
        return (
            <Box flexDirection="column" padding={1}>
                <Box borderStyle="round" borderColor="cyan" padding={1}>
                    <Text color="cyan" bold>Hoox Trading System Status (Read-Only Mode)</Text>
                </Box>
                <Box marginY={1}>
                    <WorkerStatus workers={workers} />
                </Box>
                <Box marginY={1} borderStyle="round" borderColor="yellow" padding={1}>
                    <Text color="yellow">
                        ⚠️  Interactive mode unavailable - run in a proper terminal with:
                        <Text bold>{"\n"}$ ./hoox-tui</Text>
                    </Text>
                </Box>
            </Box>
        );
    }

    return (
        <Box flexDirection={layout.direction} width="100%" height="100%" padding={0}>
            {/* Pane 1: Worker Status - Add internal padding */}
            <Box borderStyle="single" borderColor="blue" width={layout.statusWidth} height="100%" padding={1} flexDirection="column">
                <WorkerStatus workers={workers} selectedWorker={selectedWorker} />
            </Box>

            {/* Pane 2: Main Content (Controls or Logs) - Add internal padding */}
            <Box borderStyle="single" borderColor="green" width={layout.mainWidth} height="100%" padding={1} flexDirection="column">
                {renderMainPane()}
            </Box>

            {/* Pane 3: Actions & Info - Padding already exists */}
            <Box borderStyle="single" borderColor="magenta" width={layout.actionsWidth} height="100%" padding={1} flexDirection="column">
                <Text bold>Actions</Text>
                <Text>---</Text>
                <Text>(s) Start {selectedWorker}</Text>
                <Text>(k) Stop {selectedWorker}</Text>
                <Text>(r) Restart {selectedWorker}</Text>
                <Text>(l) View Logs</Text>
                <Text>---</Text>
                <Text>(S) Start All</Text>
                <Text>(K) Stop All</Text>
                <Text>(R) Restart All</Text>
                <Text>---</Text>
                <Text>(Tab) Cycle Worker</Text>
                <Text>(Ctrl+q) Exit</Text>

                {isLoading && (
                    <Box marginTop={1}>
                        <Text color="yellow"><Spinner type="dots" /> Loading...</Text>
                    </Box>
                )}
                {statusMessage && (
                    <Box marginTop={1}>
                        <Text color="yellow">{statusMessage}</Text>
                    </Box>
                )}
            </Box>
        </Box>
    );
};

// Render the AppPanes component
try {
    render(<AppPanes />);
} catch (error) {
    console.error("Failed to render TUI (Panes):", error);
    // Provide appropriate run command
    console.log("Use './run-tui-panes.sh' to run in interactive mode");
    process.exit(1);
} 