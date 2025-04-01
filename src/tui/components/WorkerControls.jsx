import React from 'react';
import { Box, Text } from 'ink';
import figures from 'figures';

const ControlButton = ({ label, shortcut, onSelect, disabled = false, color = 'blue' }) => (
    <Box
        marginRight={1}
        paddingX={1}
        borderStyle="round"
        borderColor={disabled ? 'gray' : color}
    >
        <Text color={disabled ? 'gray' : color} dimColor={disabled}>
            {label} {shortcut && <Text color="gray" dimColor>[{shortcut}]</Text>}
        </Text>
    </Box>
);

const WorkerControls = ({ workers, selectedWorker, onStart, onStop, onRestart, onViewLogs, height = 'auto' }) => {
    const worker = workers[selectedWorker];

    if (!worker) {
        return <Box height={height}><Text>Select a worker</Text></Box>;
    }

    const isRunning = worker.status === 'running';
    const isStarting = worker.status === 'starting';
    const isStopping = worker.status === 'stopping';
    const isBusy = isStarting || isStopping;

    return (
        <Box flexDirection="column" padding={0} height={height}>
            <Box paddingBottom={0}>
                <Text color="green" bold>Controls for: {worker.name}</Text>
            </Box>

            <Box marginTop={1}>
                <ControlButton
                    label={`${figures.play} Start`}
                    shortcut="s"
                    onSelect={() => onStart(selectedWorker)}
                    disabled={isRunning || isBusy}
                    color="green"
                />

                <ControlButton
                    label={`${figures.squareSmall} Stop`}
                    shortcut="k"
                    onSelect={() => onStop(selectedWorker)}
                    disabled={!isRunning || isBusy}
                    color="red"
                />

                <ControlButton
                    label={`${figures.arrowRight} Restart`}
                    shortcut="r"
                    onSelect={() => onRestart(selectedWorker)}
                    disabled={!isRunning || isBusy}
                    color="yellow"
                />

                <ControlButton
                    label={`${figures.ellipsis} Logs`}
                    shortcut="l"
                    onSelect={() => onViewLogs(selectedWorker)}
                    color="cyan"
                />
            </Box>

            <Box marginTop={1}>
                <Text dimColor>Port: {worker.port} | Status: </Text>
                <Text color={getStatusColor(worker.status)}>
                    {getStatusIcon(worker.status)} {worker.status.charAt(0).toUpperCase() + worker.status.slice(1)}
                </Text>
                {worker.extraArgs && (
                    <Text dimColor> | Args: {worker.extraArgs}</Text>
                )}
            </Box>
        </Box>
    );
};

// Helper functions for status display
const getStatusColor = (status) => {
    switch (status) {
        case 'running': return 'green';
        case 'starting':
        case 'stopping': return 'yellow';
        case 'error': return 'red';
        case 'stopped':
        default: return 'gray';
    }
};

const getStatusIcon = (status) => {
    switch (status) {
        case 'running': return figures.tick;
        case 'starting': return figures.arrowRight;
        case 'stopping': return figures.arrowLeft;
        case 'error': return figures.cross;
        case 'stopped':
        default: return figures.circle;
    }
};

export default WorkerControls; 