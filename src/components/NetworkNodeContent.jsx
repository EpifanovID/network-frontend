function NetworkNodeContent({ data }) {
    const isConnectionNode = /узел связи/i.test(data.templateName || data.type || '');
    return (
        <>
            <span className="network-node__category">{isConnectionNode ? 'УЗЕЛ СВЯЗИ' : 'ОБЪЕКТ СЕТИ'}</span>
            <strong className="network-node__label">{data.label}</strong>
            <span className="network-node__type" title={data.templateName || data.type}>{data.templateName || data.type}</span>
        </>
    );
}

export default NetworkNodeContent;
