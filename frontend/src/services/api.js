// En dev : on appelle directement l'API (ex: http://localhost:8080)
// En prod : on utilise un chemin relatif /api proxifié par Apache vers Dart
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

function getToken() { return localStorage.getItem('token'); }

function headers(withAuth = true) {
  const h = { 'Content-Type': 'application/json' };
  if (withAuth) h['Authorization'] = `Bearer ${getToken()}`;
  return h;
}

async function handleResponse(res) {
  if (res.status === 204) return null;
  const data = await res.json();
  if (!res.ok) throw new Error(data.erreur || 'Erreur serveur');
  return data;
}

// ── Auth ─────────────────────────────────────────────────────────────────────
export async function register(nom, email, mot_de_passe) {
  const res = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST', headers: headers(false),
    body: JSON.stringify({ nom, email, mot_de_passe }),
  });
  return handleResponse(res);
}

export async function login(email, mot_de_passe) {
  const res = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST', headers: headers(false),
    body: JSON.stringify({ email, mot_de_passe }),
  });
  return handleResponse(res);
}

// ── Types (admin) ─────────────────────────────────────────────────────────────
export const typesApi = {
  getAll: () => fetch(`${BASE_URL}/types`, { headers: headers() }).then(handleResponse),
  create: (d) => fetch(`${BASE_URL}/types`, { method: 'POST', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  update: (id, d) => fetch(`${BASE_URL}/types/${id}`, { method: 'PUT', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  delete: (id) => fetch(`${BASE_URL}/types/${id}`, { method: 'DELETE', headers: headers() }).then(handleResponse),
};

// ── Formats (admin) ───────────────────────────────────────────────────────────
export const formatsApi = {
  getAll: () => fetch(`${BASE_URL}/formats`, { headers: headers() }).then(handleResponse),
  create: (d) => fetch(`${BASE_URL}/formats`, { method: 'POST', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  update: (id, d) => fetch(`${BASE_URL}/formats/${id}`, { method: 'PUT', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  delete: (id) => fetch(`${BASE_URL}/formats/${id}`, { method: 'DELETE', headers: headers() }).then(handleResponse),
};

// ── Produits (admin) ──────────────────────────────────────────────────────────
export const produitsApi = {
  getAll: () => fetch(`${BASE_URL}/produits`, { headers: headers() }).then(handleResponse),
  create: (d) => fetch(`${BASE_URL}/produits`, { method: 'POST', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  update: (id, d) => fetch(`${BASE_URL}/produits/${id}`, { method: 'PUT', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  delete: (id) => fetch(`${BASE_URL}/produits/${id}`, { method: 'DELETE', headers: headers() }).then(handleResponse),
};

// ── Clients (admin) ───────────────────────────────────────────────────────────
export const clientsApi = {
  getAll: () => fetch(`${BASE_URL}/clients`, { headers: headers() }).then(handleResponse),
  create: (d) => fetch(`${BASE_URL}/clients`, { method: 'POST', headers: headers(), body: JSON.stringify(d) }).then(handleResponse),
  delete: (id) => fetch(`${BASE_URL}/clients/${id}`, { method: 'DELETE', headers: headers() }).then(handleResponse),
};

// ── Profil (client connecté) ──────────────────────────────────────────────────
export const profilApi = {
  get: () => fetch(`${BASE_URL}/profil`, { headers: headers() }).then(handleResponse),
  changePassword: (ancien, nouveau) => fetch(`${BASE_URL}/profil/password`, {
    method: 'PUT', headers: headers(),
    body: JSON.stringify({ ancien_mot_de_passe: ancien, nouveau_mot_de_passe: nouveau }),
  }).then(handleResponse),
  deleteAccount: () => fetch(`${BASE_URL}/profil`, { method: 'DELETE', headers: headers() }).then(handleResponse),
};

// ── Sélection (client) ────────────────────────────────────────────────────────
export const selectionApi = {
  getAll: () => fetch(`${BASE_URL}/selection`, { headers: headers() }).then(handleResponse),
  add: (id_produit, quantite = 1) => fetch(`${BASE_URL}/selection`, {
    method: 'POST', headers: headers(), body: JSON.stringify({ id_produit, quantite }),
  }).then(handleResponse),
  update: (id, quantite) => fetch(`${BASE_URL}/selection/${id}`, {
    method: 'PUT', headers: headers(), body: JSON.stringify({ quantite }),
  }).then(handleResponse),
  delete: (id) => fetch(`${BASE_URL}/selection/${id}`, { method: 'DELETE', headers: headers() }).then(handleResponse),
  valider: () => fetch(`${BASE_URL}/selection/valider`, { method: 'POST', headers: headers() }).then(handleResponse),
};
