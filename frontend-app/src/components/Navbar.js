import React, { useState, useEffect } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  IconButton,
  Badge,
  Menu,
  MenuItem,
  Box,
  Avatar,
  Tooltip
} from '@mui/material';
import {
  ShoppingCart,
  AccountCircle,
  Notifications,
  Store,
  Dashboard,
  Health
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { identityService, healthService } from '../services/api';

const Navbar = () => {
  const navigate = useNavigate();
  const [anchorEl, setAnchorEl] = useState(null);
  const [user, setUser] = useState(null);
  const [cartItems, setCartItems] = useState(0);
  const [servicesHealth, setServicesHealth] = useState([]);
  const [healthMenuAnchor, setHealthMenuAnchor] = useState(null);

  useEffect(() => {
    // Récupérer l'utilisateur connecté
    const currentUser = identityService.getCurrentUser();
    setUser(currentUser);

    // Récupérer le nombre d'articles dans le panier
    const cart = JSON.parse(localStorage.getItem('cart') || '[]');
    setCartItems(cart.reduce((total, item) => total + item.quantity, 0));

    // Vérifier la santé des services
    checkServicesHealth();
  }, []);

  const checkServicesHealth = async () => {
    try {
      const health = await healthService.checkAllServices();
      setServicesHealth(health);
    } catch (error) {
      console.error('Erreur lors de la vérification de santé:', error);
    }
  };

  const handleProfileMenuOpen = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleHealthMenuOpen = (event) => {
    setHealthMenuAnchor(event.currentTarget);
  };

  const handleHealthMenuClose = () => {
    setHealthMenuAnchor(null);
  };

  const handleLogout = () => {
    identityService.logout();
    setUser(null);
    navigate('/');
    handleMenuClose();
  };

  const getHealthColor = () => {
    const downServices = servicesHealth.filter(s => s.status === 'DOWN').length;
    if (downServices === 0) return 'success';
    if (downServices <= 2) return 'warning';
    return 'error';
  };

  return (
    <AppBar position="sticky" sx={{ bgcolor: 'primary.main' }}>
      <Toolbar>
        {/* Logo et titre */}
        <IconButton
          edge="start"
          color="inherit"
          onClick={() => navigate('/')}
          sx={{ mr: 2 }}
        >
          <Store />
        </IconButton>
        <Typography
          variant="h6"
          component="div"
          sx={{ flexGrow: 1, cursor: 'pointer' }}
          onClick={() => navigate('/')}
        >
          SpringBoot Microservices Store
        </Typography>

        {/* Navigation */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Button color="inherit" onClick={() => navigate('/products')}>
            Produits
          </Button>
          
          {user && (
            <Button color="inherit" onClick={() => navigate('/orders')}>
              Mes Commandes
            </Button>
          )}

          <Button color="inherit" onClick={() => navigate('/dashboard')}>
            <Dashboard sx={{ mr: 1 }} />
            Dashboard
          </Button>

          {/* Santé des services */}
          <Tooltip title="Santé des microservices">
            <IconButton
              color="inherit"
              onClick={handleHealthMenuOpen}
            >
              <Badge color={getHealthColor()} variant="dot">
                <Health />
              </Badge>
            </IconButton>
          </Tooltip>

          {/* Panier */}
          <IconButton
            color="inherit"
            onClick={() => navigate('/cart')}
          >
            <Badge badgeContent={cartItems} color="error">
              <ShoppingCart />
            </Badge>
          </IconButton>

          {/* Notifications */}
          <IconButton color="inherit">
            <Badge badgeContent={3} color="error">
              <Notifications />
            </Badge>
          </IconButton>

          {/* Profil utilisateur */}
          {user ? (
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <IconButton
                onClick={handleProfileMenuOpen}
                color="inherit"
              >
                <Avatar sx={{ width: 32, height: 32 }}>
                  {user.firstName?.[0]?.toUpperCase()}
                </Avatar>
              </IconButton>
            </Box>
          ) : (
            <Button color="inherit" onClick={() => navigate('/login')}>
              Connexion
            </Button>
          )}
        </Box>

        {/* Menu profil */}
        <Menu
          anchorEl={anchorEl}
          open={Boolean(anchorEl)}
          onClose={handleMenuClose}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        >
          <MenuItem onClick={() => { navigate('/profile'); handleMenuClose(); }}>
            Mon Profil
          </MenuItem>
          <MenuItem onClick={() => { navigate('/orders'); handleMenuClose(); }}>
            Mes Commandes
          </MenuItem>
          <MenuItem onClick={handleLogout}>
            Déconnexion
          </MenuItem>
        </Menu>

        {/* Menu santé des services */}
        <Menu
          anchorEl={healthMenuAnchor}
          open={Boolean(healthMenuAnchor)}
          onClose={handleHealthMenuClose}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        >
          <MenuItem disabled>
            <Typography variant="subtitle2" sx={{ fontWeight: 'bold' }}>
              État des Microservices
            </Typography>
          </MenuItem>
          {servicesHealth.map((service) => (
            <MenuItem key={service.service}>
              <Badge
                color={service.status === 'UP' ? 'success' : 'error'}
                variant="dot"
                sx={{ mr: 2 }}
              />
              {service.service}: {service.status}
            </MenuItem>
          ))}
          <MenuItem onClick={() => { navigate('/dashboard'); handleHealthMenuClose(); }}>
            Voir le dashboard complet
          </MenuItem>
        </Menu>
      </Toolbar>
    </AppBar>
  );
};

export default Navbar;
