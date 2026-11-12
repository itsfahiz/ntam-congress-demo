import { sessions, speakers } from '../../data/catalog.js';
import { getPool } from '../db/pool.js';
import { publicError } from '../types/http.js';

export type SavedItemType = 'session' | 'resource' | 'speaker';
export type SavedItem = { itemType: SavedItemType; itemId: string; createdAt: string };

export type SavedStore = {
  list(userId: string): Promise<SavedItem[]>;
  save(userId: string, type: SavedItemType, id: string): Promise<void>;
  remove(userId: string, type: SavedItemType, id: string): Promise<void>;
};

const sessionIds = new Set(sessions.map((session) => session.id));
// These four IDs must stay aligned with CongressCatalog.resources in Flutter.
const resourceIds = new Set(['programme', 'pediatric-guide', 'keynote-slides', 'session-recap']);
const speakerIds = new Set(speakers.filter((speaker) => speaker.listed).map((speaker) => speaker.id));
let storeOverride: SavedStore | null = null;

export function setSavedStoreOverride(value: SavedStore | null) {
  storeOverride = value;
}

export function assertCatalogItem(type: SavedItemType, id: string) {
  const ids = type === 'session' ? sessionIds : type === 'resource' ? resourceIds : speakerIds;
  if (!ids.has(id)) {
    throw publicError(404, 'This congress item is not available.', 'unknown_item');
  }
}

type SavedRow = {
  item_type: SavedItemType;
  item_id: string;
  created_at: Date | string;
};

const postgresStore: SavedStore = {
  async list(userId) {
    const { rows } = await getPool().query<SavedRow>(
      `SELECT item_type, item_id, created_at
       FROM public.saved_items
       WHERE user_id = $1
       ORDER BY created_at DESC, item_type ASC, item_id ASC`,
      [userId],
    );
    return rows.map((row) => ({
      itemType: row.item_type,
      itemId: row.item_id,
      createdAt: new Date(row.created_at).toISOString(),
    }));
  },
  async save(userId, type, id) {
    await getPool().query(
      `INSERT INTO public.saved_items (user_id, item_type, item_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, item_type, item_id) DO NOTHING`,
      [userId, type, id],
    );
  },
  async remove(userId, type, id) {
    await getPool().query(
      `DELETE FROM public.saved_items
       WHERE user_id = $1 AND item_type = $2 AND item_id = $3`,
      [userId, type, id],
    );
  },
};

const store = () => storeOverride ?? postgresStore;

export async function listSavedItems(userId: string) {
  return store().list(userId);
}

export async function saveItem(userId: string, type: SavedItemType, id: string) {
  assertCatalogItem(type, id);
  await store().save(userId, type, id);
}

export async function removeItem(userId: string, type: SavedItemType, id: string) {
  assertCatalogItem(type, id);
  await store().remove(userId, type, id);
}

/** In-memory test fixture only; production always uses PostgreSQL. */
export function createMemorySavedStore(): SavedStore {
  const rows = new Map<string, SavedItem>();
  const key = (userId: string, type: SavedItemType, id: string) =>
    [userId, type, id].join(':');
  return {
    async list(userId) {
      return [...rows.entries()]
        .filter(([savedKey]) => savedKey.startsWith(userId + ':'))
        .map(([, item]) => item)
        .sort((a, b) =>
          b.createdAt.localeCompare(a.createdAt) ||
          a.itemType.localeCompare(b.itemType) ||
          a.itemId.localeCompare(b.itemId),
        );
    },
    async save(userId, type, id) {
      const rowKey = key(userId, type, id);
      if (!rows.has(rowKey)) {
        rows.set(rowKey, {
          itemType: type,
          itemId: id,
          createdAt: new Date().toISOString(),
        });
      }
    },
    async remove(userId, type, id) {
      rows.delete(key(userId, type, id));
    },
  };
}
