import assert from 'node:assert/strict';
import test from 'node:test';
import { arrangePassports, clampPassportPosition, openPassport, passportKey } from './passports.js';

const node = (id, pinned = false) => ({ type: 'node', nodeId: id, data: { id }, pinned });

test('opening distinct passports preserves earlier cards; reopening focuses without duplicates', () => {
    const first = { ...node('one', true), position: { x: 20, y: 40 } };
    let cards = openPassport([first], node('two'));
    assert.equal(cards.length, 2);
    assert.equal(cards[0], first);
    cards = openPassport(cards, node('one'));
    assert.equal(cards.length, 2);
    assert.equal(cards[1].pinned, true);
    assert.deepEqual(cards[1].position, first.position);
    assert.deepEqual(cards.filter((card) => passportKey(card) !== 'node:one'), [node('two')]);
});

test('cards with the same anchor occupy separate visible areas when room is available', () => {
    const cards = arrangePassports(['one', 'two', 'three'].map((key) => ({ key, x: 40, y: 100, width: 300, height: 380 })),
        { left: 12, top: 80, right: 1200, bottom: 880 });
    for (const card of cards) {
        assert.ok(card.x >= 12 && card.x + card.width <= 1200);
        assert.ok(card.y >= 80 && card.y + card.height <= 880);
        assert.equal(card.overlap, 0);
    }
});

test('small viewports retain all cards within the available area even when overlap is unavoidable', () => {
    const cards = arrangePassports(['one', 'two'].map((key) => ({ key, x: 900, y: -30, width: 300, height: 340 })),
        { left: 12, top: 80, right: 330, bottom: 440 });
    assert.equal(cards.length, 2);
    for (const card of cards) {
        assert.ok(card.x >= 12 && card.x + card.width <= 330);
        assert.ok(card.y >= 80 && card.y + card.height <= 440);
    }
});

test('detached passports keep their positions and reserve space before anchored cards', () => {
    const cards = arrangePassports([
        { key: 'anchored', x: 20, y: 100, width: 280, height: 330 },
        { key: 'detached', x: 20, y: 100, width: 280, height: 330, fixed: true },
    ], { left: 12, top: 80, right: 1200, bottom: 880 });
    assert.deepEqual(cards.map(({ key }) => key), ['anchored', 'detached']);
    assert.equal(cards[1].x, 20);
    assert.equal(cards[1].y, 100);
    assert.equal(cards[0].overlap, 0);
    assert.notEqual(cards[0].x, cards[1].x);
});

test('dragged cards stay below the toolbar and inside a resized viewport', () => {
    const bounds = { left: 12, top: 124, right: 788, bottom: 588 };
    assert.deepEqual(clampPassportPosition({ x: -100, y: -100, width: 280, height: 330 }, bounds), { x: 12, y: 124 });
    assert.deepEqual(clampPassportPosition({ x: 1000, y: 1000, width: 280, height: 330 }, bounds), { x: 508, y: 258 });
});

test('layout preserves parked windows and keeps an exposed header after resize', () => {
    const card = { key: 'parked', x: 680, y: 500, width: 280, height: 330, fixed: true };
    const [parked] = arrangePassports([card], { left: 12, top: 80, right: 788, bottom: 588 });
    const [resized] = arrangePassports([card], { left: 12, top: 80, right: 588, bottom: 488 });
    assert.deepEqual([parked.x, parked.y], [680, 500]);
    assert.deepEqual([resized.x, resized.y], [516, 452]);
});

test('reopening a detached passport preserves its manually chosen position', () => {
    const detached = { ...node('one', true), detachedPosition: { x: 500, y: 200 } };
    assert.deepEqual(openPassport([detached], node('one'))[0].detachedPosition, detached.detachedPosition);
});

test('characteristics align to the visible passport and switch sides when it moves', () => {
    const bounds = { left: 12, top: 80, right: 1200, bottom: 880 };
    const details = { key: 'characteristics:one', anchorKey: 'node:one', width: 560, height: 360 };
    const parent = { key: 'node:one', x: 100, y: 240, width: 280, height: 300, fixed: true };
    const [right] = arrangePassports([details, parent], bounds);
    const [left] = arrangePassports([details, { ...parent, x: 850 }], bounds);
    assert.deepEqual([right.x, right.y], [392, 210]);
    assert.deepEqual([left.x, left.y], [278, 210]);
});

test('characteristics fall back to the node when its passport is hidden or detached', () => {
    const details = {
        key: 'characteristics:one', anchorKey: 'node:one', width: 560, height: 360,
        fallbackAnchor: { x: 150, y: 380, width: 120, height: 50 },
    };
    const parent = { key: 'node:one', x: 850, y: 200, width: 280, height: 300, fixed: true, detached: true };
    const bounds = { left: 12, top: 80, right: 1200, bottom: 880 };
    const [withoutParent] = arrangePassports([details], bounds);
    const [withDetachedParent] = arrangePassports([details, parent], bounds);
    assert.deepEqual([withoutParent.x, withoutParent.y], [282, 225]);
    assert.deepEqual(withDetachedParent, withoutParent);
});
