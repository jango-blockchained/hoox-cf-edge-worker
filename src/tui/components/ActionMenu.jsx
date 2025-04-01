import React from 'react';
import { Box, Text } from 'ink';
import figures from 'figures';

const ActionButton = ({ label, shortcut, onSelect, color = 'blue' }) => (
    <Box
        marginRight={1}
        paddingX={0}
        borderStyle="round"
        borderColor={color}
    >
        <Text color={color}>
            {label} <Text color="gray" dimColor>[{shortcut}]</Text>
        </Text>
    </Box>
);

const ActionMenu = ({ onStartAll, onStopAll, onRestartAll, onExit }) => {
    return (
        <Box flexDirection="column" borderStyle="round" borderColor="magenta" paddingX={1} paddingY={0}>
            <Box paddingBottom={0}>
                <Text color="magenta" bold>Actions</Text>
            </Box>

            <Box>
                <ActionButton
                    label={`${figures.play} Start All`}
                    shortcut="a"
                    onSelect={onStartAll}
                    color="green"
                />

                <ActionButton
                    label={`${figures.squareSmall} Stop All`}
                    shortcut="s"
                    onSelect={onStopAll}
                    color="red"
                />

                <ActionButton
                    label={`${figures.arrowRight} Restart All`}
                    shortcut="r"
                    onSelect={onRestartAll}
                    color="yellow"
                />

                <ActionButton
                    label={`${figures.cross} Exit`}
                    shortcut="Ctrl+q"
                    onSelect={onExit}
                    color="gray"
                />
            </Box>
        </Box>
    );
};

export default ActionMenu; 