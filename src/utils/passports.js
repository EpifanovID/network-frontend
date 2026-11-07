export function passportKey(passport) {
    const lineId = passport.data.lineId ?? (passport.data.isLine ? passport.nodeId : null);
    if (lineId != null) return `line:${lineId}`;
    return `${passport.type}:${passport.nodeId ?? passport.data.id}`;
}

export function openPassport(passports, next) {
    const key = passportKey(next);
    const existing = passports.find((item) => passportKey(item) === key);
    if (existing) {
        return [...passports.filter((item) => passportKey(item) !== key), {
            ...existing, pinned: existing.pinned || next.pinned,
        }];
    }
    return [...passports, next];
}

export function clampPassportPosition(card, bounds) {
    return {
        x: Math.max(bounds.left, Math.min(card.x, Math.max(bounds.left, bounds.right - card.width))),
        y: Math.max(bounds.top, Math.min(card.y, Math.max(bounds.top, bounds.bottom - card.height))),
    };
}

// Keep each card near its object, avoiding previously placed cards when space allows.
export function arrangePassports(cards, bounds) {
    const placed = [];
    const gap = 12;
    const ordered = [...cards.filter((card) => card.fixed), ...cards.filter((card) => !card.fixed)];
    for (const card of ordered) {
        if (card.fixed) {
            placed.push({ ...card, ...clampPassportPosition(card, bounds), overlap: 0, distance: 0 });
            continue;
        }
        const maxX = Math.max(bounds.left, bounds.right - card.width);
        const maxY = Math.max(bounds.top, bounds.bottom - card.height);
        const clampX = (x) => Math.max(bounds.left, Math.min(x, maxX));
        const clampY = (y) => Math.max(bounds.top, Math.min(y, maxY));
        const preferredX = clampX(card.x), preferredY = clampY(card.y);
        const xs = new Set([preferredX, bounds.left, maxX]);
        const ys = new Set([preferredY, bounds.top, maxY]);
        for (const other of placed) {
            xs.add(clampX(other.x + other.width + gap));
            xs.add(clampX(other.x - card.width - gap));
            ys.add(clampY(other.y + other.height + gap));
            ys.add(clampY(other.y - card.height - gap));
        }
        let best;
        for (const x of xs) for (const y of ys) {
            const overlap = placed.reduce((area, other) => area
                + Math.max(0, Math.min(x + card.width + gap, other.x + other.width) - Math.max(x - gap, other.x))
                * Math.max(0, Math.min(y + card.height + gap, other.y + other.height) - Math.max(y - gap, other.y)), 0);
            const distance = (x - preferredX) ** 2 + (y - preferredY) ** 2;
            if (!best || overlap < best.overlap || (overlap === best.overlap && distance < best.distance)) {
                best = { ...card, x, y, overlap, distance };
            }
        }
        placed.push(best);
    }
    const byKey = new Map(placed.map((card) => [card.key, card]));
    return cards.map((card) => byKey.get(card.key));
}
