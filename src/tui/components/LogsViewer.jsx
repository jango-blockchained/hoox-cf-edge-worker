import React, { useState, useEffect } from 'react';
import { Box, Text, useInput } from 'ink';
import figures from 'figures';

const LogsViewer = ({ logs, selectedWorker, workers }) => {
    const [activeWorkerId, setActiveWorkerId] = useState(selectedWorker || 'd1');
    const [scrollPosition, setScrollPosition] = useState(0);
    const [autoScroll, setAutoScroll] = useState(true);

    const workerLogs = logs[activeWorkerId] || [];
    const activeWorkerName = workers[activeWorkerId]?.name || 'Unknown Worker';

    // Reset scroll position when worker changes
    useEffect(() => {
        if (autoScroll) {
            setScrollPosition(Math.max(0, workerLogs.length - 15));
        }
    }, [activeWorkerId, workerLogs.length, autoScroll]);

    // Handle keyboard input for navigation
    useInput((input, key) => {
        // Worker selection
        if (input >= '1' && input <= '4') {
            const workerIds = Object.keys(workers);
            const index = parseInt(input) - 1;
            if (index < workerIds.length) {
                setActiveWorkerId(workerIds[index]);
            }
        }

        // Scrolling
        if (key.upArrow) {
            setAutoScroll(false);
            setScrollPosition(Math.max(0, scrollPosition - 1));
        } else if (key.downArrow) {
            setAutoScroll(false);
            setScrollPosition(Math.min(workerLogs.length - 15, scrollPosition + 1));
        } else if (key.pageUp) {
            setAutoScroll(false);
            setScrollPosition(Math.max(0, scrollPosition - 10));
        } else if (key.pageDown) {
            setAutoScroll(false);
            setScrollPosition(Math.min(workerLogs.length - 15, scrollPosition + 10));
        } else if (input === 'a') {
            setAutoScroll(!autoScroll);
        } else if (input === 'g') {
            setAutoScroll(false);
            setScrollPosition(0); // Go to top
        } else if (input === 'G') {
            setAutoScroll(false);
            setScrollPosition(Math.max(0, workerLogs.length - 15)); // Go to bottom
        }
    });

    // Visible logs based on scroll position
    const visibleLogs = workerLogs.slice(
        scrollPosition,
        scrollPosition + 15
    );

    return (
        <Box flexDirection="column" borderStyle="round" borderColor="cyan" padding={1}>
            <Box paddingBottom={1}>
                <Text color="cyan" bold>
                    Logs: {activeWorkerName}
                </Text>
                <Box marginLeft={2}>
                    <Text color="gray" dimColor>
                        Auto-scroll: {autoScroll ? `${figures.tick} ON` : `${figures.cross} OFF`} [a]
                    </Text>
                </Box>
            </Box>

            <Box borderStyle="single" borderColor="gray" paddingX={1} paddingY={0} flexDirection="column">
                {visibleLogs.length > 0 ? (
                    visibleLogs.map((log, index) => (
                        <Text key={index} wrap="truncate">
                            {log}
                        </Text>
                    ))
                ) : (
                    <Text color="gray" dimColor>No logs available</Text>
                )}
            </Box>

            <Box marginTop={1}>
                <Text dimColor>
                    Workers:
                    {Object.entries(workers).map(([id, worker], index) => (
                        <Text key={id} color={activeWorkerId === id ? 'cyan' : 'gray'}>
                            {' '}[{index + 1}] {worker.name}
                        </Text>
                    ))}
                </Text>
            </Box>

            <Box marginTop={1}>
                <Text dimColor>
                    Scroll: ↑/↓ | Page Up/Down | g/G (top/bottom) | a (toggle auto-scroll)
                </Text>
            </Box>
        </Box>
    );
};

export default LogsViewer; 