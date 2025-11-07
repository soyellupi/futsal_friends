export interface Season {
  id: string;
  name: string;
  year: number;
  start_date: string;
  end_date: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}
