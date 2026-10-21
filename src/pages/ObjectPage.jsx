import { Link, useParams } from 'react-router-dom';
import { useEffect, useState } from 'react';

import ObjectTree from '../components/ObjectTree';
import { fetchJson } from '../utils/api';

function ObjectPage() {
    const { objectId } = useParams();
    const [graph, setGraph] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        const controller = new AbortController();

        async function loadGraph() {
            try {
                setLoading(true);
                setError('');
                const result = await fetchJson('/api/graph', {
                    signal: controller.signal,
                });
                if (!Array.isArray(result.nodes) || !Array.isArray(result.edges)) {
                    throw new TypeError('API вернул данные графа в неверном формате.');
                }
                setGraph(result);
            } catch (loadError) {
                if (controller.signal.aborted) return;
                console.error('Не удалось загрузить структуру объекта.', loadError);
                setError(loadError.message || 'Не удалось загрузить структуру объекта.');
            } finally {
                if (!controller.signal.aborted) setLoading(false);
            }
        }

        loadGraph();
        return () => controller.abort();
    }, []);

    const object = graph?.nodes.find((node) => node.id === objectId);

    return (
        <div className="object-page">
            <div className="object-page__header">
                <Link to="/" className="object-page__back">
                    ← К карте
                </Link>
                <div className="object-page__heading">
                <span className="object-page__eyebrow">СЕТЬ СВЯЗИ / СОСТАВ</span>
                <h1>
                    {object
                        ? `Состав узла связи · ${object.data.label}`
                        : `Состав узла связи`}
                </h1>
                {object && <p>{object.data.templateName || object.data.type}</p>}
                </div>
            </div>
            <div className="object-page__content">
                {loading ? (
                    <div className="object-tree__status" role="status">
                        Загружаю состав узла связи…
                    </div>
                ) : error ? (
                    <div className="object-tree__status" role="alert">
                        Не удалось загрузить состав: {error}
                    </div>
                ) : object ? (
                    <ObjectTree
                        nodes={graph.nodes}
                        edges={graph.edges}
                        rootId={objectId}
                    />
                ) : (
                    <div className="object-tree__status" role="status">
                        Объект не найден в базе данных.
                    </div>
                )}
            </div>
        </div>
    );
}

export default ObjectPage;