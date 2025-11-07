import { LeaderboardTable } from '../components/features/LeaderboardTable';
import { useCurrentSeason } from '../hooks/useCurrentSeason';

export function LeaderboardPage() {
  const { data: season, isLoading: isSeasonLoading, error: seasonError } = useCurrentSeason();

  if (isSeasonLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Loading season data...</div>
          </div>
        </div>
      </div>
    );
  }

  if (seasonError) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-red-600 dark:text-red-400">
              Error loading season: {seasonError.message}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!season) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">No active season found</div>
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
                {season.name}
              </h2>
            </div>
          </div>
        </div>

        {/* Leaderboard Table Card */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
          <LeaderboardTable seasonId={season.id} />
        </div>

        {/* Legend */}
        <div className="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
            Legend
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 text-sm">
            <div className="flex items-center gap-2">
              <span className="text-gray-600 dark:text-gray-400">Played:</span>
              <span className="text-gray-900 dark:text-white font-medium">Matches completed</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-green-600 dark:text-green-400 font-semibold">Won:</span>
              <span className="text-gray-900 dark:text-white">Matches won</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-600 dark:text-gray-400">Draw:</span>
              <span className="text-gray-900 dark:text-white">Matches drawn</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-red-600 dark:text-red-400">Lost:</span>
              <span className="text-gray-900 dark:text-white">Matches lost</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-blue-600 dark:text-blue-400">3rd Time:</span>
              <span className="text-gray-900 dark:text-white">Attended as substitute</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-primary-600 dark:text-primary-400 font-bold">Points:</span>
              <span className="text-gray-900 dark:text-white">Total ranking points</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
