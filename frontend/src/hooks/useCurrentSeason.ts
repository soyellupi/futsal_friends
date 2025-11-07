import { useQuery } from '@tanstack/react-query';
import { API_ENDPOINTS, apiRequest } from '../services/api';
import type { Season } from '../types/season.types';

export function useCurrentSeason() {
  return useQuery({
    queryKey: ['season', 'current'],
    queryFn: () => apiRequest<Season>(API_ENDPOINTS.seasons.current),
  });
}
