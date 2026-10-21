export const DEMO_LINE_ID = '53ff7800-a047-48dd-ba59-50daff0e98d3';
export const relationKinds = {
    1: { label: 'имеет', color: '#b3987a', group: 'structure' },
    2: { label: 'подключён к', color: '#805333', group: 'physical' },
    3: { label: 'начинается в', color: '#4e8067', group: 'channel' },
    4: { label: 'проходит через', color: '#af8045', group: 'channel' },
    5: { label: 'заканчивается в', color: '#4e8067', group: 'channel' },
    6: { label: 'входит в', color: '#826490', group: 'channel' },
};

const object = (number, label, kind, group, x, y, note = '') => ({
    id: `LS1-${String(number).padStart(3, '0')}`, type: 'lineObject', position: { x, y },
    data: { label, kind, group, note },
});

export const lineExampleNodes = [
    object(1, 'УС1', 'Узел связи', 'УС1', 0, 0),
    object(2, 'П-317D · УС1', 'Оборудование', 'УС1', 0, 160),
    object(3, 'Слот 1', 'Слот оборудования', 'УС1', 0, 320),
    object(4, 'STM-4 · УС1', 'Блок STM-4', 'УС1', 0, 480),
    object(5, 'Порт 1 · STM-4', 'Начало канала', 'УС1', 0, 640),
    object(6, 'SFP-модуль', 'Оптический модуль', 'УС1', 0, 840),
    object(7, 'Кросс ODF · УС1 / A', 'Оптический кросс', 'УС1', 300, 840),
    object(8, 'Маршрутизатор', 'Оборудование', 'УС1', 300, 320),
    object(9, 'Порт 1 · маршрутизатор', 'Порт маршрутизатора', 'УС1', 300, 640,
        'Включение порта маршрутизатора в последовательный маршрут — предположение по рисунку.'),
    object(10, 'Кросс ODF · УС1 / B', 'Оптический кросс', 'УС1', 600, 840),
    object(11, 'ВОЛС', 'Волоконно-оптическая линия', 'Среда передачи', 640, 320,
        'Верхняя центральная подпись на рисунке прочитана как «ВОЛС».'),
    object(12, 'Оптоволокно № 58', 'Среда передачи', 'Среда передачи', 640, 640),
    object(13, 'Кросс ODF · УС2', 'Оптический кросс', 'УС2', 1000, 840),
    object(14, 'УС2', 'Узел связи', 'УС2', 1280, 0),
    object(15, 'П-317D · УС2', 'Оборудование', 'УС2', 1280, 160),
    object(16, 'Слот 2', 'Слот оборудования', 'УС2', 1280, 320),
    object(17, 'STM-4 · УС2', 'Блок STM-4', 'УС2', 1280, 480),
    object(18, 'Порт 4 · STM-4', 'Конец канала', 'УС2', 1280, 640),
    object(19, 'Канал связи STM-4', 'Канал связи', 'Канал и тракт', 600, 1140),
    object(20, 'Тракт № 45', 'Тракт', 'Канал и тракт', 1000, 1140),
];

const id = (number) => `LS1-${String(number).padStart(3, '0')}`;
const relations = [
    [1, 2, 1], [2, 3, 1], [3, 4, 1], [4, 5, 1], [1, 8, 1], [8, 9, 1],
    [14, 15, 1], [15, 16, 1], [16, 17, 1], [17, 18, 1], [11, 12, 1],
    [5, 6, 2], [6, 7, 2], [7, 9, 2], [9, 10, 2], [10, 12, 2], [13, 12, 2], [18, 13, 2],
    [19, 5, 3], [19, 6, 4], [19, 7, 4], [19, 9, 4], [19, 10, 4], [19, 12, 4], [19, 13, 4],
    [19, 18, 5], [19, 20, 6],
];
const physicalPorts = [
    ['bottom', 'top'], ['bottom', 'top'], ['bottom', 'top'], ['bottom', 'top'], ['right', 'top'], ['bottom', 'top'],
    ['bottom', 'top'], ['bottom', 'top'], ['bottom', 'top'], ['bottom', 'top'], ['bottom', 'top'],
    ['bottom', 'top'], ['right', 'left'], ['top', 'bottom'], ['right', 'top'], ['top', 'bottom'], ['left', 'right'], ['bottom', 'top'],
];

export const lineExampleEdges = relations.map(([source, target, relation], index) => {
    const channelRoute = relation >= 3 && relation <= 5;
    const channelTargetSide = target === 5 ? 'left' : target === 9 || target === 12 ? 'right' : 'bottom';
    const [sourceSide, targetSide] = channelRoute ? ['top', channelTargetSide]
        : relation === 6 ? ['right', 'left'] : physicalPorts[index];
    const edgeId = `LS1-R${String(index + 1).padStart(2, '0')}`;
    return { id: edgeId, source: id(source), target: id(target), type: 'lineRelation',
        sourceHandle: `${edgeId}-source`, targetHandle: `${edgeId}-target`,
        data: { relation, ...relationKinds[relation], sourceSide, targetSide,
            laneY: channelRoute ? 980 + (index - 18) * 20 : null,
            approachX: channelRoute ? ({ 5: -60, 9: 560, 12: 900 })[target] : undefined,
            assumption: index === 13 || index === 17 || index === 21 },
    };
});

export const exampleRoute = [5, 6, 7, 9, 10, 12, 13, 18].map(id);

export function getExamplePorts(nodeId) {
    return lineExampleEdges.flatMap((edge) => [
        ...(edge.source === nodeId ? [{ id: edge.sourceHandle, type: 'source', side: edge.data.sourceSide }] : []),
        ...(edge.target === nodeId ? [{ id: edge.targetHandle, type: 'target', side: edge.data.targetSide }] : []),
    ]);
}
