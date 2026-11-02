# Verification on this computer

Validated against Java 21 and a real PostgreSQL 18 server on port 5433:

- Maven compilation and four Spring Security tests passed: anonymous access, CSRF enforcement, customer role restrictions, and inactive session rejection.
- Vite production build passed; chapter editor loads in a separate chunk.
- Live API smoke test passed: admin authentication; password-free DTOs; book creation/update/deletion; PNG cover upload and persistence; sanitized chapter creation retaining headings; chapter editing, reordering and deletion; customer creation/update/deletion; publication and unpublication; customer draft and management restrictions; reading progress; deactivation; password reset; logout.
- Application restart test passed: custom book metadata, chapter HTML, customer and reading progress survived stopping and restarting Spring Boot.
- Browser checks: real administrator login, populated dashboard and catalog, management table, accessible Add Book dialog, saved chapter rendering, chapter navigation, table of contents, font-size adjustment and dark reading mode.

`verify.ps1` is repeatable and removes its disposable records. The initial two original sample stories remain in PostgreSQL. These are local development checks, not a load test or production security audit.
