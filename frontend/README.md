# Folio frontend

React 19 + Vite, React Router, Axios, Lucide icons, Tiptap rich-text editing and DOMPurify. See `../backend/README.md` for the complete setup guide, architecture, account instructions and API documentation.

Run `powershell -ExecutionPolicy Bypass -File .\start.ps1` from this folder. Production build: `node .tools/package/bin/npm-cli.js run build`. The backend must run on port 8080; Vite proxies `/api` from port 5173.
