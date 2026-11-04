/**
 * Utility to compress and downscale receipt images client-side before uploading.
 * Reduces 4-10MB mobile photos down to ~200-400KB in milliseconds,
 * drastically reducing network upload latency while keeping crisp text for OCR.
 */

export interface CompressReceiptOptions {
  maxWidth?: number;
  maxHeight?: number;
  quality?: number;
}

export async function compressReceiptImage(
  file: File,
  options: CompressReceiptOptions = {}
): Promise<File> {
  const { maxWidth = 1200, maxHeight = 2000, quality = 0.82 } = options;

  // If file is already small (e.g. <= 300KB), return as is without extra processing
  if (file.size <= 300 * 1024) {
    return file;
  }

  // Only compress supported image types
  if (!["image/jpeg", "image/png", "image/webp"].includes(file.type.toLowerCase())) {
    return file;
  }

  // Ensure running in browser environment
  if (typeof window === "undefined" || typeof document === "undefined") {
    return file;
  }

  return new Promise((resolve) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();

      img.onload = () => {
        const width = img.naturalWidth || img.width;
        const height = img.naturalHeight || img.height;

        // If image is already smaller than max dimensions and under 600KB, keep original
        if (width <= maxWidth && height <= maxHeight && file.size < 600 * 1024) {
          resolve(file);
          return;
        }

        // Calculate aspect-ratio preserved dimensions
        let scale = 1;
        if (width > maxWidth) {
          scale = maxWidth / width;
        }
        if (height * scale > maxHeight) {
          scale = Math.min(scale, maxHeight / height);
        }

        const targetWidth = Math.max(1, Math.round(width * scale));
        const targetHeight = Math.max(1, Math.round(height * scale));

        const canvas = document.createElement("canvas");
        canvas.width = targetWidth;
        canvas.height = targetHeight;

        const ctx = canvas.getContext("2d");
        if (!ctx) {
          resolve(file); // Fallback to original
          return;
        }

        // High quality image smoothing
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";
        ctx.drawImage(img, 0, 0, targetWidth, targetHeight);

        canvas.toBlob(
          (blob) => {
            if (!blob || blob.size >= file.size) {
              resolve(file); // If compression didn't help, use original
              return;
            }

            const cleanFileName = file.name.replace(/\.[^.]+$/, ".jpg");
            const compressedFile = new File([blob], cleanFileName, {
              type: "image/jpeg",
              lastModified: Date.now(),
            });
            resolve(compressedFile);
          },
          "image/jpeg",
          quality
        );
      };

      img.onerror = () => {
        resolve(file); // Fallback to original file on error
      };

      img.src = e.target?.result as string;
    };

    reader.onerror = () => {
      resolve(file); // Fallback to original file on error
    };

    reader.readAsDataURL(file);
  });
}
