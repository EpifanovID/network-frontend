import { MarkerType } from '@xyflow/react';
import DiagramEdge from './DiagramEdge';

export const diagramEdgeTypes = { composition: DiagramEdge };
export const diagramEdgeOptions = {
    type: 'composition',
    style: { stroke: '#ad8a68', strokeWidth: 1.5 },
    markerEnd: { type: MarkerType.ArrowClosed, color: '#ad8a68', width: 16, height: 16 },
    labelStyle: { fill: '#76583d', fontSize: 12, fontWeight: 500 },
    labelBgStyle: { fill: '#fbfaf7', fillOpacity: 1 },
    labelBgPadding: [7, 4],
    labelBgBorderRadius: 5,
};
