// ============================================================================
// DASHBOARD ROUTER
// Aggregated stats for owner/renter dashboards
// ============================================================================

declare const require: any;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const express = require('express');
import { asyncHandler } from '../../shared/errors';
import { firestore } from '../../shared/auth';

const router = express.Router();

router.get('/owner', asyncHandler(async (req: any, res: any) => {
  const { ownerId } = req.query;

  const terrenosSnap = ownerId
    ? await firestore.collection('terrenos').where('ownerId', '==', ownerId).get()
    : await firestore.collection('terrenos').limit(20).get();

  const reservasSnap = ownerId
    ? await firestore.collection('reservas').where('ownerId', '==', ownerId).get()
    : await firestore.collection('reservas').limit(20).get();

  const properties = terrenosSnap.docs.map((doc: any) => ({
    id: doc.id,
    ...doc.data(),
  }));

  const renterIds = new Set<string>();
  reservasSnap.docs.forEach((doc: any) => {
    const data = doc.data() as { renterId?: string };
    if (data.renterId) renterIds.add(data.renterId);
  });

  res.json({
    stats: {
      propertiesCount: terrenosSnap.size,
      activeReservationsCount: reservasSnap.size,
      rentersCount: renterIds.size,
      viewsCount: 0,
    },
    properties,
    notifications: [],
    requestId: req.requestId,
  });
}));

router.get('/renter', asyncHandler(async (req: any, res: any) => {
  const { renterId } = req.query;

  const reservasSnap = renterId
    ? await firestore.collection('reservas').where('renterId', '==', renterId).get()
    : await firestore.collection('reservas').limit(20).get();

  const favoritesSnap = renterId
    ? await firestore.collection('favorites').where('userId', '==', renterId).get()
    : await firestore.collection('favorites').limit(20).get();

  const conversationsSnap = renterId
    ? await firestore.collection('conversaciones').where('participants', 'array-contains', renterId).get()
    : await firestore.collection('conversaciones').limit(20).get();

  const reservas = await Promise.all(reservasSnap.docs.map(async (doc: any) => {
    const data = doc.data() as { terrenoId?: string; status?: string; startDate?: number; endDate?: number };
    let terreno: any = null;

    if (data.terrenoId) {
      const terrenoDoc = await firestore.collection('terrenos').doc(data.terrenoId).get();
      terreno = terrenoDoc.exists ? terrenoDoc.data() : null;
    }

    const start = data.startDate ? new Date(data.startDate) : null;
    const end = data.endDate ? new Date(data.endDate) : null;
    const dates = start && end
      ? `${start.getDate()}/${start.getMonth() + 1} - ${end.getDate()}/${end.getMonth() + 1}`
      : '';

    const location = terreno?.location ? `${terreno.location.city ?? ''}, ${terreno.location.country ?? ''}`.trim() : '';
    const image = Array.isArray(terreno?.images) && terreno?.images.length
      ? terreno.images[0].url
      : '';

    return {
      listingId: data.terrenoId || '',
      title: terreno?.title ?? '',
      location,
      image,
      status: data.status ?? 'pendiente',
      dates,
      price: terreno?.priceMonthly ? `\$${terreno.priceMonthly}/mes` : '',
    };
  }));

  res.json({
    stats: {
      activeReservationsCount: reservasSnap.size,
      favoritesCount: favoritesSnap.size,
      messagesCount: conversationsSnap.size,
      hectares: 0,
    },
    reservas,
    notifications: [],
    requestId: req.requestId,
  });
}));

export default router;
