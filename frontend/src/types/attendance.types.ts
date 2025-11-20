export enum PlayerType {
  REGULAR = 'regular',
  INVITED = 'invited'
}

export interface PlayerAttendanceDetail {
  player_id: string;
  player_name: string;
  player_type: PlayerType;
  attended: boolean | null;
  current_rating: number | null;
}

export interface MatchAttendanceData {
  match_id: string;
  match_week: number;
  match_date: string;
  regular_players: PlayerAttendanceDetail[];
  invited_players: PlayerAttendanceDetail[];
}
