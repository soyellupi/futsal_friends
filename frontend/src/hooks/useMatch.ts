import { useQuery } from '@tanstack/react-query';
import { apiRequest, API_ENDPOINTS } from '../services/api';
import type { Match } from '../types/match.types';

export function useMatch(year: number | undefined, matchWeek: number | undefined) {
  return useQuery({
    queryKey: ['match', year, matchWeek],
    queryFn: () => apiRequest<Match>(API_ENDPOINTS.matches.bySeasonWeek(year!, matchWeek!)),
    enabled: !!year && !!matchWeek,
  });
}
