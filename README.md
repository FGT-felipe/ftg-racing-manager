# Formula Track Glory

> A browser-based F1-style team management simulation. Build your racing operation from the ground up — scout drivers, engineer your car, negotiate sponsors, and compete every weekend in a live, shared league.

**Version:** 1.8.0 · **Live:** https://ftg-racing-manager.web.app

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | SvelteKit · Svelte 5 Runes · TypeScript · Tailwind CSS |
| Backend | Firebase Cloud Functions v2 (Node.js 20) |
| Database | Firestore (NoSQL) |
| Auth | Firebase Authentication (Google OAuth) |
| Hosting | Firebase Hosting |

---

## Project Structure

```
ftg-racing-manager/
├── frontend/          # SvelteKit web app (active development)
│   ├── src/
│   │   ├── routes/    # File-based routing (pages)
│   │   └── lib/
│   │       ├── services/  # Stateless Firebase logic
│   │       ├── stores/    # Reactive Svelte 5 state
│   │       ├── components/
│   │       └── types/
│   └── static/        # Static assets (driver portraits, car parts)
├── functions/         # Firebase Cloud Functions (race simulation, economy)
├── docs/              # Architecture and product documentation
├── firestore.rules    # Firestore security rules
├── firestore.indexes.json
└── firebase.json
```

---

## Getting Started

### Prerequisites

- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore and Authentication enabled

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The app runs at `http://localhost:5173`.

### Cloud Functions (local emulator)

```bash
cd functions
npm install
firebase emulators:start --only functions,firestore
```

---

## Deployment

```bash
# Build and deploy everything
cd frontend && npm run build
firebase deploy

# Deploy only functions (after changes to functions/index.js)
firebase deploy --only functions

# Deploy only hosting
firebase deploy --only hosting
```

> **After any manual race simulation**, run `node functions/sync_universe.js` to sync the standings page.

---

## Race Weekend Schedule

The simulation runs on a fixed weekly schedule (UTC-5 / Bogotá):

| Day | Time (COT) | Event |
|---|---|---|
| Mon–Sat | 00:00–13:59 | Practice window open |
| Saturday | 14:00 | Qualifying locks |
| Saturday | 15:00 | Qualifying simulation (automated) |
| Sunday | 14:00 | Race simulation (automated) |
| Sunday | ~15:00 | Economy processing (salaries, bonuses, XP) |

---

## Documentation

In-app documentation is available at `/admin/docs` when running the app.

AI agent context lives in `frontend/src/routes/admin/docs/ai/`. Read `CLAUDE.md` at the project root before making any changes.

---

## Contributing

See `CLAUDE.md` for development standards, architecture rules, and the Cloud Functions safety checklist.
