import { useParams } from 'react-router-dom';
import ObjectTree from '../components/ObjectTree';

function ObjectPage() {
    const { objectId } = useParams();

    return (
        <div className="object-page">
            <div className="object-page__header">
                <h1>Структура объекта {objectId}</h1>
            </div>

            <div className="object-page__content">
                <ObjectTree objectId={objectId} />
            </div>
        </div>
    );
}

export default ObjectPage;