import { useParams } from 'react-router-dom';
import { useMatch } from '../hooks/useMatch';
import type { MatchPlayerDetail, MatchTeamDetail, TeamName } from '../types/match.types';
import { PlayerType } from '../types/match.types';

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

function calculateTotalRank(players: MatchPlayerDetail[], useCurrentRating: boolean = false): number {
  return players.reduce((sum, player) => {
    const rating = useCurrentRating ? (player.current_rating || 0) : (player.rating || 0);
    return sum + rating;
  }, 0);
}

function getTeamDisplayName(teamName: TeamName): string {
  return teamName === 'black' ? 'Black Team' : 'Pink Team';
}

function TeamCard({
  team,
  isWinner,
  hasResult
}: {
  team: MatchTeamDetail;
  isWinner: boolean | null;
  hasResult: boolean;
}) {
  // Use current_rating if there's no result, otherwise use rating (before match)
  const totalRank = calculateTotalRank(team.players, !hasResult);

  // Sort players: goalkeepers first, then regular players
  const sortedPlayers = [...team.players].sort((a, b) => {
    const aIsGK = a.position === 'goalkeeper';
    const bIsGK = b.position === 'goalkeeper';
    if (aIsGK && !bIsGK) return -1;
    if (!aIsGK && bIsGK) return 1;
    return 0;
  });

  return (
    <div className={`bg-white dark:bg-gray-800 rounded-lg shadow-sm border ${
      isWinner === true
        ? 'border-green-400 dark:border-green-600 ring-2 ring-green-200 dark:ring-green-900'
        : isWinner === false
        ? 'border-red-300 dark:border-red-700'
        : 'border-gray-200 dark:border-gray-700'
    } p-3 sm:p-4 lg:p-6`}>
      <div className="mb-3 sm:mb-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-lg sm:text-xl lg:text-2xl font-bold text-gray-900 dark:text-white">
            {getTeamDisplayName(team.name)}
          </h3>
          {isWinner === true && (
            <span className="px-2 py-0.5 sm:px-3 sm:py-1 bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 rounded-full text-xs sm:text-sm font-semibold">
              Winner
            </span>
          )}
        </div>
        <div className="text-sm sm:text-base text-gray-600 dark:text-gray-400">
          Total Rank: <span className="font-semibold text-lg sm:text-xl text-gray-900 dark:text-white">{Math.round(totalRank)}</span>
        </div>
      </div>

      <div className="space-y-1.5 sm:space-y-2">
        <h4 className="text-xs sm:text-sm font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
          Players
        </h4>
        <div className="space-y-1.5 sm:space-y-2">
          {team.players.length === 0 ? (
            <div className="text-xs sm:text-sm text-gray-600 dark:text-gray-400 italic">
              No players assigned yet
            </div>
          ) : (
            sortedPlayers.map((player) => (
              <div
                key={player.id}
                className="flex items-center justify-between p-2 sm:p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
              >
                <div className="flex items-center gap-1 sm:gap-2 flex-wrap min-w-0">
                  <span className="font-medium text-xs sm:text-sm text-gray-900 dark:text-white truncate">
                    {player.name}
                  </span>
                  {player.position === 'goalkeeper' && (
                    <span className="px-1.5 sm:px-2 py-0.5 text-xs font-bold bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200 rounded flex-shrink-0">
                      GK
                    </span>
                  )}
                  {player.player_type === PlayerType.INVITED && (
                    <span className="px-1.5 sm:px-2 py-0.5 text-xs font-medium bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 rounded flex-shrink-0">
                      Invited
                    </span>
                  )}
                </div>
                <span className="inline-flex items-center px-2 sm:px-3 py-0.5 sm:py-1 rounded-full text-xs sm:text-sm font-semibold bg-primary-100 dark:bg-primary-900 text-primary-800 dark:text-primary-200 flex-shrink-0 ml-1">
                  {(() => {
                    const displayRating = hasResult ? player.rating : player.current_rating;
                    return displayRating !== null ? Math.round(displayRating) : 'N/A';
                  })()} pts
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

  // Determine winner and if match has result
  let blackTeamIsWinner: boolean | null = null;
  let pinkTeamIsWinner: boolean | null = null;
  const hasResult = blackTeam?.score !== null && pinkTeam?.score !== null;

  if (blackTeam && pinkTeam && hasResult) {
    if (blackTeam.score! > pinkTeam.score!) {
      blackTeamIsWinner = true;
      pinkTeamIsWinner = false;
    } else if (pinkTeam.score! > blackTeam.score!) {
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
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 sm:p-6 mb-4 sm:mb-6">
            <div className="flex items-center justify-center gap-4 sm:gap-6 lg:gap-8">
              <div className="text-center">
                <div className="text-sm sm:text-lg lg:text-xl font-semibold text-gray-900 dark:text-white mb-1">
                  {getTeamDisplayName(blackTeam.name)}
                </div>
                <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-primary-600 dark:text-primary-400">
                  {blackTeam.score ?? 0}
                </div>
              </div>
              <div className="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-400 dark:text-gray-600">
                VS
              </div>
              <div className="text-center">
                <div className="text-sm sm:text-lg lg:text-xl font-semibold text-gray-900 dark:text-white mb-1">
                  {getTeamDisplayName(pinkTeam.name)}
                </div>
                <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-primary-600 dark:text-primary-400">
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
          <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:gap-6">
            <TeamCard team={blackTeam} isWinner={blackTeamIsWinner} hasResult={hasResult} />
            <TeamCard team={pinkTeam} isWinner={pinkTeamIsWinner} hasResult={hasResult} />
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
