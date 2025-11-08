import { Navigate } from 'react-router-dom';
import { useCurrentSeason } from '../hooks/useCurrentSeason';

export function RootRedirect() {
  const { data: season, isLoading, error } = useCurrentSeason();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Loading...</div>
          </div>
        </div>
      </div>
    );
  }

  if (error || !season) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-red-600 dark:text-red-400">
              Error loading current season: {error?.message || 'No active season found'}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return <Navigate to={`/season/${season.year}/leaderboard`} replace />;
}
