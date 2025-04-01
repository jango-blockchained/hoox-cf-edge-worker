#!/usr/bin/env bun
import React, { useState, useEffect } from 'react';
import { render, Box, Text, useApp, useInput } from 'ink';
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

const App = () => {
    const { exit } = useApp();
    const [workers, setWorkers] = useState({
        d1: { name: 'D1 Worker', status: 'stopped', port: 8787, extraArgs: '--local' },
        trade: { name: 'Trade Worker', status: 'stopped', port: 8788, extraArgs: '' },
        webhook: { name: 'Webhook Receiver', status: 'stopped', port: 8789, extraArgs: '' },
        telegram: { name: 'Telegram Worker', status: 'stopped', port: 8790, extraArgs: '' }
    });

    const [selectedTab, setSelectedTab] = useState('dashboard');
    const [selectedWorker, setSelectedWorker] = useState(null);
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
            if (key.escape) {
                // Go back to dashboard from any other view
                if (selectedTab !== 'dashboard') {
                    setSelectedTab('dashboard');
                    setSelectedWorker(null);
                }
            }

            if (input === 'q' && key.ctrl) {
                // Exit application
                handleExit();
            }

            if (input === '1') {
                setSelectedTab('dashboard');
            } else if (input === '2') {
                setSelectedTab('workers');
            } else if (input === '3') {
                setSelectedTab('logs');
            }

            // Worker control shortcuts
            if (selectedTab === 'workers') {
                if (input === 'a') {
                    handleStartAll();
                } else if (input === 's') {
                    handleStopAll();
                } else if (input === 'r') {
                    handleRestartAll();
                }
            }
        } catch (error) {
            // If error occurs during input handling, set inputAvailable to false
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

    // Render appropriate content based on selected tab
    const renderContent = () => {
        if (selectedTab === 'dashboard') {
            return (
                <Box flexDirection="column">
                    <Box marginY={0}>
                        <WorkerStatus workers={workers} />
                    </Box>
                    <Box marginY={0}>
                        <ActionMenu
                            onStartAll={handleStartAll}
                            onStopAll={handleStopAll}
                            onRestartAll={handleRestartAll}
                            onExit={handleExit}
                        />
                    </Box>
                </Box>
            );
        } else if (selectedTab === 'workers') {
            return (
                <WorkerControls
                    workers={workers}
                    onStart={handleStartWorker}
                    onStop={handleStopWorker}
                    onRestart={handleRestartWorker}
                    onViewLogs={handleViewLogs}
                />
            );
        } else if (selectedTab === 'logs') {
            return (
                <LogsViewer
                    logs={logs}
                    selectedWorker={selectedWorker}
                    workers={workers}
                />
            );
        }
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
        <Box flexDirection="column" padding={0}>
            <Header selectedTab={selectedTab} onChangeTab={setSelectedTab} />

            {isLoading ? (
                <Box marginY={0}>
                    <Text color="yellow">
                        <Spinner type="dots" />
                        <Text> Loading...</Text>
                    </Text>
                </Box>
            ) : (
                renderContent()
            )}

            {statusMessage && (
                <Box marginY={0} borderStyle="round" borderColor="yellow" padding={1}>
                    <Text color="yellow">{statusMessage}</Text>
                </Box>
            )}

            <Box marginTop={0}>
                <CommandBar selectedTab={selectedTab} />
            </Box>
        </Box>
    );
};

// Handle errors with rendering
try {
    render(<App />);
} catch (error) {
    console.error("Failed to render TUI:", error);
    console.log("Use './hoox-tui' to run in interactive mode");
    process.exit(1);
} 