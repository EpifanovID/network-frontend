function Passport({ type, data, position }) {
    if (!data || !position) {
        return null;
    }

    return (
        <div
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