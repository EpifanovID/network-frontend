import { Handle, Position } from '@xyflow/react';

import NetworkNodeContent from './NetworkNodeContent';

function NetworkNode({ data }) {
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

            <NetworkNodeContent data={data} />

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