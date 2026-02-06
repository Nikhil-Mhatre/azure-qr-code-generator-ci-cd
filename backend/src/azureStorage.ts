import {
  BlobServiceClient,
  StorageSharedKeyCredential,
} from "@azure/storage-blob";

/* ============================================================
                    Azure Storage Configuration
   ============================================================ */
export class AzureStorageConfig {
  static readonly QR_CODE_CONTAINER = "images";

  static readonly QR_SAS_EXPIRY_HOURS = Number(
    process.env.QR_SAS_EXPIRY_HOURS ?? 1,
  );

  static get accountName(): string {
    return process.env.STORAGE_ACCOUNT_NAME ?? "";
  }

  static get accountKey(): string {
    return process.env.STORAGE_ACCOUNT_KEY ?? "";
  }

  static get connectionString(): string {
    return process.env.STORAGE_CONN_STRING ?? "";
  }

  static validate(): void {
    if (!this.connectionString || !this.accountName || !this.accountKey) {
      throw new Error("Azure Storage is not configured");
    }

    if (this.QR_SAS_EXPIRY_HOURS <= 0) {
      throw new Error("QR_SAS_EXPIRY_HOURS must be > 0");
    }
  }
}

/* ============================================================
                    Lazy Storage Factory
   ============================================================ */
let cachedClient: {
  blobServiceClient: BlobServiceClient;
  credentials: StorageSharedKeyCredential;
} | null = null;

export function getAzureStorage() {
  if (cachedClient) return cachedClient;

  AzureStorageConfig.validate();

  const credentials = new StorageSharedKeyCredential(
    AzureStorageConfig.accountName,
    AzureStorageConfig.accountKey,
  );

  const blobServiceClient = BlobServiceClient.fromConnectionString(
    AzureStorageConfig.connectionString,
  );

  cachedClient = { blobServiceClient, credentials };
  return cachedClient;
}
