// ============================================================================
// NOTIFICATIONS ROUTER
// ============================================================================

declare const require: any;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const express = require('express');
import { asyncHandler } from '../../shared/errors';
import { firestore } from '../../shared/auth';

const router = express.Router();

router.get('/', asyncHandler(async (req: any, res: any) => {
  const { userId } = req.query;
  let query: any = firestore.collection('notifications');

  if (userId) {
    query = query.where('userId', '==', userId);
  }

  const snapshot = await query.get();
  const items = snapshot.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));

  res.json({ items, requestId: req.requestId });
}));

export default router;
