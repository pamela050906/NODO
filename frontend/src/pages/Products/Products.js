import React, { useState, useEffect } from 'react';
import Layout from '../../components/Layout';
import { productService } from '../../services/apiService';
import { Package, Plus, Search, Pencil, Trash2 } from 'lucide-react';
import './Products.css';

function Products() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [formData, setFormData] = useState({
    nombre: '',
    descripcion: '',
    precio: '',
    stock_actual: '',
    stock_minimo: '',
    codigo_barras: '',
    categoria: '',
  });
  const [message, setMessage] = useState({ type: '', text: '' });

  useEffect(() => {
    loadProducts();
  }, []);

  const loadProducts = async () => {
    try {
      setLoading(true);
      const data = await productService.getAll();
      setProducts(data);
    } catch (error) {
      console.error('Error cargando productos:', error);
      setMessage({ type: 'error', text: 'Error al cargar productos' });
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (e) => {
    setSearchTerm(e.target.value);
  };

  const filteredProducts = products.filter((product) =>
    product.nombre?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.codigo_barras?.includes(searchTerm) ||
    product.categoria?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleOpenModal = (product = null) => {
    if (product) {
      setEditingProduct(product);
      setFormData({
        nombre: product.nombre || '',
        descripcion: product.descripcion || '',
        precio: product.precio || '',
        stock_actual: product.stock_actual || '',
        stock_minimo: product.stock_minimo || '',
        codigo_barras: product.codigo_barras || '',
        categoria: product.categoria || '',
      });
    } else {
      setEditingProduct(null);
      setFormData({
        nombre: '',
        descripcion: '',
        precio: '',
        stock_actual: '',
        stock_minimo: '',
        codigo_barras: '',
        categoria: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingProduct(null);
    setFormData({
      nombre: '',
      descripcion: '',
      precio: '',
      stock_actual: '',
      stock_minimo: '',
      codigo_barras: '',
      categoria: '',
    });
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      const productData = {
        ...formData,
        precio: parseFloat(formData.precio),
        stock_actual: parseInt(formData.stock_actual),
        stock_minimo: parseInt(formData.stock_minimo),
      };

      if (editingProduct) {
        await productService.update(editingProduct.id, productData);
        setMessage({ type: 'success', text: 'Producto actualizado exitosamente' });
      } else {
        await productService.create(productData);
        setMessage({ type: 'success', text: 'Producto creado exitosamente' });
      }

      handleCloseModal();
      loadProducts();
      setTimeout(() => setMessage({ type: '', text: '' }), 3000);
    } catch (error) {
      console.error('Error guardando producto:', error);
      setMessage({
        type: 'error',
        text: `❌ ${error.response?.data?.detail || 'Error al guardar producto'}`,
      });
    }
  };

  const handleDelete = async (productId) => {
    if (window.confirm('¿Estás seguro de eliminar este producto?')) {
      try {
        await productService.delete(productId);
        setMessage({ type: 'success', text: '✅ Producto eliminado' });
        loadProducts();
        setTimeout(() => setMessage({ type: '', text: '' }), 3000);
      } catch (error) {
        console.error('Error eliminando producto:', error);
        setMessage({ type: 'error', text: '❌ Error al eliminar producto' });
      }
    }
  };

  if (loading) {
    return (
      <Layout>
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Cargando productos...</p>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="products">
        <div className="products-header">
          <h1 className="page-title">📦 Productos</h1>
          <button className="btn btn-primary" onClick={() => handleOpenModal()}>
            ➕ Nuevo Producto
          </button>
        </div>

        {message.text && (
          <div className={`alert alert-${message.type}`}>
            {message.text}
          </div>
        )}

        <div className="card">
          <div className="products-controls">
            <input
              type="text"
              className="search-input"
              placeholder="Buscar por nombre, código de barras o categoría..."
              value={searchTerm}
              onChange={handleSearch}
            />
          </div>

          {filteredProducts.length > 0 ? (
            <div className="products-table-container">
              <table className="table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Nombre</th>
                    <th>Código de Barras</th>
                    <th>Categoría</th>
                    <th>Precio</th>
                    <th>Stock</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredProducts.map((product) => (
                    <tr key={product.id}>
                      <td>#{product.id}</td>
                      <td className="product-name">{product.nombre}</td>
                      <td>{product.codigo_barras}</td>
                      <td>
                        <span className="badge badge-info">{product.categoria}</span>
                      </td>
                      <td className="text-price">${product.precio?.toFixed(2)}</td>
                      <td>
                        <span
                          className={`stock-badge ${
                            product.stock_actual <= product.stock_minimo
                              ? 'stock-low'
                              : 'stock-ok'
                          }`}
                        >
                          {product.stock_actual}
                        </span>
                      </td>
                      <td>
                        <span
                          className={`badge ${
                            product.activo ? 'badge-success' : 'badge-secondary'
                          }`}
                        >
                          {product.activo ? 'Activo' : 'Inactivo'}
                        </span>
                      </td>
                      <td className="actions-cell">
                        <button
                          className="btn-icon btn-edit"
                          onClick={() => handleOpenModal(product)}
                          title="Editar"
                        >
                          ✏️
                        </button>
                        <button
                          className="btn-icon btn-delete"
                          onClick={() => handleDelete(product.id)}
                          title="Eliminar"
                        >
                          🗑️
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="empty-state">
              <p className="d-flex align-items-center justify-content-center gap-2">
                <Package size={24} className="opacity-75" />
                No se encontraron productos
              </p>
            </div>
          )}
        </div>

        {/* Modal */}
        {showModal && (
          <div className="modal-overlay" onClick={handleCloseModal}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>{editingProduct ? 'Editar Producto' : 'Nuevo Producto'}</h2>
                <button className="btn-close" onClick={handleCloseModal}>
                  ✕
                </button>
              </div>

              <form onSubmit={handleSubmit} className="modal-form">
                <div className="form-group">
                  <label htmlFor="nombre">Nombre *</label>
                  <input
                    type="text"
                    id="nombre"
                    name="nombre"
                    className="form-control"
                    value={formData.nombre}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="descripcion">Descripción</label>
                  <textarea
                    id="descripcion"
                    name="descripcion"
                    className="form-control"
                    value={formData.descripcion}
                    onChange={handleChange}
                    rows="3"
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="precio">Precio *</label>
                    <input
                      type="number"
                      id="precio"
                      name="precio"
                      className="form-control"
                      value={formData.precio}
                      onChange={handleChange}
                      step="0.01"
                      min="0"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label htmlFor="codigo_barras">Código de Barras *</label>
                    <input
                      type="text"
                      id="codigo_barras"
                      name="codigo_barras"
                      className="form-control"
                      value={formData.codigo_barras}
                      onChange={handleChange}
                      required
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="stock_actual">Stock Actual *</label>
                    <input
                      type="number"
                      id="stock_actual"
                      name="stock_actual"
                      className="form-control"
                      value={formData.stock_actual}
                      onChange={handleChange}
                      min="0"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label htmlFor="stock_minimo">Stock Mínimo *</label>
                    <input
                      type="number"
                      id="stock_minimo"
                      name="stock_minimo"
                      className="form-control"
                      value={formData.stock_minimo}
                      onChange={handleChange}
                      min="0"
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label htmlFor="categoria">Categoría *</label>
                  <input
                    type="text"
                    id="categoria"
                    name="categoria"
                    className="form-control"
                    value={formData.categoria}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div className="modal-actions">
                  <button type="button" className="btn btn-secondary" onClick={handleCloseModal}>
                    Cancelar
                  </button>
                  <button type="submit" className="btn btn-primary">
                    {editingProduct ? 'Actualizar' : 'Crear'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}

export default Products;
