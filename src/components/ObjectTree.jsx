import { ReactFlow, Background, Controls, Handle, Panel, Position } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import { useMemo } from 'react';
import '@xyflow/react/dist/style.css';
import { buildObjectSubtree } from '../utils/objectTree';
import { diagramEdgeTypes, diagramEdgeOptions } from './diagramEdges';

const NODE_WIDTH = 224;
const NODE_HEIGHT = 86;

function CompositionNode({ data }) {
    return (
        <div className={`composition-node${data.isRoot ? ' composition-node--root' : ''}`}>
            {!data.isRoot && <Handle type="target" position={Position.Top} />}
            <span className="composition-node__category">{data.isRoot ? 'УЗЕЛ СВЯЗИ' : 'ЭЛЕМЕНТ СОСТАВА'}</span>
            <strong className="composition-node__name" title={data.label}>{data.label}</strong>
            <span className="composition-node__type" title={data.type}>{data.type || 'Тип не указан'}</span>
            <Handle type="source" position={Position.Bottom} />
        </div>
    );
}

const nodeTypes = { composition: CompositionNode };


function ObjectTree({ nodes: graphNodes, edges: graphEdges, rootId }) {
    const tree = useMemo(() => buildObjectSubtree(graphNodes, graphEdges, rootId),
        [graphNodes, graphEdges, rootId]);
    const edges = useMemo(() => tree.edges.map((edge) => ({ ...edge, type: 'composition' })), [tree]);
    const nodes = useMemo(() => {
        if (!tree.nodes.length) return [];
        const layout = new dagre.graphlib.Graph();
        layout.setDefaultEdgeLabel(() => ({}));
        layout.setGraph({ rankdir: 'TB', nodesep: 32, ranksep: 108, marginx: 24, marginy: 24 });
        tree.nodes.forEach((node) => layout.setNode(node.id, { width: NODE_WIDTH, height: NODE_HEIGHT }));
        tree.edges.forEach((edge) => layout.setEdge(edge.source, edge.target));
        dagre.layout(layout);
        return tree.nodes.map((node) => {
            const position = layout.node(node.id);
            return {
                id: node.id,
                type: 'composition',
                position: { x: position.x - NODE_WIDTH / 2, y: position.y - NODE_HEIGHT / 2 },
                data: { label: node.data.label, type: node.data.templateName || node.data.type, isRoot: node.id === rootId },
            };
        });
    }, [tree, rootId]);

    if (!nodes.length) return <div className="object-tree__status" role="status">Состав узла не найден.</div>;

    return (
        <div className="object-tree">
            <div className="object-tree__summary">
                <span><i className="object-tree__dot" /> Иерархия оборудования</span>
                <span>{nodes.length - 1} элементов · {tree.edges.length} связей</span>
            </div>
            <div className="object-tree__canvas">
                <ReactFlow
                    key={rootId}
                    nodes={nodes}
                    edges={edges}
                    nodeTypes={nodeTypes}
                    edgeTypes={diagramEdgeTypes}
                    defaultEdgeOptions={diagramEdgeOptions}
                    fitView
                    fitViewOptions={{ padding: 0.16, maxZoom: 1 }}
                    minZoom={0.15}
                    maxZoom={2}
                    nodesDraggable={false}
                    nodesConnectable={false}
                    aria-label="Граф состава узла связи"
                >
                    <Background color="#ded8ce" gap={24} size={1} />
                    <Controls showInteractive={false} />
                    {nodes.length === 1 && (
                        <Panel position="top-center">Состав этого узла пока не заполнен</Panel>
                    )}
                </ReactFlow>
            </div>
        </div>
    );
}

export default ObjectTree;
