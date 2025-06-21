import { Router } from 'express';
import fs from 'fs';
import path from 'path';
import multer from 'multer';
import { authenticateJWT } from '../middleware/auth';

const router = Router();
const upload = multer({ dest: '/tmp' }); // Adjust as needed

const SERVERS_ROOT = '/srv/game_servers'; // Change to your server files root

router.use(authenticateJWT);

// List files/folders
router.get('/:serverId/*', (req, res) => {
  const { serverId } = req.params;
  const relPath = req.params[0] || '';
  const absPath = path.join(SERVERS_ROOT, serverId, relPath);
  fs.readdir(absPath, { withFileTypes: true }, (err, files) => {
    if (err) return res.status(404).json({ error: 'Not found' });
    res.json(files.map(f => ({
      name: f.name,
      isDir: f.isDirectory(),
    })));
  });
});

// Download file
router.get('/:serverId/download/*', (req, res) => {
  const { serverId } = req.params;
  const relPath = req.params[0] || '';
  const absPath = path.join(SERVERS_ROOT, serverId, relPath);
  res.download(absPath);
});

// Upload file
router.post('/:serverId/upload/*', upload.single('file'), (req, res) => {
  const { serverId } = req.params;
  const relPath = req.params[0] || '';
  const absPath = path.join(SERVERS_ROOT, serverId, relPath, req.file.originalname);
  fs.rename(req.file.path, absPath, err => {
    if (err) return res.status(500).json({ error: 'Upload failed' });
    res.json({ status: 'ok' });
  });
});

// Edit file (text)
router.post('/:serverId/edit/*', (req, res) => {
  const { serverId } = req.params;
  const relPath = req.params[0] || '';
  const absPath = path.join(SERVERS_ROOT, serverId, relPath);
  fs.writeFile(absPath, req.body.content, err => {
    if (err) return res.status(500).json({ error: 'Edit failed' });
    res.json({ status: 'ok' });
  });
});

// Delete file/folder
router.delete('/:serverId/*', (req, res) => {
  const { serverId } = req.params;
  const relPath = req.params[0] || '';
  const absPath = path.join(SERVERS_ROOT, serverId, relPath);
  fs.rm(absPath, { recursive: true, force: true }, err => {
    if (err) return res.status(500).json({ error: 'Delete failed' });
    res.json({ status: 'ok' });
  });
});

export default router; 