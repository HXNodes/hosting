import { useEffect, useState, useRef } from 'react';

export default function FileManager({ serverId }: { serverId: string }) {
  const [path, setPath] = useState('');
  const [files, setFiles] = useState<any[]>([]);
  const [editing, setEditing] = useState<string | null>(null);
  const [editContent, setEditContent] = useState('');
  const fileInput = useRef<HTMLInputElement>(null);
  const token = localStorage.getItem('token');

  const fetchFiles = async (subpath = '') => {
    const res = await fetch(`/api/files/${serverId}/${subpath}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    setPath(subpath);
    setFiles(await res.json());
  };

  useEffect(() => { fetchFiles(); }, [serverId]);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.length) return;
    const formData = new FormData();
    formData.append('file', e.target.files[0]);
    await fetch(`/api/files/${serverId}/upload/${path}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: formData
    });
    fetchFiles(path);
  };

  const handleDownload = (name: string) => {
    window.open(`/api/files/${serverId}/download/${path ? path + '/' : ''}${name}`);
  };

  const handleDelete = async (name: string) => {
    await fetch(`/api/files/${serverId}/${path ? path + '/' : ''}${name}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    fetchFiles(path);
  };

  const handleEdit = async (name: string) => {
    const res = await fetch(`/api/files/${serverId}/${path ? path + '/' : ''}${name}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    setEditContent(await res.text());
    setEditing(name);
  };

  const saveEdit = async () => {
    await fetch(`/api/files/${serverId}/edit/${path ? path + '/' : ''}${editing}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ content: editContent })
    });
    setEditing(null);
    fetchFiles(path);
  };

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-2">File Manager</h2>
      <input type="file" ref={fileInput} style={{ display: 'none' }} onChange={handleUpload} />
      <button className="mb-2 bg-blue-600 text-white px-3 py-1 rounded" onClick={() => fileInput.current?.click()}>Upload</button>
      <ul>
        {files.map(f => (
          <li key={f.name} className="flex items-center gap-2">
            {f.isDir ? (
              <button className="text-blue-600" onClick={() => fetchFiles(path ? path + '/' + f.name : f.name)}>{f.name}/</button>
            ) : (
              <span>{f.name}</span>
            )}
            {!f.isDir && <>
              <button onClick={() => handleDownload(f.name)} className="text-green-600">Download</button>
              <button onClick={() => handleEdit(f.name)} className="text-yellow-600">Edit</button>
            </>}
            <button onClick={() => handleDelete(f.name)} className="text-red-600">Delete</button>
          </li>
        ))}
      </ul>
      {editing && (
        <div className="mt-4">
          <h3 className="font-bold">Editing: {editing}</h3>
          <textarea className="w-full h-40 border p-2" value={editContent} onChange={e => setEditContent(e.target.value)} />
          <button className="bg-blue-600 text-white px-3 py-1 rounded mt-2" onClick={saveEdit}>Save</button>
          <button className="ml-2" onClick={() => setEditing(null)}>Cancel</button>
        </div>
      )}
    </div>
  );
} 