import { useParams } from 'react-router-dom';
import { useMatch } from '../hooks/useMatch';
import type { MatchPlayerDetail, MatchTeamDetail, TeamName } from '../types/match.types';

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

function calculateTotalRank(players: MatchPlayerDetail[]): number {
  return players.reduce((sum, player) => sum + (player.rating || 0), 0);
}

function getTeamDisplayName(teamName: TeamName): string {
  return teamName === 'black' ? 'Black Team' : 'Pink Team';
}

function TeamCard({
  team,
  isWinner
}: {
  team: MatchTeamDetail;
  isWinner: boolean | null
}) {
  const totalRank = calculateTotalRank(team.players);

  return (
    <div className={`bg-white dark:bg-gray-800 rounded-lg shadow-sm border ${
      isWinner === true
        ? 'border-green-400 dark:border-green-600 ring-2 ring-green-200 dark:ring-green-900'
        : isWinner === false
        ? 'border-red-300 dark:border-red-700'
        : 'border-gray-200 dark:border-gray-700'
    } p-6`}>
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
            {getTeamDisplayName(team.name)}
          </h3>
          {isWinner === true && (
            <span className="px-3 py-1 bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 rounded-full text-sm font-semibold">
              Winner
            </span>
          )}
        </div>
        <div className="flex items-baseline gap-4">
          <div className="text-5xl font-bold text-primary-600 dark:text-primary-400">
            {team.score ?? 0}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">
            Total Rank: <span className="font-semibold text-gray-900 dark:text-white">{Math.round(totalRank)}</span>
          </div>
        </div>
      </div>

      <div className="space-y-2">
        <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
          Players
        </h4>
        <div className="space-y-2">
          {team.players.length === 0 ? (
            <div className="text-sm text-gray-600 dark:text-gray-400 italic">
              No players assigned yet
            </div>
          ) : (
            team.players.map((player) => (
              <div
                key={player.id}
                className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
              >
                <span className="font-medium text-gray-900 dark:text-white">
                  {player.name}
                </span>
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-primary-100 dark:bg-primary-900 text-primary-800 dark:text-primary-200">
                  {player.rating !== null ? Math.round(player.rating) : 'N/A'} pts
                </span>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}

export function MatchPage() {
  const { year, matchWeek } = useParams<{ year: string; matchWeek: string }>();
  const yearNum = year ? parseInt(year, 10) : undefined;
  const weekNum = matchWeek ? parseInt(matchWeek, 10) : undefined;
  const { data: match, isLoading, error } = useMatch(yearNum, weekNum);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Loading match data...</div>
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
              Error loading match: {error.message}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!match) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600 dark:text-gray-400">Match not found</div>
          </div>
        </div>
      </div>
    );
  }

  // Find teams (should be black and pink)
  const blackTeam = match.teams.find(t => t.name === 'black');
  const pinkTeam = match.teams.find(t => t.name === 'pink');

  // Determine winner
  let blackTeamIsWinner: boolean | null = null;
  let pinkTeamIsWinner: boolean | null = null;

  if (blackTeam && pinkTeam && blackTeam.score !== null && pinkTeam.score !== null) {
    if (blackTeam.score > pinkTeam.score) {
      blackTeamIsWinner = true;
      pinkTeamIsWinner = false;
    } else if (pinkTeam.score > blackTeam.score) {
      blackTeamIsWinner = false;
      pinkTeamIsWinner = true;
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Match Details
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            {formatMatchDate(match.match_date)}
          </p>
          {match.location && (
            <p className="text-gray-600 dark:text-gray-400 mt-1">
              Location: {match.location}
            </p>
          )}
        </div>

        {/* Match Score Summary */}
        {blackTeam && pinkTeam && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-6">
            <div className="flex items-center justify-center gap-8">
              <div className="text-center">
                <div className="text-xl font-semibold text-gray-900 dark:text-white mb-1">
                  {getTeamDisplayName(blackTeam.name)}
                </div>
                <div className="text-5xl font-bold text-primary-600 dark:text-primary-400">
                  {blackTeam.score ?? 0}
                </div>
              </div>
              <div className="text-3xl font-bold text-gray-400 dark:text-gray-600">
                VS
              </div>
              <div className="text-center">
                <div className="text-xl font-semibold text-gray-900 dark:text-white mb-1">
                  {getTeamDisplayName(pinkTeam.name)}
                </div>
                <div className="text-5xl font-bold text-primary-600 dark:text-primary-400">
                  {pinkTeam.score ?? 0}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* No teams message */}
        {match.teams.length === 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-6">
            <div className="text-center text-gray-600 dark:text-gray-400">
              Teams have not been assigned yet for this match
            </div>
          </div>
        )}

        {/* Team Details */}
        {blackTeam && pinkTeam && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <TeamCard team={blackTeam} isWinner={blackTeamIsWinner} />
            <TeamCard team={pinkTeam} isWinner={pinkTeamIsWinner} />
          </div>
        )}

        {/* Third Time Attendance */}
        {match.third_time_attendees.length > 0 && (
          <div className="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Third Time Attendance
            </h3>
            <div className="flex flex-wrap gap-2">
              {match.third_time_attendees.map((attendee) => (
                <span
                  key={attendee.id}
                  className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
                >
                  {attendee.name}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Notes */}
        {match.notes && (
          <div className="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
              Notes
            </h3>
            <p className="text-gray-600 dark:text-gray-400">
              {match.notes}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
