import { useParams } from 'react-router-dom';
import ObjectTree from '../components/ObjectTree';
import { initialNodes } from './NetworkPage';

function ObjectPage() {
    const { objectId } = useParams();

    const object = initialNodes.find(
        (n) => String(n.id) === String(objectId)
    );

    const treeNumber = object?.data?.treeNumber ?? null;

    return (
        <div className="object-page">
            <div className="object-page__header">
                <h1>Структура объекта {objectId}</h1>
            </div>
            <div className="object-page__content">
                {treeNumber ? (
                    <ObjectTree treeNumber={treeNumber} />
                ) : (
                    <div>Объект не найден</div>
                )}
            </div>
        </div>
    );
}

export default ObjectPage;