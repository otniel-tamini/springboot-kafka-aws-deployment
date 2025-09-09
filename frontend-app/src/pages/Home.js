import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Button,
  Box,
  Grid,
  Card,
  CardContent,
  CardActions,
  Chip,
  Paper,
  Avatar,
  List,
  ListItem,
  ListItemIcon,
  ListItemText
} from '@mui/material';
import {
  ShoppingCart,
  Dashboard,
  Store,
  Speed,
  Security,
  Cloud,
  CheckCircle,
  TrendingUp,
  People,
  Inventory
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { healthService, productService, orderService } from '../services/api';

const Home = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    servicesUp: 0,
    totalServices: 0,
    productsCount: 0,
    ordersCount: 0
  });

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      // Santé des services
      const health = await healthService.checkAllServices();
      const upServices = health.filter(s => s.status === 'UP').length;
      
      // Statistiques des produits (optionnel)
      try {
        const products = await productService.getProducts(0, 1);
        const productsCount = products.totalElements || products.length || 0;
        
        setStats(prev => ({
          ...prev,
          servicesUp: upServices,
          totalServices: health.length,
          productsCount
        }));
      } catch (err) {
        setStats(prev => ({
          ...prev,
          servicesUp: upServices,
          totalServices: health.length
        }));
      }
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  const features = [
    {
      icon: <Speed color="primary" />,
      title: 'Architecture Microservices',
      description: 'Services découplés et scalables avec Spring Boot'
    },
    {
      icon: <Cloud color="primary" />,
      title: 'Déployé sur AWS EKS',
      description: 'Cluster Kubernetes managé avec haute disponibilité'
    },
    {
      icon: <Security color="primary" />,
      title: 'Sécurisé',
      description: 'Authentification JWT et autorisation par service'
    },
    {
      icon: <Dashboard color="primary" />,
      title: 'Monitoring Intégré',
      description: 'Prometheus, Grafana et health checks en temps réel'
    }
  ];

  const microservices = [
    { name: 'Service Registry', description: 'Discovery et load balancing', status: 'UP' },
    { name: 'API Gateway', description: 'Point d\'entrée unifié', status: 'UP' },
    { name: 'Product Service', description: 'Gestion du catalogue', status: 'UP' },
    { name: 'Order Service', description: 'Traitement des commandes', status: 'UP' },
    { name: 'Payment Service', description: 'Processus de paiement', status: 'UP' },
    { name: 'Identity Service', description: 'Authentification utilisateur', status: 'UP' },
    { name: 'Email Service', description: 'Notifications par email', status: 'UP' }
  ];

  return (
    <Box>
      {/* Hero Section */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          color: 'white',
          py: 8,
          mb: 6
        }}
      >
        <Container maxWidth="lg">
          <Grid container spacing={4} alignItems="center">
            <Grid item xs={12} md={6}>
              <Typography variant="h2" component="h1" gutterBottom sx={{ fontWeight: 'bold' }}>
                SpringBoot Microservices Store
              </Typography>
              <Typography variant="h5" paragraph sx={{ opacity: 0.9 }}>
                Architecture microservices moderne avec Spring Boot, Kafka et Kubernetes
              </Typography>
              <Typography variant="body1" paragraph sx={{ opacity: 0.8, mb: 4 }}>
                Découvrez une plateforme e-commerce complète basée sur une architecture 
                microservices scalable, déployée sur AWS EKS avec monitoring en temps réel.
              </Typography>
              <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                <Button
                  variant="contained"
                  size="large"
                  startIcon={<ShoppingCart />}
                  onClick={() => navigate('/products')}
                  sx={{
                    bgcolor: 'rgba(255,255,255,0.2)',
                    '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' }
                  }}
                >
                  Voir les Produits
                </Button>
                <Button
                  variant="outlined"
                  size="large"
                  startIcon={<Dashboard />}
                  onClick={() => navigate('/dashboard')}
                  sx={{
                    borderColor: 'rgba(255,255,255,0.5)',
                    color: 'white',
                    '&:hover': {
                      borderColor: 'white',
                      bgcolor: 'rgba(255,255,255,0.1)'
                    }
                  }}
                >
                  Dashboard
                </Button>
              </Box>
            </Grid>
            <Grid item xs={12} md={6}>
              <Box sx={{ textAlign: 'center' }}>
                <Store sx={{ fontSize: 200, opacity: 0.3 }} />
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>

      <Container maxWidth="lg">
        {/* Statistiques */}
        <Grid container spacing={3} sx={{ mb: 6 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Avatar sx={{ bgcolor: 'success.main', mx: 'auto', mb: 2 }}>
                  <CheckCircle />
                </Avatar>
                <Typography variant="h4" color="primary">
                  {stats.servicesUp}/{stats.totalServices}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Services Actifs
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Avatar sx={{ bgcolor: 'info.main', mx: 'auto', mb: 2 }}>
                  <Inventory />
                </Avatar>
                <Typography variant="h4" color="primary">
                  {stats.productsCount}+
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Produits
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Avatar sx={{ bgcolor: 'warning.main', mx: 'auto', mb: 2 }}>
                  <TrendingUp />
                </Avatar>
                <Typography variant="h4" color="primary">
                  7
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Microservices
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Avatar sx={{ bgcolor: 'secondary.main', mx: 'auto', mb: 2 }}>
                  <People />
                </Avatar>
                <Typography variant="h4" color="primary">
                  24/7
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Disponibilité
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Fonctionnalités */}
        <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 4 }}>
          Technologies & Fonctionnalités
        </Typography>
        <Grid container spacing={3} sx={{ mb: 6 }}>
          {features.map((feature, index) => (
            <Grid item xs={12} sm={6} md={3} key={index}>
              <Card sx={{ height: '100%', textAlign: 'center' }}>
                <CardContent>
                  <Avatar sx={{ bgcolor: 'primary.light', mx: 'auto', mb: 2, width: 56, height: 56 }}>
                    {feature.icon}
                  </Avatar>
                  <Typography variant="h6" gutterBottom>
                    {feature.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {feature.description}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Architecture */}
        <Grid container spacing={4} sx={{ mb: 6 }}>
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h5" gutterBottom>
                🏗️ Architecture Microservices
              </Typography>
              <List>
                {microservices.map((service, index) => (
                  <ListItem key={index}>
                    <ListItemIcon>
                      <Chip
                        size="small"
                        label={service.status}
                        color={service.status === 'UP' ? 'success' : 'error'}
                      />
                    </ListItemIcon>
                    <ListItemText
                      primary={service.name}
                      secondary={service.description}
                    />
                  </ListItem>
                ))}
              </List>
            </Paper>
          </Grid>
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h5" gutterBottom>
                ☁️ Infrastructure Cloud
              </Typography>
              <List>
                <ListItem>
                  <ListItemIcon><CheckCircle color="success" /></ListItemIcon>
                  <ListItemText primary="AWS EKS" secondary="Cluster Kubernetes managé" />
                </ListItem>
                <ListItem>
                  <ListItemIcon><CheckCircle color="success" /></ListItemIcon>
                  <ListItemText primary="Application Load Balancer" secondary="Répartition de charge intelligente" />
                </ListItem>
                <ListItem>
                  <ListItemIcon><CheckCircle color="success" /></ListItemIcon>
                  <ListItemText primary="AWS RDS MySQL" secondary="Base de données relationnelle" />
                </ListItem>
                <ListItem>
                  <ListItemIcon><CheckCircle color="success" /></ListItemIcon>
                  <ListItemText primary="AWS ElastiCache Redis" secondary="Cache in-memory" />
                </ListItem>
                <ListItem>
                  <ListItemIcon><CheckCircle color="success" /></ListItemIcon>
                  <ListItemText primary="AWS MSK Kafka" secondary="Streaming d'événements" />
                </ListItem>
                <ListItem>
                  <ListItemIcon><CheckCircle color="success" /></ListItemIcon>
                  <ListItemText primary="Prometheus + Grafana" secondary="Monitoring et alertes" />
                </ListItem>
              </List>
            </Paper>
          </Grid>
        </Grid>

        {/* Call to Action */}
        <Paper
          sx={{
            p: 4,
            textAlign: 'center',
            background: 'linear-gradient(45deg, #FE6B8B 30%, #FF8E53 90%)',
            color: 'white',
            mb: 4
          }}
        >
          <Typography variant="h4" gutterBottom>
            Prêt à Explorer ?
          </Typography>
          <Typography variant="body1" paragraph>
            Découvrez comment cette architecture microservices gère 
            la scalabilité, la résilience et la performance en temps réel.
          </Typography>
          <Box sx={{ display: 'flex', justifyContent: 'center', gap: 2, flexWrap: 'wrap' }}>
            <Button
              variant="contained"
              size="large"
              startIcon={<Store />}
              onClick={() => navigate('/products')}
              sx={{
                bgcolor: 'rgba(255,255,255,0.2)',
                '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' }
              }}
            >
              Parcourir le Catalogue
            </Button>
            <Button
              variant="outlined"
              size="large"
              startIcon={<Dashboard />}
              onClick={() => navigate('/dashboard')}
              sx={{
                borderColor: 'rgba(255,255,255,0.5)',
                color: 'white',
                '&:hover': {
                  borderColor: 'white',
                  bgcolor: 'rgba(255,255,255,0.1)'
                }
              }}
            >
              Voir le Dashboard
            </Button>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default Home;
