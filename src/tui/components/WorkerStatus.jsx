import React from 'react';
import { Box, Text } from 'ink';
import chalk from 'chalk';
import figures from 'figures';

// Helper function to get status icon and color
const getStatusDisplay = (status) => {
    switch (status) {
        case 'running':
            return { icon: figures.tick, color: 'green' };
        case 'starting':
            return { icon: figures.arrowRight, color: 'yellow' };
        case 'stopping':
            return { icon: figures.arrowLeft, color: 'yellow' };
        case 'error':
            return { icon: figures.cross, color: 'red' };
        case 'stopped':
        default:
            return { icon: figures.circle, color: 'gray' };
    }
};

const WorkerStatus = ({ workers, selectedWorker }) => {
    return (
        <Box flexDirection="column" padding={0}>
            <Box paddingBottom={0}>
                <Text color="blue" bold>Worker Status</Text>
            </Box>

            {Object.entries(workers).map(([id, worker]) => {
                const { icon, color } = getStatusDisplay(worker.status);
                const isSelected = id === selectedWorker;

                return (
                    <Box key={id} marginBottom={0} backgroundColor={isSelected ? 'gray' : undefined}>
                        <Box width={20}>
                            <Text bold color={isSelected ? 'white' : undefined}>{worker.name}</Text>
                        </Box>
                        <Box width={15}>
                            <Text color={isSelected ? 'white' : color}>
                                {icon} {worker.status.charAt(0).toUpperCase() + worker.status.slice(1)}
                            </Text>
                        </Box>
                        <Box>
                            <Text dimColor>Port: {worker.port}</Text>
                        </Box>
                    </Box>
                );
            })}
        </Box>
    );
};

export default WorkerStatus; 