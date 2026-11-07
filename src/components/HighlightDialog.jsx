import { useEffect, useRef, useState } from 'react';
import { emptyHighlight, highlightInterfaces } from '../utils/networkHighlight';

const manualHelp = 'Клик по узлу добавляет его в подборку. Повторный клик снимает отметку. Для быстрого выбора используйте Ctrl + клик.';

function ManualHelp() {
    const [expanded, setExpanded] = useState(false);
    const [suppressHover, setSuppressHover] = useState(false);
    return <span className="highlight-dialog__help" data-suppress-hover={suppressHover}
        onPointerLeave={() => setSuppressHover(false)}>
        <button type="button" aria-label="Как выбрать узлы" aria-expanded={expanded}
            aria-controls="manual-selection-help" onClick={() => {
                setSuppressHover(expanded);
                setExpanded(!expanded);
            }}>?</button>
        <span id="manual-selection-help" className="highlight-dialog__help-text">{manualHelp}</span>
    </span>;
}

function Checklist({ label, options, value, onChange }) {
    return <div className="highlight-dialog__filter" role="group" aria-label={label}>
        <span>{label}</span>
        <div className="highlight-dialog__options">
            {options.map((option) => <label key={option.value}>
                <input type="checkbox" checked={value.includes(option.value)} onChange={(event) => onChange(
                    event.target.checked ? [...value, option.value] : value.filter((id) => id !== option.value)
                )} />
                {option.label}
            </label>)}
            {options.length === 0 && <small>Данные о границах недоступны</small>}
        </div>
    </div>;
}

function TerritoryPair({ label, options, value, onChange }) {
    return <div className="highlight-dialog__filter" role="group" aria-label={label}>
        <span>{label}</span>
        <div className="highlight-dialog__pair">
            {value.map((selected, index) => <label key={index}>
                <span>{index === 0 ? 'Откуда' : 'Куда'}</span>
                <select value={selected} disabled={options.length === 0}
                    onChange={(event) => onChange(value.map((id, position) => position === index ? event.target.value : id))}>
                    <option value="">Выберите территорию</option>
                    {options.map((option) => <option key={option.value} value={option.value}
                        disabled={option.value === value[1 - index]}>{option.label}</option>)}
                </select>
            </label>)}
        </div>
    </div>;
}

