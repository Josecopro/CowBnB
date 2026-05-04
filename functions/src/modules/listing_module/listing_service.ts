import { ListingRepository } from "./listing_repository";
import { ListingData } from "./listing_types";

export class ListingService {
  private repository: ListingRepository;

  constructor() {
    this.repository = new ListingRepository();
  }

  async createListing(
    uid: string, 
    data: { title: string; description: string; size: number; price: number; features: string[]; }, 
    imagesBase64: { base64: string; ext: string }[]
  ): Promise<string> {
    const imageUrls: string[] = [];

    for (const img of imagesBase64) {
      const url = await this.repository.uploadImageBase64(img.base64, img.ext);
      imageUrls.push(url);
    }

    const listing: ListingData = {
      ...data,
      ownerId: uid,
      images: imageUrls,
      createdAt: new Date().toISOString(),
    };

    return this.repository.createListing(listing);
  }

  async getAllListings() {
    return this.repository.getAllListings();
  }

  async getListingsByOwner(uid: string) {
    return this.repository.getListingsByOwner(uid);
  }
}
