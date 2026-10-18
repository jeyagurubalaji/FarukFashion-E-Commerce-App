exports.uploadImages = (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files uploaded',
      });
    }

    const base =
      process.env.PUBLIC_BASE_URL ||
      `${req.protocol}://${req.get('host')}`;

    const urls = req.files.map((f) => {
      // Cloudinary (multer-storage-cloudinary sets path = secure_url)
      if (f.path && String(f.path).startsWith('http')) {
        return f.path;
      }
      if (f.secure_url) return f.secure_url;
      // Local fallback
      return `${base}/api/uploads/${f.filename}`;
    });

    res.status(201).json({
      success: true,
      message: 'Upload successful',
      data: {
        urls,
        files: req.files.map((f, i) => ({
          filename: f.filename || f.public_id || `file-${i}`,
          originalName: f.originalname,
          size: f.size,
          url: urls[i],
        })),
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};