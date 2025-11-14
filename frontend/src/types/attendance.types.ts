export enum RSVPStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  DECLINED = 'declined',
  TENTATIVE = 'tentative'
}

export enum PlayerType {
  REGULAR = 'regular',
  INVITED = 'invited'
}

export interface PlayerAttendanceDetail {
  player_id: string;
  player_name: string;
  player_type: PlayerType;
  rsvp_status: RSVPStatus | null;
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
