import { Table } from '../common/Table';
import { TableHeader } from '../common/TableHeader';
import { TableBody } from '../common/TableBody';
import { TableRow } from '../common/TableRow';
import { TableCell } from '../common/TableCell';
import type { LeaderboardData } from '../../types/leaderboard.types';
import clsx from 'clsx';

interface LeaderboardTableProps {
  data: LeaderboardData;
  className?: string;
}

function getRankBadge(rank: number) {
  const baseClasses = 'inline-flex items-center justify-center w-6 h-6 sm:w-8 sm:h-8 rounded-full font-bold text-xs sm:text-sm';

  if (rank === 1) {
    return (
      <div className={clsx(baseClasses, 'bg-yellow-400 text-yellow-900')}>
        {rank}
      </div>
    );
  }

  if (rank >= 2 && rank <= 7) {
    return (
      <div className={clsx(baseClasses, 'bg-green-300 text-green-800')}>
        {rank}
      </div>
    );
  }

  if (rank > 7) {
    return (
      <div className={clsx(baseClasses, 'bg-red-400 text-red-900')}>
        {rank}
      </div>
    );
  }

  return (
    <div className={clsx(baseClasses, 'bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300')}>
      {rank}
    </div>
  );
}

export function LeaderboardTable({ data, className }: LeaderboardTableProps) {
  if (!data || data.entries.length === 0) {
    return (
      <div className={clsx('w-full p-8 flex items-center justify-center', className)}>
        <div className="text-gray-600 dark:text-gray-400">No leaderboard data available</div>
      </div>
    );
  }

  return (
    <div className={clsx('w-full', className)}>
      <Table>
        <TableHeader>
          <TableRow isHeader>
            <TableCell variant="header" align="center">Rank</TableCell>
            <TableCell variant="header" align="left">Player</TableCell>
            <TableCell variant="header" align="center">Points</TableCell>
            <TableCell variant="header" align="center">Played</TableCell>
            <TableCell variant="header" align="center">Won</TableCell>
            <TableCell variant="header" align="center">Draw</TableCell>
            <TableCell variant="header" align="center">Lost</TableCell>
            <TableCell variant="header" align="center">3rd Time</TableCell>
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.entries.map((entry) => (
            <TableRow key={entry.player_stats.player_id}>
              <TableCell align="center" className="w-12 sm:w-16">
                {getRankBadge(entry.rank)}
              </TableCell>
              <TableCell align="left" className="font-medium max-w-[100px] sm:max-w-none">
                <div className="min-w-0">
                  <div className="truncate">{entry.player_stats.player_name}</div>
                </div>
              </TableCell>
              <TableCell align="center" className="font-bold text-primary-600 dark:text-primary-400">
                {entry.player_stats.total_points}
              </TableCell>
              <TableCell align="center">
                {entry.player_stats.matches_attended}
              </TableCell>
              <TableCell align="center" className="text-green-600 dark:text-green-400 font-semibold">
                {entry.player_stats.wins}
              </TableCell>
              <TableCell align="center" className="text-gray-600 dark:text-gray-400">
                {entry.player_stats.draws}
              </TableCell>
              <TableCell align="center" className="text-red-600 dark:text-red-400">
                {entry.player_stats.losses}
              </TableCell>
              <TableCell align="center" className="text-blue-600 dark:text-blue-400">
                {entry.player_stats.third_time_attended}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
