const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const API_ENDPOINTS = {
  auth: {
    login: `${API_BASE_URL}/api/v1/auth/login`,
    register: `${API_BASE_URL}/api/v1/auth/register`,
    logout: `${API_BASE_URL}/api/v1/auth/logout`,
    refresh: `${API_BASE_URL}/api/v1/auth/refresh`,
  },
  seasons: {
    current: `${API_BASE_URL}/api/v1/seasons/current`,
  },
  leaderboard: {
    byYear: (year: number) => `${API_BASE_URL}/api/v1/seasons/${year}/leaderboard`,
  },
  matches: {
    bySeasonWeek: (year: number, week: number) => `${API_BASE_URL}/api/v1/seasons/${year}/matches/${week}`,
  },
} as const;

interface RequestOptions extends RequestInit {
  token?: string;
}

export async function apiRequest<T>(
  url: string,
  options: RequestOptions = {}
): Promise<T> {
  const { token, ...fetchOptions } = options;

  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...fetchOptions.headers,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...fetchOptions,
    headers,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({
      message: 'An error occurred',
    }));
    throw new Error(error.message || 'Request failed');
  }

  return response.json();
}
