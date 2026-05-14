import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

// The Firebase emulator suite auto-injects FIREBASE_AUTH_EMULATOR_HOST, FIRESTORE_EMULATOR_HOST, etc.
// These can also come from .env or be hardcoded for local dev.
const isEmulated = process.env.FUNCTIONS_EMULATOR === "true";
if (isEmulated) {
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";
  if (!process.env.FIRESTORE_EMULATOR_HOST) process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) process.env.FIREBASE_STORAGE_EMULATOR_HOST = "localhost:9199";
}

const app = getApps().length > 0 ? getApps()[0] : initializeApp({
    storageBucket: "demo-cowbnb.appspot.com"
});

const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

export { auth, db, storage };
