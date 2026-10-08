import { Link } from 'react-router-dom';
import { useState } from 'react';

function Passport({
    type,
    data,
    position,
    elementRef,
    onCoordinatesChange,
    onFocusLocation,
}) {
    const [longitude, setLongitude] = useState(data?.lng ?? '');
    const [latitude, setLatitude] = useState(data?.lat ?? '');
    const [coordinateError, setCoordinateError] = useState('');

    if (!data || !position) {
        return null;
    }

    const handleCoordinatesSubmit = (event) => {
        event.preventDefault();
        const lng = Number(longitude);
        const lat = Number(latitude);
        if (
            !Number.isFinite(lng)
            || !Number.isFinite(lat)
            || lng < -180
            || lng > 180
            || lat < -90
            || lat > 90
        ) {
            setCoordinateError('Введите долготу от −180 до 180 и широту от −90 до 90.');
            return;
        }

        setCoordinateError('');
        setLongitude(lng);
        setLatitude(lat);
        onCoordinatesChange?.({ id: data.id, lng, lat });
    };

    return (
        <div
            ref={elementRef}
            className="passport"
            style={{
                left: `${position.x}px`,
                top: `${position.y}px`,
            }}
        >
            {type === 'node' && (
                <>
                    <div className="passport__title">
                        Паспорт объекта
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            Наименование:
                        </span>

                        <span className="passport__value">
                            {data.label}
                        </span>
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            ID:
                        </span>

                        <span className="passport__value">
                            {data.id}
                        </span>
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            Тип:
                        </span>

                        <span className="passport__value">
                            {data.type}
                        </span>
                    </div>

                    <form
                        className="passport__coordinates"
                        onSubmit={handleCoordinatesSubmit}
                    >
                        <label className="passport__coordinate-field">
                            <span>Долгота</span>
                            <input
                                type="number"
                                min="-180"
                                max="180"
                                step="any"
                                value={longitude}
                                onChange={(event) => setLongitude(event.target.value)}
                                required
                            />
                        </label>
                        <label className="passport__coordinate-field">
                            <span>Широта</span>
                            <input
                                type="number"
                                min="-90"
                                max="90"
                                step="any"
                                value={latitude}
                                onChange={(event) => setLatitude(event.target.value)}
                                required
                            />
                        </label>
                        {coordinateError && (
                            <div className="passport__coordinate-error" role="alert">
                                {coordinateError}
                            </div>
                        )}
                        <button
                            className="passport__action"
                            type="submit"
                        >
                            Сохранить и показать на карте
                        </button>
                        <button
                            className="passport__action passport__action--secondary"
                            type="button"
                            onClick={() => onFocusLocation?.(data.lng, data.lat)}
                        >
                            Показать текущее место
                        </button>
                    </form>

                    <Link
                        to={`/objects/${data.id}`}
                        className="passport__link"
                    >
                        Открыть структуру объекта →
                    </Link>
                </>
            )}

            {type === 'edge' && (
                <>
                    <div className="passport__title">
                        Паспорт соединения
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            ID:
                        </span>

                        <span className="passport__value">
                            {data.id}
                        </span>
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            Источник:
                        </span>

                        <span className="passport__value">
                            {data.source}
                        </span>
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            Приёмник:
                        </span>

                        <span className="passport__value">
                            {data.target}
                        </span>
                    </div>
                </>
            )}
        </div>
    );
}

export default Passport;