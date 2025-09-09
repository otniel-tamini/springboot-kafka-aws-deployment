import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  Chip,
  Box,
  Divider,
  Alert,
  CircularProgress
} from '@mui/material';
import {
  ShoppingBag,
  Payment,
  LocalShipping,
  CheckCircle,
  Error,
  Schedule
} from '@mui/icons-material';
import { orderService, identityService } from '../services/api';

const OrderList = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    try {
      setLoading(true);
      const user = identityService.getCurrentUser();
      if (user) {
        const response = await orderService.getUserOrders(user.id);
        setOrders(response);
      } else {
        // Charger toutes les commandes pour un admin
        const response = await orderService.getOrders();
        setOrders(response.content || response);
      }
      setError(null);
    } catch (err) {
      setError('Erreur lors du chargement des commandes');
      console.error('Erreur:', err);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'pending': return 'warning';
      case 'confirmed': return 'info';
      case 'processing': return 'primary';
      case 'shipped': return 'secondary';
      case 'delivered': return 'success';
      case 'cancelled': return 'error';
      default: return 'default';
    }
  };

  const getStatusIcon = (status) => {
    switch (status?.toLowerCase()) {
      case 'pending': return <Schedule />;
      case 'confirmed': return <Payment />;
      case 'processing': return <ShoppingBag />;
      case 'shipped': return <LocalShipping />;
      case 'delivered': return <CheckCircle />;
      case 'cancelled': return <Error />;
      default: return <Schedule />;
    }
  };

  const getStatusLabel = (status) => {
    const labels = {
      'pending': 'En attente',
      'confirmed': 'Confirmée',
      'processing': 'En préparation',
      'shipped': 'Expédiée',
      'delivered': 'Livrée',
      'cancelled': 'Annulée'
    };
    return labels[status?.toLowerCase()] || status;
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  if (error) {
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Alert severity="error">
          {error}
          <Button onClick={loadOrders} sx={{ ml: 2 }}>
            Réessayer
          </Button>
        </Alert>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Mes Commandes
      </Typography>

      {orders.length === 0 ? (
        <Alert severity="info">
          Aucune commande trouvée.
          <Button href="/products" sx={{ ml: 2 }}>
            Commencer mes achats
          </Button>
        </Alert>
      ) : (
        <Grid container spacing={3}>
          {orders.map((order) => (
            <Grid item xs={12} key={order.id}>
              <Card>
                <CardContent>
                  {/* En-tête de la commande */}
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', mb: 2 }}>
                    <Box>
                      <Typography variant="h6" component="h2">
                        Commande #{order.id}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {new Date(order.createdAt || order.orderDate).toLocaleDateString('fr-FR', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </Typography>
                    </Box>
                    <Chip
                      label={getStatusLabel(order.status)}
                      color={getStatusColor(order.status)}
                      icon={getStatusIcon(order.status)}
                    />
                  </Box>

                  <Divider sx={{ my: 2 }} />

                  {/* Détails de la commande */}
                  <Grid container spacing={2}>
                    <Grid item xs={12} md={8}>
                      <Typography variant="subtitle1" gutterBottom>
                        Articles commandés
                      </Typography>
                      {order.items?.map((item, index) => (
                        <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                          <Typography variant="body2">
                            {item.productName || item.name} × {item.quantity}
                          </Typography>
                          <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                            {(item.price * item.quantity).toFixed(2)} €
                          </Typography>
                        </Box>
                      )) || (
                        <Typography variant="body2" color="text.secondary">
                          Détails des articles non disponibles
                        </Typography>
                      )}
                    </Grid>

                    <Grid item xs={12} md={4}>
                      <Box sx={{ textAlign: 'right' }}>
                        <Typography variant="subtitle1" gutterBottom>
                          Récapitulatif
                        </Typography>
                        <Typography variant="body2">
                          Sous-total: {order.subtotal?.toFixed(2) || '0.00'} €
                        </Typography>
                        <Typography variant="body2">
                          Livraison: {order.shippingCost?.toFixed(2) || '0.00'} €
                        </Typography>
                        <Typography variant="body2">
                          TVA: {order.tax?.toFixed(2) || '0.00'} €
                        </Typography>
                        <Divider sx={{ my: 1 }} />
                        <Typography variant="h6" color="primary">
                          Total: {order.totalAmount?.toFixed(2) || order.total?.toFixed(2) || '0.00'} €
                        </Typography>
                      </Box>
                    </Grid>
                  </Grid>

                  {/* Adresse de livraison */}
                  {order.shippingAddress && (
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="subtitle2" gutterBottom>
                        Adresse de livraison
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {order.shippingAddress.street}<br />
                        {order.shippingAddress.city}, {order.shippingAddress.postalCode}<br />
                        {order.shippingAddress.country}
                      </Typography>
                    </Box>
                  )}

                  {/* Informations de suivi */}
                  {order.trackingNumber && (
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="subtitle2" gutterBottom>
                        Suivi
                      </Typography>
                      <Typography variant="body2">
                        Numéro de suivi: <strong>{order.trackingNumber}</strong>
                      </Typography>
                    </Box>
                  )}
                </CardContent>

                <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                  <Box>
                    {order.status?.toLowerCase() === 'pending' && (
                      <Button
                        variant="outlined"
                        color="error"
                        onClick={() => {/* Annuler la commande */}}
                      >
                        Annuler
                      </Button>
                    )}
                  </Box>
                  <Box>
                    <Button variant="outlined" sx={{ mr: 1 }}>
                      Détails
                    </Button>
                    {order.status?.toLowerCase() === 'delivered' && (
                      <Button variant="contained">
                        Noter
                      </Button>
                    )}
                    {order.trackingNumber && (
                      <Button variant="contained" sx={{ ml: 1 }}>
                        Suivre
                      </Button>
                    )}
                  </Box>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}
    </Container>
  );
};

export default OrderList;
