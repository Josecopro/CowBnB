// ============================================================================
// FAVORITES ROUTER
// ============================================================================

declare const require: any;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const express = require('express');
import { asyncHandler } from '../../shared/errors';
import { firestore } from '../../shared/auth';

const router = express.Router();

router.get('/', asyncHandler(async (req: any, res: any) => {
  const { userId } = req.query;
  let query: any = firestore.collection('favorites');

  if (userId) {
    query = query.where('userId', '==', userId);
  }

  const snapshot = await query.get();

  const items = await Promise.all(snapshot.docs.map(async (doc: any) => {
    const data = doc.data() as { terrenoId?: string };
    let terreno: any = null;

    if (data.terrenoId) {
      const terrenoDoc = await firestore.collection('terrenos').doc(data.terrenoId).get();
      terreno = terrenoDoc.exists ? terrenoDoc.data() : null;
    }

    const location = terreno?.location ? `${terreno.location.city ?? ''}, ${terreno.location.country ?? ''}`.trim() : '';
    const image = Array.isArray(terreno?.images) && terreno?.images.length
      ? terreno.images[0].url
      : '';

    return {
      id: data.terrenoId || doc.id,
      title: terreno?.title ?? '',
      location,
      price: terreno?.priceMonthly ? `\$${terreno.priceMonthly}/mes` : '',
      image,
      hectares: terreno?.sizeHectares ? `${terreno.sizeHectares} ha` : '',
    };
  }));

  res.json({ items, requestId: req.requestId });
}));

export default router;
