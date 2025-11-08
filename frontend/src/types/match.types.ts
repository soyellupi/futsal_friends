export enum MatchStatus {
  SCHEDULED = 'scheduled',
  CONFIRMED = 'confirmed',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

export enum TeamName {
  TEAM_A = 'black',
  TEAM_B = 'pink'
}

export interface MatchPlayerDetail {
  id: string;
  name: string;
  rating: number | null;
}

export interface MatchTeamDetail {
  id: string;
  name: TeamName;
  score: number | null;
  players: MatchPlayerDetail[];
  average_rating: number | null;
}

export interface ThirdTimeAttendee {
  id: string;
  name: string;
}

export interface Match {
  id: string;
  season_id: string;
  match_date: string;
  status: MatchStatus;
  rsvp_deadline: string | null;
  location: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
  teams: MatchTeamDetail[];
  third_time_attendees: ThirdTimeAttendee[];
}
