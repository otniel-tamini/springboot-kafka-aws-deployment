import React, { useState, useEffect } from 'react';
import {
  Container,
  Grid,
  Paper,
  Typography,
  Box,
  Card,
  CardContent,
  Chip,
  LinearProgress,
  Alert,
  Button,
  Refresh
} from '@mui/material';
import {
  CheckCircle,
  Error,
  Warning,
  Info,
  Speed,
  Storage,
  Cloud,
  Security
} from '@mui/icons-material';
import { healthService } from '../services/api';

const Dashboard = () => {
  const [servicesHealth, setServicesHealth] = useState([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  useEffect(() => {
    checkServicesHealth();
    
    // Actualiser toutes les 30 secondes
    const interval = setInterval(checkServicesHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const checkServicesHealth = async () => {
    try {
      setLoading(true);
      const health = await healthService.checkAllServices();
      setServicesHealth(health);
      setLastUpdate(new Date());
    } catch (error) {
      console.error('Erreur lors de la vérification de santé:', error);
    } finally {
      setLoading(false);
    }
  };

  const getOverallHealth = () => {
    const upServices = servicesHealth.filter(s => s.status === 'UP').length;
    const totalServices = servicesHealth.length;
    return { up: upServices, total: totalServices, percentage: (upServices / totalServices) * 100 };
  };

  const getServiceIcon = (serviceName) => {
    const icons = {
      'product': <Storage />,
      'order': <Speed />,
      'payment': <Security />,
      'identity': <Security />,
      'email': <Cloud />
    };
    return icons[serviceName] || <Info />;
  };

  const getServiceDescription = (serviceName) => {
    const descriptions = {
      'product': 'Gestion du catalogue produits',
      'order': 'Traitement des commandes',
      'payment': 'Traitement des paiements',
      'identity': 'Authentification et autorisation',
      'email': 'Service de notification par email'
    };
    return descriptions[serviceName] || 'Service microservice';
  };

  const overallHealth = getOverallHealth();

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h4" component="h1">
          Dashboard Microservices
        </Typography>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={checkServicesHealth}
          disabled={loading}
        >
          Actualiser
        </Button>
      </Box>

      {/* Vue d'ensemble */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <CheckCircle color="success" sx={{ mr: 1 }} />
                <Typography variant="h6">État Général</Typography>
              </Box>
              <Typography variant="h3" color="primary">
                {overallHealth.up}/{overallHealth.total}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Services opérationnels
              </Typography>
              <LinearProgress
                variant="determinate"
                value={overallHealth.percentage}
                color={overallHealth.percentage === 100 ? 'success' : 'warning'}
                sx={{ mt: 2 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Speed color="info" sx={{ mr: 1 }} />
                <Typography variant="h6">Performance</Typography>
              </Box>
              <Typography variant="h3" color="info">
                {overallHealth.percentage.toFixed(0)}%
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Disponibilité globale
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Info color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Dernière MAJ</Typography>
              </Box>
              <Typography variant="body1">
                {lastUpdate.toLocaleTimeString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {lastUpdate.toLocaleDateString()}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* État des services */}
      <Paper sx={{ p: 3, mb: 4 }}>
        <Typography variant="h5" gutterBottom>
          État des Microservices
        </Typography>
        
        {loading && <LinearProgress sx={{ mb: 2 }} />}
        
        <Grid container spacing={2}>
          {servicesHealth.map((service) => (
            <Grid item xs={12} md={6} lg={4} key={service.service}>
              <Card variant="outlined">
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    {getServiceIcon(service.service)}
                    <Typography variant="h6" sx={{ ml: 1, flexGrow: 1 }}>
                      {service.service.charAt(0).toUpperCase() + service.service.slice(1)} Service
                    </Typography>
                    <Chip
                      label={service.status}
                      color={service.status === 'UP' ? 'success' : 'error'}
                      size="small"
                      icon={service.status === 'UP' ? <CheckCircle /> : <Error />}
                    />
                  </Box>
                  
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {getServiceDescription(service.service)}
                  </Typography>

                  {service.status === 'UP' && service.details && (
                    <Box>
                      <Typography variant="caption" color="text.secondary">
                        Statut: {service.details.status}
                      </Typography>
                      {service.details.components && (
                        <Box sx={{ mt: 1 }}>
                          {Object.entries(service.details.components).map(([key, value]) => (
                            <Chip
                              key={key}
                              label={`${key}: ${value.status}`}
                              size="small"
                              variant="outlined"
                              sx={{ mr: 0.5, mb: 0.5 }}
                              color={value.status === 'UP' ? 'success' : 'warning'}
                            />
                          ))}
                        </Box>
                      )}
                    </Box>
                  )}

                  {service.status === 'DOWN' && (
                    <Alert severity="error" sx={{ mt: 1 }}>
                      Service indisponible: {service.error}
                    </Alert>
                  )}
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Paper>

      {/* Informations système */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h5" gutterBottom>
          Architecture du Système
        </Typography>
        
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Typography variant="h6" gutterBottom>
              🏗️ Infrastructure
            </Typography>
            <ul>
              <li>Cluster EKS Kubernetes</li>
              <li>AWS Application Load Balancer</li>
              <li>AWS RDS MySQL</li>
              <li>AWS ElastiCache Redis</li>
              <li>AWS MSK Kafka</li>
            </ul>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Typography variant="h6" gutterBottom>
              🚀 Services Déployés
            </Typography>
            <ul>
              <li>Service Registry (Eureka)</li>
              <li>API Gateway (Spring Cloud Gateway)</li>
              <li>Product Service</li>
              <li>Order Service</li>
              <li>Payment Service</li>
              <li>Identity Service</li>
              <li>Email Service</li>
            </ul>
          </Grid>
        </Grid>

        <Box sx={{ mt: 3, p: 2, bgcolor: 'grey.100', borderRadius: 1 }}>
          <Typography variant="body2" color="text.secondary">
            💡 Ce dashboard surveille en temps réel la santé de tous les microservices.
            Les services communiquent via Apache Kafka pour les événements asynchrones
            et utilisent le service discovery Eureka pour la découverte de services.
          </Typography>
        </Box>
      </Paper>
    </Container>
  );
};

export default Dashboard;
