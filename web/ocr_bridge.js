// Loads OCR code only when the user selects an image. Recognition runs locally
// in the browser; Tesseract and its language data are fetched from the CDN.
globalThis.smartWmsOcr = {
  async recognize(file, onProgress) {
    const { createWorker } = await import(
      'https://cdn.jsdelivr.net/npm/tesseract.js@7.0.0/dist/tesseract.esm.min.js'
    );
    const worker = await createWorker('vie+eng', undefined, {
      logger: ({ status, progress }) => onProgress(status, progress),
    });

    try {
      // Phone photos can be very large. Downscale before OCR to keep the
      // browser's memory use manageable while retaining label readability.
      let image = file;
      try {
        const bitmap = await createImageBitmap(file);
        const scale = Math.min(1, 2200 / Math.max(bitmap.width, bitmap.height));
        if (scale < 1) {
          const canvas = document.createElement('canvas');
          canvas.width = Math.round(bitmap.width * scale);
          canvas.height = Math.round(bitmap.height * scale);
          canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
          image = await new Promise((resolve) =>
            canvas.toBlob((blob) => resolve(blob || file), 'image/jpeg', 0.92)
          );
        }
        bitmap.close();
      } catch (_) {
        // Keep the original image for browsers without bitmap/canvas support.
      }

      const { data } = await worker.recognize(image);
      return data.text;
    } finally {
      await worker.terminate();
    }
  },
};
