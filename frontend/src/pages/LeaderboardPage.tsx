import { useParams } from 'react-router-dom';
import { LeaderboardTable } from '../components/features/LeaderboardTable';
import { useLeaderboardByYear } from '../hooks/useLeaderboardByYear';

export function LeaderboardPage() {
  const { year } = useParams<{ year: string }>();
  const yearNum = year ? parseInt(year, 10) : undefined;

  const { data: leaderboardData, isLoading, error } = useLeaderboardByYear(yearNum);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Loading leaderboard...</div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-red-600 dark:text-red-400">
              Error loading leaderboard: {error.message}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!leaderboardData) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">No leaderboard data found</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Season Leaderboard
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Player rankings based on total points
          </p>
        </div>

        {/* Season Info Card */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <div className="flex flex-wrap items-center gap-4">
            <div>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                {leaderboardData.season_name}
              </h2>
            </div>
          </div>
        </div>

        {/* Leaderboard Table Card */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
          <LeaderboardTable data={leaderboardData} />
        </div>
      </div>
    </div>
  );
}
