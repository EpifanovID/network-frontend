import antenna1 from '../assets/icons/antenna_1.svg';
import antenna2 from '../assets/icons/antenna_2.svg';
import antenna3 from '../assets/icons/antenna_3.svg';

const icons = {
    1: antenna1,
    2: antenna2,
    3: antenna3,
};

function NetworkNodeContent({ data }) {
    const icon = icons[data.treeNumber] || antenna1;

    return (
        <>
            <img
                src={icon}
                alt={data.label}
                className="network-node__icon"
            />
            <div className="network-node__label">{data.label}</div>
        </>
    );
}

export default NetworkNodeContent;
