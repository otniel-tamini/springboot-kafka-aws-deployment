import React, { useState, useEffect } from 'react';
import {
  Grid,
  Card,
  CardMedia,
  CardContent,
  CardActions,
  Typography,
  Button,
  Chip,
  Box,
  CircularProgress,
  Alert,
  TextField,
  InputAdornment,
  Fab
} from '@mui/material';
import {
  Add,
  Search,
  ShoppingCart,
  Euro,
  Star
} from '@mui/icons-material';
import { productService } from '../services/api';
import { toast } from 'react-toastify';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredProducts, setFilteredProducts] = useState([]);

  useEffect(() => {
    loadProducts();
  }, []);

  useEffect(() => {
    // Filtrer les produits selon la recherche
    if (searchQuery.trim() === '') {
      setFilteredProducts(products);
    } else {
      const filtered = products.filter(product =>
        product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        product.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
        product.category.toLowerCase().includes(searchQuery.toLowerCase())
      );
      setFilteredProducts(filtered);
    }
  }, [searchQuery, products]);

  const loadProducts = async () => {
    try {
      setLoading(true);
      const response = await productService.getProducts(0, 50);
      setProducts(response.content || response);
      setError(null);
    } catch (err) {
      setError('Erreur lors du chargement des produits');
      console.error('Erreur:', err);
    } finally {
      setLoading(false);
    }
  };

  const addToCart = (product) => {
    try {
      const cart = JSON.parse(localStorage.getItem('cart') || '[]');
      const existingItem = cart.find(item => item.id === product.id);

      if (existingItem) {
        existingItem.quantity += 1;
      } else {
        cart.push({ ...product, quantity: 1 });
      }

      localStorage.setItem('cart', JSON.stringify(cart));
      toast.success(`${product.name} ajouté au panier !`);
      
      // Mettre à jour le badge du panier
      window.dispatchEvent(new Event('cartUpdated'));
    } catch (err) {
      toast.error('Erreur lors de l\'ajout au panier');
    }
  };

  const getStockColor = (stock) => {
    if (stock > 10) return 'success';
    if (stock > 5) return 'warning';
    return 'error';
  };

  const getStockLabel = (stock) => {
    if (stock > 10) return 'En stock';
    if (stock > 5) return 'Stock limité';
    if (stock > 0) return 'Dernières pièces';
    return 'Rupture de stock';
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        {error}
        <Button onClick={loadProducts} sx={{ ml: 2 }}>
          Réessayer
        </Button>
      </Alert>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête avec recherche */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Catalogue Produits
        </Typography>
        <TextField
          fullWidth
          variant="outlined"
          placeholder="Rechercher des produits..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search />
              </InputAdornment>
            ),
          }}
          sx={{ maxWidth: 500 }}
        />
      </Box>

      {/* Grille des produits */}
      <Grid container spacing={3}>
        {filteredProducts.map((product) => (
          <Grid item xs={12} sm={6} md={4} lg={3} key={product.id}>
            <Card 
              sx={{ 
                height: '100%', 
                display: 'flex', 
                flexDirection: 'column',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 4
                }
              }}
            >
              <CardMedia
                component="img"
                height="200"
                image={product.imageUrl || 'https://via.placeholder.com/300x200?text=Produit'}
                alt={product.name}
                sx={{ objectFit: 'cover' }}
              />
              
              <CardContent sx={{ flexGrow: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', mb: 1 }}>
                  <Typography variant="h6" component="h2" noWrap>
                    {product.name}
                  </Typography>
                  <Chip 
                    label={product.category} 
                    size="small" 
                    color="primary" 
                    variant="outlined"
                  />
                </Box>
                
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {product.description}
                </Typography>

                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <Typography variant="h5" component="span" color="primary" sx={{ fontWeight: 'bold' }}>
                    {product.price?.toFixed(2)}
                  </Typography>
                  <Euro sx={{ ml: 0.5, fontSize: '1.2rem' }} />
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Chip
                    label={getStockLabel(product.stock)}
                    color={getStockColor(product.stock)}
                    size="small"
                  />
                  {product.rating && (
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <Star sx={{ color: 'gold', fontSize: '1rem' }} />
                      <Typography variant="caption" sx={{ ml: 0.5 }}>
                        {product.rating}
                      </Typography>
                    </Box>
                  )}
                </Box>
              </CardContent>

              <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                <Button size="small" variant="outlined">
                  Détails
                </Button>
                <Button
                  size="small"
                  variant="contained"
                  startIcon={<ShoppingCart />}
                  onClick={() => addToCart(product)}
                  disabled={product.stock === 0}
                >
                  Ajouter
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {filteredProducts.length === 0 && !loading && (
        <Box textAlign="center" sx={{ mt: 4 }}>
          <Typography variant="h6" color="text.secondary">
            {searchQuery ? 'Aucun produit trouvé pour cette recherche' : 'Aucun produit disponible'}
          </Typography>
        </Box>
      )}

      {/* Bouton flottant pour ajouter un produit (admin) */}
      <Fab
        color="primary"
        aria-label="add"
        sx={{ position: 'fixed', bottom: 16, right: 16 }}
        onClick={() => {/* Navigation vers création produit */}}
      >
        <Add />
      </Fab>
    </Box>
  );
};

export default ProductList;
