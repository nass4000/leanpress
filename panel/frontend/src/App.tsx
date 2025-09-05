import { Routes, Route, Link } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import { Container, Box, Typography } from '@mui/material';

function App() {
  return (
    <Container>
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          WordPress Control Panel
        </Typography>
        <nav>
          <Link to="/login">Login</Link> | <Link to="/register">Register</Link>
        </nav>
      </Box>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/" element={<HomePage />} />
      </Routes>
    </Container>
  );
}

function HomePage() {
    return <h2>Welcome! Please login or register.</h2>;
}

export default App;
