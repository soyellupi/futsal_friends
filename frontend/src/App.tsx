import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './config/queryClient';
import { LeaderboardPage } from './pages/LeaderboardPage';
import { MatchPage } from './pages/MatchPage';
import { AttendancePage } from './pages/AttendancePage';
import { RootRedirect } from './pages/RootRedirect';

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<RootRedirect />} />
          <Route path="/season/:year/leaderboard" element={<LeaderboardPage />} />
          <Route path="/season/:year/match/:matchWeek" element={<MatchPage />} />
          <Route path="/season/:year/match/:matchWeek/attendance" element={<AttendancePage />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;
