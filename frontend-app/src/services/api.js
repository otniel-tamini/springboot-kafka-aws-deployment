import apiClient from './apiClient';

// =================================
// PRODUCT SERVICE API
// =================================
export const productService = {
  // Récupérer tous les produits
  getProducts: async (page = 0, size = 10) => {
    const response = await apiClient.get(`/product/api/products?page=${page}&size=${size}`);
    return response.data;
  },

  // Récupérer un produit par ID
  getProductById: async (id) => {
    const response = await apiClient.get(`/product/api/products/${id}`);
    return response.data;
  },

  // Créer un nouveau produit
  createProduct: async (product) => {
    const response = await apiClient.post('/product/api/products', product);
    return response.data;
  },

  // Mettre à jour un produit
  updateProduct: async (id, product) => {
    const response = await apiClient.put(`/product/api/products/${id}`, product);
    return response.data;
  },

  // Supprimer un produit
  deleteProduct: async (id) => {
    const response = await apiClient.delete(`/product/api/products/${id}`);
    return response.data;
  },

  // Rechercher des produits
  searchProducts: async (query) => {
    const response = await apiClient.get(`/product/api/products/search?q=${query}`);
    return response.data;
  },

  // Récupérer les produits par catégorie
  getProductsByCategory: async (category) => {
    const response = await apiClient.get(`/product/api/products/category/${category}`);
    return response.data;
  }
};

// =================================
// ORDER SERVICE API
// =================================
export const orderService = {
  // Récupérer toutes les commandes
  getOrders: async (page = 0, size = 10) => {
    const response = await apiClient.get(`/order/api/orders?page=${page}&size=${size}`);
    return response.data;
  },

  // Récupérer une commande par ID
  getOrderById: async (id) => {
    const response = await apiClient.get(`/order/api/orders/${id}`);
    return response.data;
  },

  // Créer une nouvelle commande
  createOrder: async (order) => {
    const response = await apiClient.post('/order/api/orders', order);
    return response.data;
  },

  // Mettre à jour le statut d'une commande
  updateOrderStatus: async (id, status) => {
    const response = await apiClient.patch(`/order/api/orders/${id}/status`, { status });
    return response.data;
  },

  // Annuler une commande
  cancelOrder: async (id) => {
    const response = await apiClient.patch(`/order/api/orders/${id}/cancel`);
    return response.data;
  },

  // Récupérer les commandes d'un utilisateur
  getUserOrders: async (userId) => {
    const response = await apiClient.get(`/order/api/orders/user/${userId}`);
    return response.data;
  }
};

// =================================
// PAYMENT SERVICE API
// =================================
export const paymentService = {
  // Initier un paiement
  initiatePayment: async (paymentData) => {
    const response = await apiClient.post('/payment/api/payments', paymentData);
    return response.data;
  },

  // Confirmer un paiement
  confirmPayment: async (paymentId, confirmationData) => {
    const response = await apiClient.patch(`/payment/api/payments/${paymentId}/confirm`, confirmationData);
    return response.data;
  },

  // Récupérer l'historique des paiements
  getPaymentHistory: async (userId) => {
    const response = await apiClient.get(`/payment/api/payments/user/${userId}`);
    return response.data;
  },

  // Rembourser un paiement
  refundPayment: async (paymentId, amount) => {
    const response = await apiClient.post(`/payment/api/payments/${paymentId}/refund`, { amount });
    return response.data;
  }
};

// =================================
// IDENTITY SERVICE API
// =================================
export const identityService = {
  // Connexion utilisateur
  login: async (credentials) => {
    const response = await apiClient.post('/identity/api/auth/login', credentials);
    if (response.data.token) {
      localStorage.setItem('authToken', response.data.token);
      localStorage.setItem('user', JSON.stringify(response.data.user));
    }
    return response.data;
  },

  // Inscription utilisateur
  register: async (userData) => {
    const response = await apiClient.post('/identity/api/auth/register', userData);
    return response.data;
  },

  // Déconnexion
  logout: () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
  },

  // Récupérer le profil utilisateur
  getProfile: async () => {
    const response = await apiClient.get('/identity/api/users/profile');
    return response.data;
  },

  // Mettre à jour le profil
  updateProfile: async (userData) => {
    const response = await apiClient.put('/identity/api/users/profile', userData);
    return response.data;
  },

  // Vérifier si l'utilisateur est connecté
  isAuthenticated: () => {
    return !!localStorage.getItem('authToken');
  },

  // Récupérer l'utilisateur actuel
  getCurrentUser: () => {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  }
};

// =================================
// EMAIL SERVICE API
// =================================
export const emailService = {
  // Envoyer un email de confirmation
  sendConfirmationEmail: async (orderId) => {
    const response = await apiClient.post(`/email/api/emails/order-confirmation/${orderId}`);
    return response.data;
  },

  // Envoyer un email de newsletter
  subscribeNewsletter: async (email) => {
    const response = await apiClient.post('/email/api/emails/newsletter/subscribe', { email });
    return response.data;
  },

  // Envoyer un email de support
  sendSupportEmail: async (supportData) => {
    const response = await apiClient.post('/email/api/emails/support', supportData);
    return response.data;
  }
};

// =================================
// HEALTH CHECKS API
// =================================
export const healthService = {
  // Vérifier la santé de tous les services
  checkAllServices: async () => {
    const services = ['product', 'order', 'payment', 'identity', 'email'];
    const healthChecks = await Promise.allSettled(
      services.map(async (service) => {
        try {
          const response = await apiClient.get(`/${service}/actuator/health`);
          return { service, status: 'UP', details: response.data };
        } catch (error) {
          return { service, status: 'DOWN', error: error.message };
        }
      })
    );
    return healthChecks.map(result => result.value);
  },

  // Vérifier la santé d'un service spécifique
  checkServiceHealth: async (serviceName) => {
    try {
      const response = await apiClient.get(`/${serviceName}/actuator/health`);
      return { service: serviceName, status: 'UP', details: response.data };
    } catch (error) {
      return { service: serviceName, status: 'DOWN', error: error.message };
    }
  }
};
