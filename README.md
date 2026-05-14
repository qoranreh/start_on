# Start On

Monorepo for the Start On frontend and backend.

## Structure

```text
start_on/
  frontend/   Flutter app
  backend/    FastAPI backend
  supabase/   Supabase local config and migrations
```

## Frontend

```bash
cd frontend
flutter run
```

## Backend

```bash
cd backend
python -m venv .venv311
.venv311/bin/pip install -r requirements.txt
.venv311/bin/python -m app.main
```
