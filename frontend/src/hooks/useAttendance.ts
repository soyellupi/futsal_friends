import { useQuery } from '@tanstack/react-query';
import { apiRequest, API_ENDPOINTS } from '../services/api';
import type { MatchAttendanceData } from '../types/attendance.types';

export function useAttendance(year: number | undefined, matchWeek: number | undefined) {
  return useQuery({
    queryKey: ['attendance', year, matchWeek],
    queryFn: () => apiRequest<MatchAttendanceData>(API_ENDPOINTS.matches.attendance(year!, matchWeek!)),
    enabled: !!year && !!matchWeek,
  });
}
