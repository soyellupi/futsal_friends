import { useParams } from 'react-router-dom';
import { useAttendance } from '../hooks/useAttendance';
import type { PlayerAttendanceDetail } from '../types/attendance.types';

function formatMatchDate(dateString: string): string {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date);
}

function getAttendedBadge(attended: boolean | null) {
  if (attended === null) {
    return (
      <span className="px-2 py-1 text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200 rounded">
        N/A
      </span>
    );
  }

  if (attended) {
    return (
      <span className="px-2 py-1 text-xs font-medium bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 rounded">
        Yes
      </span>
    );
  }

  return (
    <span className="px-2 py-1 text-xs font-medium bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 rounded">
      No
    </span>
  );
}

interface PlayerListProps {
  players: PlayerAttendanceDetail[];
  title: string;
}

function PlayerList({ players, title }: PlayerListProps) {
  if (players.length === 0) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
          {title}
        </h2>
        <p className="text-gray-600 dark:text-gray-400 italic">
          No {title.toLowerCase()} for this match
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
      <div className="p-4 sm:p-6 border-b border-gray-200 dark:border-gray-700">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white">
          {title}
        </h2>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
          {players.length} {players.length === 1 ? 'player' : 'players'}
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead className="bg-gray-50 dark:bg-gray-900">
            <tr>
              <th scope="col" className="px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Name
              </th>
              <th scope="col" className="px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Attended
              </th>
              <th scope="col" className="px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Rating
              </th>
            </tr>
          </thead>
          <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
            {players.map((player) => (
              <tr key={player.player_id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                <td className="px-4 sm:px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900 dark:text-white">
                    {player.player_name}
                  </div>
                </td>
                <td className="px-4 sm:px-6 py-4 whitespace-nowrap">
                  {getAttendedBadge(player.attended)}
                </td>
                <td className="px-4 sm:px-6 py-4 whitespace-nowrap">
                  <span className="text-sm text-gray-900 dark:text-white font-semibold">
                    {player.current_rating !== null ? Math.round(player.current_rating) : 'N/A'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function AttendancePage() {
  const { year, matchWeek } = useParams<{ year: string; matchWeek: string }>();
  const yearNum = year ? parseInt(year, 10) : undefined;
  const weekNum = matchWeek ? parseInt(matchWeek, 10) : undefined;
  const { data: attendance, isLoading, error } = useAttendance(yearNum, weekNum);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Loading attendance data...</div>
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
              Error loading attendance: {error.message}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!attendance) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Attendance data not found</div>
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
            Match Attendance - Week {attendance.match_week}
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            {formatMatchDate(attendance.match_date)}
          </p>
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Regular Players attended</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">
              {attendance.regular_players.filter(p => p.attended === true).length}
            </div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Invited Players attended</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">
              {attendance.invited_players.filter(p => p.attended === true).length}
            </div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Players attended</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">
              {attendance.regular_players.filter(p => p.attended === true).length +
               attendance.invited_players.filter(p => p.attended === true).length}
            </div>
          </div>
        </div>

        {/* Player Lists */}
        <div className="grid grid-cols-2 gap-4 lg:gap-6">
          <PlayerList players={attendance.regular_players} title="Regular Players" />
          <PlayerList players={attendance.invited_players} title="Invited Players" />
        </div>
      </div>
    </div>
  );
}
