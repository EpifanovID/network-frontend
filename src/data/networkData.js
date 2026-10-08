export const initialNodes = [
    { id: '1',  lng: 37.62, lat: 55.75, data: { label: 'Объект 1',  treeNumber: '1' } },
    { id: '2',  lng: 30.31, lat: 59.94, data: { label: 'Объект 2',  treeNumber: '2' } },
    { id: '3',  lng: 49.12, lat: 55.79, data: { label: 'Объект 3',  treeNumber: '3' } },
    { id: '4',  lng: 82.93, lat: 55.03, data: { label: 'Объект 4',  treeNumber: '1' } },
    { id: '5',  lng: 60.60, lat: 56.84, data: { label: 'Объект 5',  treeNumber: '2' } },
    { id: '6',  lng: 44.00, lat: 56.32, data: { label: 'Объект 6',  treeNumber: '1' } },
    { id: '7',  lng: 39.20, lat: 51.66, data: { label: 'Объект 7',  treeNumber: '3' } },
    { id: '8',  lng: 55.10, lat: 51.77, data: { label: 'Объект 8',  treeNumber: '1' } },
    { id: '9',  lng: 73.40, lat: 54.99, data: { label: 'Объект 9',  treeNumber: '3' } },
    { id: '10', lng: 49.10, lat: 55.00, data: { label: 'Объект 10', treeNumber: '1' } },
];

export function getTreeNumberById(objectId) {
    const node = initialNodes.find(
        (n) => String(n.id) === String(objectId)
    );
    return node ? node.data.treeNumber : null;
}
