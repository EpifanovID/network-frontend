export function parseXmlTree(xmlText) {
    const parser = new DOMParser();

    const xmlDocument = parser.parseFromString(
        xmlText,
        'application/xml'
    );

    const parserError = xmlDocument.querySelector(
        'parsererror'
    );

    if (parserError) {
        console.error(
            'Ошибка XML:',
            parserError.textContent
        );

        console.error(
            'Полученный XML:',
            xmlText
        );

        throw new Error(
            `Ошибка при разборе XML: ${parserError.textContent}`
        );
    }

    const treeElement = xmlDocument.querySelector('tree');

    if (!treeElement) {
        throw new Error(
            'Корневой элемент <tree> не найден'
        );
    }

    function parseNode(element) {
        const node = {
            id: element.getAttribute('id'),
            name: element.getAttribute('name'),
            type: element.getAttribute('type'),
            children: [],
        };

        const children = element.querySelectorAll(
            ':scope > node'
        );

        children.forEach((child) => {
            node.children.push(
                parseNode(child)
            );
        });

        return node;
    }

    const tree = {
        id: treeElement.getAttribute('id'),
        name: treeElement.getAttribute('name'),
        children: [],
    };

    const rootNodes = treeElement.querySelectorAll(
        ':scope > node'
    );

    rootNodes.forEach((node) => {
        tree.children.push(
            parseNode(node)
        );
    });

    return tree;
}