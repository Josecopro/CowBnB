import { firestore } from './auth';
import { createError } from './errors';
import { logInfo, logError } from './logging';
import { getCurrentRequestId } from './request-context';

// ============================================================================
// FIRESTORE CRUD HELPERS
// Admin SDK operations with error handling
// ============================================================================

// Collection names
export const COLLECTIONS = {
  USERS: 'users',
  TERRENOS: 'terrenos',
  RESERVAS: 'reservas',
  PAGOS: 'pagos',
  CONVERSACIONES: 'conversaciones',
  REVIEWS: 'reviews',
  ACTION_TOKENS: 'action_tokens',
  NDVI_CHECKS: 'ndvi_checks',
} as const;

// Generic CRUD operations
export class FirestoreService {
  // Create document
  static async create<T extends { id?: string }>(
    collection: string,
    data: Omit<T, 'id'>,
    id?: string
  ): Promise<T> {
    try {
      const docRef = id
        ? firestore.collection(collection).doc(id)
        : firestore.collection(collection).doc();

      const docData = {
        ...data,
        id: docRef.id,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      await docRef.set(docData);

      const requestId = getCurrentRequestId();
      logInfo('Document created', { collection, id: docRef.id }, requestId);

      return docData as unknown as T;
    } catch (error) {
      const requestId = getCurrentRequestId();
      logError('Failed to create document', error as Error, { collection }, requestId);
      throw createError('INTERNAL_ERROR', 'Failed to create document');
    }
  }

  // Get document by ID
  static async get<T>(collection: string, id: string): Promise<T | null> {
    try {
      const doc = await firestore.collection(collection).doc(id).get();

      if (!doc.exists) {
        return null;
      }

      const requestId = getCurrentRequestId();
      logInfo('Document retrieved', { collection, id }, requestId);

      return { id: doc.id, ...doc.data() } as T;
    } catch (error) {
      const requestId = getCurrentRequestId();
      logError('Failed to get document', error as Error, { collection, id }, requestId);
      throw createError('INTERNAL_ERROR', 'Failed to retrieve document');
    }
  }

  // Update document
  static async update<T>(
    collection: string,
    id: string,
    updates: Partial<Omit<T, 'id' | 'createdAt'>>
  ): Promise<T> {
    try {
      const updateData = {
        ...updates,
        updatedAt: Date.now(),
      };

      await firestore.collection(collection).doc(id).update(updateData);

      const requestId = getCurrentRequestId();
      logInfo('Document updated', { collection, id }, requestId);

      // Return updated document
      return await this.get<T>(collection, id) as T;
    } catch (error) {
      const requestId = getCurrentRequestId();
      logError('Failed to update document', error as Error, { collection, id }, requestId);
      throw createError('INTERNAL_ERROR', 'Failed to update document');
    }
  }

  // Delete document (soft delete by setting status)
  static async delete(collection: string, id: string): Promise<void> {
    try {
      // For collections with status, set to inactive
      if (collection === COLLECTIONS.TERRENOS) {
        await this.update(collection, id, { status: 'inactivo' } as any);
      } else {
        await firestore.collection(collection).doc(id).delete();
      }

      const requestId = getCurrentRequestId();
      logInfo('Document deleted', { collection, id }, requestId);
    } catch (error) {
      const requestId = getCurrentRequestId();
      logError('Failed to delete document', error as Error, { collection, id }, requestId);
      throw createError('INTERNAL_ERROR', 'Failed to delete document');
    }
  }

  // Query with filters
  static async query<T>(
    collection: string,
    filters: Array<{
      field: string;
      operator: FirebaseFirestore.WhereFilterOp;
      value: any;
    }> = [],
    orderBy?: { field: string; direction: 'asc' | 'desc' },
    limit?: number
  ): Promise<T[]> {
    try {
      let query: FirebaseFirestore.Query = firestore.collection(collection);

      // Apply filters
      filters.forEach(({ field, operator, value }) => {
        query = query.where(field, operator, value);
      });

      // Apply ordering
      if (orderBy) {
        query = query.orderBy(orderBy.field, orderBy.direction);
      }

      // Apply limit
      if (limit) {
        query = query.limit(limit);
      }

      const snapshot = await query.get();
      const results = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as T[];

      const requestId = getCurrentRequestId();
      logInfo('Query executed', {
        collection,
        filtersCount: filters.length,
        resultsCount: results.length,
      }, requestId);

      return results;
    } catch (error) {
      const requestId = getCurrentRequestId();
      logError('Query failed', error as Error, { collection }, requestId);
      throw createError('INTERNAL_ERROR', 'Query failed');
    }
  }

  // Transaction wrapper
  static async runTransaction<T>(
    updateFunction: (transaction: FirebaseFirestore.Transaction) => Promise<T>
  ): Promise<T> {
    try {
      const result = await firestore.runTransaction(updateFunction);

      const requestId = getCurrentRequestId();
      logInfo('Transaction completed', {}, requestId);

      return result;
    } catch (error) {
      const requestId = getCurrentRequestId();
      logError('Transaction failed', error as Error, {}, requestId);
      throw createError('INTERNAL_ERROR', 'Transaction failed');
    }
  }
}

// Specific service methods
export class UserService extends FirestoreService {
  static async getByEmail(email: string) {
    return this.query(COLLECTIONS.USERS, [
      { field: 'email', operator: '==', value: email },
    ]);
  }

  static async getByUid(uid: string) {
    return this.get(COLLECTIONS.USERS, uid);
  }
}

export class TerrenoService extends FirestoreService {
  static async getDisponibles(limit = 50) {
    return this.query(COLLECTIONS.TERRENOS, [
      { field: 'status', operator: '==', value: 'disponible' },
    ], { field: 'createdAt', direction: 'desc' }, limit);
  }

  static async getByOwner(ownerId: string) {
    return this.query(COLLECTIONS.TERRENOS, [
      { field: 'ownerId', operator: '==', value: ownerId },
    ]);
  }
}

export class ReservaService extends FirestoreService {
  static async getByRenter(renterId: string) {
    return this.query(COLLECTIONS.RESERVAS, [
      { field: 'renterId', operator: '==', value: renterId },
    ]);
  }

  static async getByOwner(ownerId: string) {
    return this.query(COLLECTIONS.RESERVAS, [
      { field: 'ownerId', operator: '==', value: ownerId },
    ]);
  }
}