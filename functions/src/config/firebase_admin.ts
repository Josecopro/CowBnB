import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

if (process.env.APP_AUTH_EMULATOR_HOST) {
	process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.APP_AUTH_EMULATOR_HOST;
}

if (process.env.APP_FIRESTORE_EMULATOR_HOST) {
	process.env.FIRESTORE_EMULATOR_HOST = process.env.APP_FIRESTORE_EMULATOR_HOST;
}

const app = getApps().length > 0 ? getApps()[0] : initializeApp();

const auth = getAuth(app);
const db = getFirestore(app);

export { auth, db };