export default function HighlightDialog({ boundaries, draft, onDraftChange, open, onApply, onReset, onMinimize, onClose,
    section, onSectionChange, selectedNodes, hasAppliedManual, onStartManual, onApplyManual, onClearManual, onRemoveManualNode }) {
    const dialog = useRef(null);
    const manualCount = selectedNodes.length;
    useEffect(() => {
        if (open) dialog.current.showModal();
        else dialog.current.close();
    }, [open]);
    const change = (key) => (value) => onDraftChange((previous) => ({ ...previous, [key]: value }));
    const regions = (boundaries?.regions ?? []).map(({ properties }) => ({
        value: properties.shapeISO, label: properties.name,
    })).sort((first, second) => first.label.localeCompare(second.label, 'ru'));
    const districts = (boundaries?.districts ?? []).map(({ properties }) => ({
        value: properties.district, label: properties.district,
    }));
    const options = (values) => values.map((value) => ({ value, label: value }));
    const incompletePair = [draft.betweenRegions, draft.betweenDistricts]
        .some(([first, second]) => Boolean(first) !== Boolean(second));

    return <dialog ref={dialog} id="highlight-dialog" className="highlight-dialog" aria-labelledby="highlight-heading"
        onCancel={(event) => { event.preventDefault(); onClose(); }}
        onKeyDown={(event) => { if (event.key === 'Escape') event.stopPropagation(); }}>
        <form onSubmit={(event) => {
            event.preventDefault();
            if (section !== 'filters' || incompletePair) return;
            onApply(draft);
            onMinimize();
        }}>
            <header className="highlight-dialog__header">
                <div>
                    <h2 id="highlight-heading">Подсветить</h2>
                </div>
                <div className="highlight-dialog__actions">
                    <button type="button" className="highlight-dialog__close" aria-label="Свернуть настройки подсветки"
                        onClick={onMinimize}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                            <path d="M6 12h12" />
                        </svg>
                    </button>
                    <button type="button" className="highlight-dialog__close" aria-label="Закрыть настройки подсветки"
                        onClick={onClose}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                            <path d="m6 6 12 12M18 6 6 18" />
                        </svg>
                    </button>
                </div>
            </header>
            <div className="highlight-dialog__content">
            <div className="highlight-dialog__switch" role="group" aria-label="Способ подсветки">
                <button type="button" aria-pressed={section === 'filters'} onClick={() => onSectionChange('filters')}>По фильтрам</button>
                <button type="button" aria-pressed={section === 'manual'} onClick={() => onSectionChange('manual')}>Ручной выбор</button>
            </div>
            {section === 'manual' ? <div className="highlight-dialog__manual">
                <p role="status">Выбрано узлов: {manualCount}</p>
                {manualCount > 0 && <ul className="highlight-dialog__selected-nodes" aria-label="Выбранные узлы">
                    {selectedNodes.map(({ id, data }) => <li key={id}>
                        <span>{data.label}</span>
                        <button type="button" aria-label={`Убрать ${data.label} из подборки`}
                            onClick={() => onRemoveManualNode(id)}>
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                                <path d="m6 6 12 12M18 6 6 18" />
                            </svg>
                        </button>
                    </li>)}
                </ul>}
                <button type="button" onClick={onStartManual}>Выбрать узлы</button>
            </div> : <>
            <p className="highlight-dialog__manual">Если выбраны территория и класс, подсвечиваются узлы этого класса в выбранной территории.</p>
            <div className="highlight-dialog__body">
                <fieldset>
                    <legend>Узлы и линии связи</legend>
                    <Checklist label="В регионах" options={regions} value={draft.regions} onChange={change('regions')} />
                    <Checklist label="В округах" options={districts} value={draft.districts} onChange={change('districts')} />
                </fieldset>
                <fieldset>
                    <legend>Узлы связи</legend>
                    <Checklist label="Класс узла" options={options(['A', 'B', 'C'])}
                        value={draft.classes} onChange={change('classes')} />
                </fieldset>
                <fieldset>
                    <legend>Линии связи</legend>
                    <TerritoryPair label="Между регионами" options={regions}
                        value={draft.betweenRegions} onChange={change('betweenRegions')} />
                    <TerritoryPair label="Между округами" options={districts}
                        value={draft.betweenDistricts} onChange={change('betweenDistricts')} />
                </fieldset>
                <fieldset className="highlight-dialog__channels">
                    <legend>Каналы связи</legend>
                    <Checklist label="Тип интерфейса" options={options(highlightInterfaces)}
                        value={draft.interfaces} onChange={change('interfaces')} />
                </fieldset>
            </div>
            </>}
            </div>
            {section === 'manual' ? <footer className="highlight-dialog__footer">
                <button type="button" disabled={!manualCount && !hasAppliedManual} onClick={onClearManual}>Очистить выбор</button>
                <div>
                    <button type="button" disabled={!manualCount} onClick={() => onApplyManual(false)}>Подсветить выбранные</button>
                    <button type="button" disabled={!manualCount} onClick={() => onApplyManual(true)}>Показать только выбранные</button>
                    {open && <ManualHelp />}
                </div>
            </footer> :
            <footer className="highlight-dialog__footer">
                <label><input type="checkbox" checked={draft.hideOthers}
                    onChange={(event) => change('hideOthers')(event.target.checked)} />Скрыть иное</label>
                <div>
                    <button type="button" onClick={() => { onDraftChange(emptyHighlight); onReset(); }}>Сбросить всё</button>
                    <button type="submit" disabled={incompletePair}>Применить</button>
                </div>
                {incompletePair && <p role="status">Выберите обе территории для фильтра линий связи.</p>}
            </footer>}
        </form>
    </dialog>;
}
