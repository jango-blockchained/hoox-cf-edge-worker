import React from 'react';
import { Box, Text } from 'ink';
import figures from 'figures';

const CommandBar = ({ selectedTab }) => {
    // Define common commands
    const commonCommands = [
        { key: '1-3', description: 'Switch tabs' },
        { key: 'Esc', description: 'Back to dashboard' },
        { key: 'Ctrl+q', description: 'Exit' }
    ];

    // Define tab-specific commands
    const tabCommands = {
        dashboard: [
            { key: 'a', description: 'Start all workers' },
            { key: 's', description: 'Stop all workers' },
            { key: 'r', description: 'Restart all workers' }
        ],
        workers: [
            { key: 'a', description: 'Start all workers' },
            { key: 's', description: 'Stop all workers' },
            { key: 'r', description: 'Restart all workers' }
        ],
        logs: [
            { key: '1-4', description: 'Switch worker' },
            { key: '↑/↓', description: 'Scroll lines' },
            { key: 'PgUp/PgDn', description: 'Scroll pages' },
            { key: 'g/G', description: 'Top/Bottom' },
            { key: 'a', description: 'Toggle auto-scroll' }
        ]
    };

    // Get commands for current tab
    const currentTabCommands = tabCommands[selectedTab] || [];

    return (
        <Box borderStyle="single" borderColor="gray" padding={0}>
            <Text dimColor>
                {commonCommands.concat(currentTabCommands).map((cmd, index) => (
                    <Text key={index}>
                        {index > 0 && ' | '}
                        <Text bold color="blue">{cmd.key}</Text> {cmd.description}
                    </Text>
                ))}
            </Text>
        </Box>
    );
};

export default CommandBar; 