import React from 'react';
import { Box, Text } from 'ink';
import chalk from 'chalk';
import figures from 'figures';

const Header = ({ selectedTab, onChangeTab }) => {
    const tabs = [
        { id: 'dashboard', label: 'Dashboard', shortcut: '1' },
        { id: 'workers', label: 'Workers', shortcut: '2' },
        { id: 'logs', label: 'Logs', shortcut: '3' }
    ];

    return (
        <Box flexDirection="column">
            <Box borderStyle="round" borderColor="cyan" padding={1} width="100%">
                <Text color="cyan" bold>
                    {chalk.bold('Hoox Trading System Management Console')}
                </Text>
            </Box>

            <Box marginTop={1}>
                {tabs.map((tab) => (
                    <Box
                        key={tab.id}
                        marginRight={2}
                        paddingX={2}
                        paddingY={0}
                        borderStyle={selectedTab === tab.id ? 'round' : 'single'}
                        borderColor={selectedTab === tab.id ? 'green' : 'gray'}
                    >
                        <Text
                            color={selectedTab === tab.id ? 'green' : 'gray'}
                            bold={selectedTab === tab.id}
                        >
                            {selectedTab === tab.id ? figures.radioOn : figures.radioOff} {tab.label} <Text color="gray" dimColor>[{tab.shortcut}]</Text>
                        </Text>
                    </Box>
                ))}
            </Box>
        </Box>
    );
};

export default Header; 