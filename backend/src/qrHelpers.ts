import crypto from "crypto";
import QRCode from "qrcode";
import {
  generateBlobSASQueryParameters,
  BlobSASPermissions,
  StorageSharedKeyCredential,
} from "@azure/storage-blob";

/* ============================================================
                    Request URL Extraction
   ============================================================ */
export class RequestUrlExtractor {
  static isValid(value: string): boolean {
    try {
      new URL(value);
      return true;
    } catch {
      return false;
    }
  }

  static async extract(request: any): Promise<string | null> {
    const body = (await request.json().catch(() => ({}))) as {
      url?: unknown;
    };

    return (
      request.query.get("url") ??
      (typeof body.url === "string" ? body.url : null)
    );
  }
}

/* ============================================================
                    QR Blob Access
   ============================================================ */
export class QrBlobAccess {
  static createQrImageBlobName(sourceUrl: string): string {
    return `${crypto.createHash("sha256").update(sourceUrl).digest("hex")}.png`;
  }

  static createSasExpiryDate(hoursFromNow: number): Date {
    const expiryDate = new Date();
    expiryDate.setHours(expiryDate.getHours() + hoursFromNow);
    return expiryDate;
  }

  static generateReadOnlySasToken(params: {
    containerName: string;
    blobName: string;
    expiresOn: Date;
    credentials: StorageSharedKeyCredential;
  }): string {
    return generateBlobSASQueryParameters(
      {
        containerName: params.containerName,
        blobName: params.blobName,
        permissions: BlobSASPermissions.parse("r"),
        expiresOn: params.expiresOn,
      },
      params.credentials,
    ).toString();
  }
}

/* ============================================================
                    QR Code Generator
   ============================================================ */
export class QrCodeGenerator {
  static generatePngBuffer(sourceUrl: string): Promise<Buffer> {
    return QRCode.toBuffer(sourceUrl, {
      type: "png",
      errorCorrectionLevel: "H",
      width: 256,
      margin: 1,
    });
  }
}
