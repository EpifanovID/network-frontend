function Toolbar({
    isMapVisible,
    onMapToggle,
}) {
    return (
        <div className="toolbar">
            <button
                className={`toolbar__button ${
                    isMapVisible
                        ? 'toolbar__button--active'
                        : ''
                }`}
                onClick={onMapToggle}
                title="Физическая карта"
            >
                <span className="toolbar__icon">
                    🗺
                </span>
            </button>
        </div>
    );
}

export default Toolbar;