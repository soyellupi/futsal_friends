/**
 * Leaderboard type definitions matching backend schemas
 */

export interface PlayerStats {
  player_id: string;
  player_name: string;
  current_rating: number;
  matches_completed: number;
  matches_attended: number;
  wins: number;
  draws: number;
  losses: number;
  third_time_attended: number;
  total_points: number;
  attendance_rate: number;
}

export interface LeaderboardEntry {
  rank: number;
  player_stats: PlayerStats;
}

export interface LeaderboardData {
  season_id: string;
  season_name: string;
  season_year: number;
  entries: LeaderboardEntry[];
  total_matches: number;
}
