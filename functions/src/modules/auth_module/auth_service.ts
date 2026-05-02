import { auth_repository } from "./auth_repository";
import { UpsertProfilePayload } from "./auth_types";

export const auth_service = {
  async get_profile(uid: string) {
    return auth_repository.get_profile(uid);
  },

  async upsert_profile(uid: string, payload: UpsertProfilePayload, email: string | null) {
    return auth_repository.upsert_profile(uid, payload, email);
  },
};
