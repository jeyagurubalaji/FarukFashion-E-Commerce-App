const multer = require('multer');
const path = require('path');
const fs = require('fs');
const os = require('os');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

const hasCloudinary =
  !!(process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET);

if (hasCloudinary) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
}

function localDir() {
  const isVercel = process.env.VERCEL === '1' || !!process.env.NOW_REGION;
  return isVercel
    ? path.join(os.tmpdir(), 'faruk-uploads')
    : path.join(__dirname, '../../uploads');
}

const storage = hasCloudinary
  ? new CloudinaryStorage({
      cloudinary,
      params: {
        folder: 'faruk-fashion',
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        transformation: [{ width: 1200, crop: 'limit' }],
      },
    })
  : multer.diskStorage({
      destination: (_req, _file, cb) => {
        try {
          const dir = localDir();
          fs.mkdirSync(dir, { recursive: true });
          cb(null, dir);
        } catch (e) {
          cb(e);
        }
      },
      filename: (_req, file, cb) => {
        const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        let ext = path.extname(file.originalname || '').toLowerCase();
        if (!ext || ext === '.') {
          const mime = (file.mimetype || '').toLowerCase();
          if (mime.includes('png')) ext = '.png';
          else if (mime.includes('webp')) ext = '.webp';
          else if (mime.includes('gif')) ext = '.gif';
          else ext = '.jpg';
        }
        cb(null, `product-${unique}${ext}`);
      },
    });

const fileFilter = (_req, file, cb) => {
  const name = (file.originalname || '').toLowerCase();
  const mime = (file.mimetype || '').toLowerCase();
  const ext = path.extname(name);
  const extOk = ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext);
  if (
    extOk ||
    mime.startsWith('image/') ||
    mime === 'application/octet-stream' ||
    mime === ''
  ) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed (jpg, png, webp, gif)'));
  }
};

module.exports = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter,
});