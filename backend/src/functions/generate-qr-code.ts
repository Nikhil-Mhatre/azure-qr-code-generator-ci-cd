import { HttpRequest, HttpResponseInit, app } from "@azure/functions";
import { getAzureStorage, AzureStorageConfig } from "../azureStorage";
import {
  RequestUrlExtractor,
  QrBlobAccess,
  QrCodeGenerator,
} from "../qrHelpers";

export async function generateQr(
  request: HttpRequest,
): Promise<HttpResponseInit> {
  try {
    const sourceUrl = await RequestUrlExtractor.extract(request);
    if (!sourceUrl || !RequestUrlExtractor.isValid(sourceUrl)) {
      return { status: 400, jsonBody: { message: "Invalid URL" } };
    }

    const qrImageBuffer = await QrCodeGenerator.generatePngBuffer(sourceUrl);

    // ✅ Storage initialized ONLY HERE
    const { blobServiceClient, credentials } = getAzureStorage();

    const containerClient = blobServiceClient.getContainerClient(
      AzureStorageConfig.QR_CODE_CONTAINER,
    );

    const blobName = QrBlobAccess.createQrImageBlobName(sourceUrl);
    const blobClient = containerClient.getBlockBlobClient(blobName);

    await blobClient.uploadData(qrImageBuffer, {
      blobHTTPHeaders: { blobContentType: "image/png" },
    });

    const expiry = QrBlobAccess.createSasExpiryDate(
      AzureStorageConfig.QR_SAS_EXPIRY_HOURS,
    );

    const sas = QrBlobAccess.generateReadOnlySasToken({
      containerName: AzureStorageConfig.QR_CODE_CONTAINER,
      blobName,
      expiresOn: expiry,
      credentials,
    });

    return {
      status: 200,
      jsonBody: {
        qrCodeUrl: `${blobClient.url}?${sas}`,
        expiry: expiry.toISOString(),
      },
    };
  } catch {
    return { status: 500, jsonBody: { message: "Failed to generate QR" } };
  }
}


app.http("generate-qr", {
  methods: ["POST"],
  route: "generate-qr",
  authLevel: "anonymous",
  handler: generateQr,
});