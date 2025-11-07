import { useQuery } from '@tanstack/react-query';
import { API_ENDPOINTS, apiRequest } from '../services/api';
import type { LeaderboardData } from '../types/leaderboard.types';

export function useLeaderboard(seasonId: string | undefined) {
  return useQuery({
    queryKey: ['leaderboard', seasonId],
    queryFn: () => {
      if (!seasonId) throw new Error('Season ID is required');
      return apiRequest<LeaderboardData>(API_ENDPOINTS.leaderboard.bySeason(seasonId));
    },
    enabled: !!seasonId,
  });
}
