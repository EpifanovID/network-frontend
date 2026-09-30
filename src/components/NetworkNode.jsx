import { Handle, Position } from '@xyflow/react';
import { useState } from 'react';

import antenna1 from '../assets/icons/antenna_1.svg';
import antenna2 from '../assets/icons/antenna_2.svg';
import antenna3 from '../assets/icons/antenna_3.svg';

const icons = {
    antenna1,
    antenna2,
    antenna3,
};

function getHandleClassName(handleId, connectedHandles) {
    return `network-node__handle ${
        connectedHandles.has(handleId)
            ? 'network-node__handle--connected'
            : ''
    }`;
}


function NetworkNode({ data }) {
    const icon = icons[data.type] || antenna1;

    return (
        <div className="network-node">
            {/* Верхняя сторона */}
            <Handle
                type="target"
                position={Position.Top}
                id="top-target"
                className="network-node__handle"
            />

            <Handle
                type="source"
                position={Position.Top}
                id="top-source"
                className="network-node__handle"
            />

            {/* Левая сторона */}
            <Handle
                type="target"
                position={Position.Left}
                id="left-target"
                className="network-node__handle"
            />

            <Handle
                type="source"
                position={Position.Left}
                id="left-source"
                className="network-node__handle"
            />

            <img
                src={icon}
                alt={data.label}
                className="network-node__icon"
                onMouseEnter={() => {
                    if (data.onMouseEnter) {
                        data.onMouseEnter();
                    }
                }}
                onMouseLeave={() => {
                    if (data.onMouseLeave) {
                        data.onMouseLeave();
                    }
                }}
            />

            <div className="network-node__label">
                {data.label}
            </div>

            {/* Правая сторона */}
            <Handle
                type="target"
                position={Position.Right}
                id="right-target"
                className="network-node__handle"
            />

            <Handle
                type="source"
                position={Position.Right}
                id="right-source"
                className="network-node__handle"
            />

            {/* Нижняя сторона */}
            <Handle
                type="target"
                position={Position.Bottom}
                id="bottom-target"
                className="network-node__handle"
            />

            <Handle
                type="source"
                position={Position.Bottom}
                id="bottom-source"
                className="network-node__handle"
            />
        </div>
    );
}


export default NetworkNode;