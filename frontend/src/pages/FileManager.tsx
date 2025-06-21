import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Folder, File, Upload, Download, Trash2, Edit, Plus, ArrowUp } from 'lucide-react';
import toast from 'react-hot-toast';

interface FileItem {
  name: string;
  type: 'file' | 'directory';
  size: number;
  modified: string;
  path: string;
}

const FileManager: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [files, setFiles] = useState<FileItem[]>([]);
  const [currentPath, setCurrentPath] = useState('/');
  const [loading, setLoading] = useState(true);
  const [selectedFiles, setSelectedFiles] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    if (id) {
      fetchFiles();
    }
  }, [id, currentPath]);

  const fetchFiles = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/servers/${id}/files?path=${encodeURIComponent(currentPath)}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        setFiles(data.files || []);
      } else {
        toast.error('Failed to fetch files');
      }
    } catch (error) {
      toast.error('Network error');
    } finally {
      setLoading(false);
    }
  };

  const handleFileClick = (file: FileItem) => {
    if (file.type === 'directory') {
      setCurrentPath(file.path);
      setSelectedFiles([]);
    }
  };

  const handleFileSelect = (fileName: string) => {
    setSelectedFiles(prev => 
      prev.includes(fileName) 
        ? prev.filter(f => f !== fileName)
        : [...prev, fileName]
    );
  };

  const navigateUp = () => {
    const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/';
    setCurrentPath(parentPath);
    setSelectedFiles([]);
  };

  const deleteFiles = async () => {
    if (selectedFiles.length === 0) return;

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/servers/${id}/files/delete`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          files: selectedFiles.map(file => `${currentPath}${file}`)
        })
      });

      if (response.ok) {
        toast.success('Files deleted successfully');
        fetchFiles();
        setSelectedFiles([]);
      } else {
        toast.error('Failed to delete files');
      }
    } catch (error) {
      toast.error('Network error');
    }
  };

  const downloadFiles = async () => {
    if (selectedFiles.length === 0) return;

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/servers/${id}/files/download`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          files: selectedFiles.map(file => `${currentPath}${file}`)
        })
      });

      if (response.ok) {
        const blob = await response.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = selectedFiles.length === 1 ? selectedFiles[0] : 'files.zip';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        toast.success('Files downloaded successfully');
      } else {
        toast.error('Failed to download files');
      }
    } catch (error) {
      toast.error('Network error');
    }
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    setUploading(true);
    try {
      const token = localStorage.getItem('token');
      const formData = new FormData();
      
      for (let i = 0; i < files.length; i++) {
        formData.append('files', files[i]);
      }
      formData.append('path', currentPath);

      const response = await fetch(`/api/servers/${id}/files/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });

      if (response.ok) {
        toast.success('Files uploaded successfully');
        fetchFiles();
      } else {
        toast.error('Failed to upload files');
      }
    } catch (error) {
      toast.error('Network error');
    } finally {
      setUploading(false);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-4">
            <Link
              to={`/server/${id}`}
              className="text-gray-400 hover:text-white transition-colors"
            >
              <ArrowLeft className="h-6 w-6" />
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-white">File Manager</h1>
              <p className="text-gray-400">Manage server files and directories</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-3">
            <label className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors cursor-pointer">
              <Upload className="h-4 w-4" />
              <span>Upload</span>
              <input
                type="file"
                multiple
                onChange={handleFileUpload}
                className="hidden"
                disabled={uploading}
              />
            </label>
            
            {selectedFiles.length > 0 && (
              <>
                <button
                  onClick={downloadFiles}
                  className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
                >
                  <Download className="h-4 w-4" />
                  <span>Download ({selectedFiles.length})</span>
                </button>
                
                <button
                  onClick={deleteFiles}
                  className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
                >
                  <Trash2 className="h-4 w-4" />
                  <span>Delete ({selectedFiles.length})</span>
                </button>
              </>
            )}
          </div>
        </div>

        {/* Breadcrumb */}
        <div className="bg-gray-800 rounded-lg p-4 mb-6">
          <div className="flex items-center space-x-2 text-sm">
            <button
              onClick={navigateUp}
              disabled={currentPath === '/'}
              className="text-blue-500 hover:text-blue-400 disabled:text-gray-600 disabled:cursor-not-allowed"
            >
              <ArrowUp className="h-4 w-4" />
            </button>
            <span className="text-gray-400">Path:</span>
            <span className="text-white font-mono">{currentPath}</span>
          </div>
        </div>

        {/* Files List */}
        <div className="bg-gray-800 rounded-lg overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-700 bg-gray-700">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-medium text-gray-300">
                Files ({files.length})
              </h3>
              {selectedFiles.length > 0 && (
                <span className="text-sm text-blue-400">
                  {selectedFiles.length} selected
                </span>
              )}
            </div>
          </div>
          
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-700">
              <thead className="bg-gray-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={selectedFiles.length === files.length && files.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedFiles(files.map(f => f.name));
                        } else {
                          setSelectedFiles([]);
                        }
                      }}
                      className="rounded border-gray-600 text-blue-600 focus:ring-blue-500 bg-gray-800"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Size
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Modified
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-gray-800 divide-y divide-gray-700">
                {files.map((file) => (
                  <tr key={file.name} className="hover:bg-gray-700">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input
                        type="checkbox"
                        checked={selectedFiles.includes(file.name)}
                        onChange={() => handleFileSelect(file.name)}
                        className="rounded border-gray-600 text-blue-600 focus:ring-blue-500 bg-gray-800"
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div 
                        className="flex items-center space-x-3 cursor-pointer"
                        onClick={() => handleFileClick(file)}
                      >
                        {file.type === 'directory' ? (
                          <Folder className="h-5 w-5 text-blue-500" />
                        ) : (
                          <File className="h-5 w-5 text-gray-400" />
                        )}
                        <span className="text-white">{file.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                      {file.type === 'directory' ? '-' : formatFileSize(file.size)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                      {new Date(file.modified).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end space-x-2">
                        {file.type === 'file' && (
                          <button
                            onClick={() => {
                              setSelectedFiles([file.name]);
                              setTimeout(downloadFiles, 100);
                            }}
                            className="text-green-400 hover:text-green-300 p-1"
                            title="Download"
                          >
                            <Download className="h-4 w-4" />
                          </button>
                        )}
                        <button
                          onClick={() => {
                            setSelectedFiles([file.name]);
                            setTimeout(deleteFiles, 100);
                          }}
                          className="text-red-400 hover:text-red-300 p-1"
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            
            {files.length === 0 && (
              <div className="text-center py-12">
                <Folder className="h-16 w-16 text-gray-600 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-400 mb-2">No files found</h3>
                <p className="text-gray-500">This directory is empty</p>
              </div>
            )}
          </div>
        </div>

        {uploading && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-gray-800 p-6 rounded-lg">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-white">Uploading files...</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default FileManager; 