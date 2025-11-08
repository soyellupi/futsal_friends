import { useQuery } from '@tanstack/react-query';
import { apiRequest, API_ENDPOINTS } from '../services/api';
import type { LeaderboardData } from '../types/leaderboard.types';

export function useLeaderboardByYear(year: number | undefined) {
  return useQuery({
    queryKey: ['leaderboard', year],
    queryFn: () => apiRequest<LeaderboardData>(API_ENDPOINTS.leaderboard.byYear(year!)),
    enabled: !!year,
  });
}
