# Folio digital library

The project root has two application folders: `frontend` and `backend`. This workspace is already the requested Lib management folder (Windows folder names are case insensitive). Open the root folder in VS Code.

## Quick start on this Windows computer

The easiest VS Code option is **File → Open Workspace from File → `Library.code-workspace`** in the project root. Press **Ctrl+Shift+B** to run the default **Library: Start everything** task. It launches the backend/database and frontend in two dedicated terminals. If a service is already running, the script reuses it. Open http://127.0.0.1:5173 after both services are ready. Use **Terminal → Run Task → Library: Show admin login** to display the administrator credentials locally.

Java 21, Node.js and PostgreSQL 18 must be installed. The provided scripts install Maven and npm locally if needed. Open two PowerShell terminals in VS Code at the project root:

Terminal 1 — database and Spring Boot:

```powershell
powershell -ExecutionPolicy Bypass -File .\backend\start.ps1
```

Terminal 2 — React:

```powershell
powershell -ExecutionPolicy Bypass -File .\frontend\start.ps1
```

Open http://127.0.0.1:5173. Use this command to display your generated administrator login **locally**:

```powershell
powershell -ExecutionPolicy Bypass -File .\backend\show-login.ps1
```

Select ADMIN and sign in. Create customer accounts in User Management. Customers sign in using CUSTOMER. There is no public registration. Keep your administrator password private.

The setup creates its own PostgreSQL 18 instance on port **5433**, leaving your existing server on 5432 alone. Its database is `library_management`. Data and logs live in `%USERPROFILE%\FolioLibrary\PostgreSQL18` and `%USERPROFILE%\FolioLibrary\postgres.log`, outside this project. Generated credentials are protected with Windows DPAPI and only decrypt under the same Windows account. Start scripts reuse them on every run. Stop the Java and Vite processes with Ctrl+C. To stop the separate database:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe' stop -D "$env:USERPROFILE\FolioLibrary\PostgreSQL18" -m fast
```

## Using an existing PostgreSQL server instead

Create a database named `library_management` and a dedicated login with ownership of that database. Set `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `ADMIN_USERNAME` and `ADMIN_PASSWORD` in the backend terminal, then run `backend\mvnw.cmd spring-boot:run`. Do not run `start.ps1` for this option because it configures the isolated local instance. No database password is committed in source. `ADMIN_PASSWORD` must have at least 12 characters and is only used when creating the first admin. Changing it later does not reset an existing account.

## Workflow

1. Admin: Book Management → Add book. Upload a PNG or JPEG cover (5 MB, 4000 × 4000 maximum). Save the book as a draft.
2. Click its chapter icon. Add chapters using headings, paragraphs, emphasis, lists and quotes. Save each chapter; use arrows to reorder.
3. Publish the book. Customers immediately see it in their catalog. Unpublish to hide it again.
4. User Management → Add customer. Usernames allow 3–60 letters, numbers, dots, underscores and hyphens. Customer passwords need 10+ characters, at most 72 UTF-8 bytes. Email and username are unique.
5. Customers browse, search, filter and read. Each opened chapter saves their place in PostgreSQL. Returning opens the last saved chapter. Font size and theme apply to the current reader session.
6. Profile displays account details. Administrators edit customer details and reset passwords from User Management. Deactivated customers are rejected on their next request.

Prices are displayed in INR and do not enable purchases. Initial original short stories are seeded into the actual database, with complete short chapters. They remain editable like any other book. No external copyrighted books are included.

## Architecture and security

React components/pages → Axios REST calls → Spring controllers → transactional services → JPA repositories → PostgreSQL. Flyway owns the schema; Hibernate validates it at startup. Book/chapter deletion cascades to related progress. Unique chapter ordering is deferred to transaction commit for safe reordering. Images are validated/decoded, re-encoded as PNG, and stored as data URLs in the database `cover_image_path` field, so they persist with database backups.

Tomcat uses its supported NIO2 connector because the installed Java 21 selector's Unix-domain wakeup socket fails in this Windows execution environment. The start script also gives Java a short native temporary directory. Flyway is pinned to 11.20.2 for PostgreSQL 18 support.

Spring Security performs form authentication, BCrypt password verification and server-side role authorization. A selected login toggle never grants a role. HTTP-only SameSite session cookies hold only the session identifier. CSRF uses a server session token retrieved from `/api/auth/csrf` and sent in a header on every mutation. Login and logout refresh the token. Password hashes never enter response DTOs. Backend Jsoup sanitizes chapter HTML; DOMPurify also sanitizes reader output. Vite proxies `/api` to Spring Boot to keep cookies and CSRF same-origin.

Local HTTP uses `COOKIE_SECURE=false`; production must use HTTPS and `COOKIE_SECURE=true`. Deploy frontend and `/api` on one origin with a reverse proxy, use a non-superuser database login, protect credentials and backups, and add login rate limiting at the reverse proxy before exposing publicly. The local instance's initialization login owns its cluster and is intended for local development.

## API map

| Area | Endpoints |
|---|---|
| Authentication | GET `/api/auth/csrf`, POST `/api/auth/login` (form username/password), GET `/api/auth/me`, POST `/api/auth/logout` |
| Catalog | GET `/api/books`, `/api/books/{id}`, `/api/books/{id}/chapters` |
| Progress | GET/PUT `/api/books/{id}/progress` (`chapterId`) |
| Books (admin) | POST `/api/admin/books`, PUT/DELETE `/api/admin/books/{id}`, PUT `/{id}/status` (`published`), POST `/{id}/cover` (multipart `file`) |
| Chapters (admin) | POST `/api/admin/books/{id}/chapters`, PUT/DELETE `/{id}/chapters/{chapterId}`, PUT `/{id}/chapters/order` (all chapter IDs in order) |
| Customers (admin) | GET/POST `/api/admin/customers`, PUT/DELETE `/{id}`, PUT `/{id}/active`, PUT `/{id}/password` |

Unauthenticated requests return 401, forbidden requests 403, missing records 404, duplicate values 409, invalid data 400, creations 201, deletions 204. Customers receive only published books and cannot retrieve draft content by ID.

## Checks and troubleshooting

```powershell
.\backend\mvnw.cmd test
cd frontend
node .tools/package/bin/npm-cli.js run build
```

If ports 5173, 8080 or 5433 are occupied, stop the conflicting application. If startup fails, inspect the terminal and PostgreSQL log. A 403 after a long idle period can be resolved by refreshing and signing in again. External Google Fonts are decorative; system fonts work offline. Internet is needed for the first dependency installation. Never delete the PostgreSQL data directory to fix a startup error; it contains your saved library.

Live integration checks (with the backend running): `powershell -ExecutionPolicy Bypass -File .\backend\verify.ps1`. This creates and deletes disposable test records. To repeat the restart test, run with `-PreparePersistence`, restart the backend, then run with `-CheckPersistence`.
