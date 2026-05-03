import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

if (process.env.APP_AUTH_EMULATOR_HOST) {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.APP_AUTH_EMULATOR_HOST;
}
if (process.env.APP_FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = process.env.APP_FIRESTORE_EMULATOR_HOST;
}
if (process.env.APP_STORAGE_EMULATOR_HOST) {
    process.env.FIREBASE_STORAGE_EMULATOR_HOST = process.env.APP_STORAGE_EMULATOR_HOST;
}

const app = getApps().length > 0 ? getApps()[0] : initializeApp({
    storageBucket: "demo-cowbnb.appspot.com"
});

const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

export { auth, db, storage };
