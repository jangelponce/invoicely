# Invoicely

## Resumen de la Aplicación

Invoicely es una aplicación web moderna para la gestión de facturas construida con Ruby on Rails 8 y React. La aplicación utiliza Inertia.js para crear una experiencia de SPA (Single Page Application) fluida, combinando el poder del backend de Rails con la reactividad del frontend de React.

### Características Principales

- **Gestión de Facturas**: Visualización, filtrado y ordenamiento de facturas con paginación
- **Interfaz Moderna**: Frontend construido con React, TypeScript y Tailwind CSS
- **Reportes Automáticos**: Jobs programados que envían reportes diarios por email con:
  - Top 10 facturas del día anterior
  - Top 10 días con más ventas
- **Cache Inteligente**: Sistema de cache implementado para optimizar consultas de datos
- **Arquitectura Escalable**: Utiliza Solid Queue para trabajos en segundo plano y Solid Cache para almacenamiento en caché

### Stack Tecnológico

**Backend:**
- Ruby on Rails 8.0.2
- PostgreSQL (producción) / SQLite (desarrollo y testing)
- Inertia Rails para integración SPA
- Solid Queue para jobs en segundo plano
- Solid Cache para sistema de cache

**Frontend:**
- React 19 con TypeScript
- Tailwind CSS 4 para estilos
- Vite como bundler
- Inertia.js para comunicación client-server

## Requisitos del Sistema

- Ruby 3.3+
- Node.js 18+
- Mailcatcher (para desarrollo)

## Pasos para la Ejecución

### 1. Instalación de Dependencias

```bash
# Instalar dependencias de Ruby
bundle install

# Instalar dependencias de Node.js
npm install
```

### 2. Configuración de Base de Datos

```bash
# Crear y configurar la base de datos
bin/rails db:create
bin/rails db:migrate
```

### 3. Configuración de Mailcatcher

Mailcatcher es necesario para interceptar y visualizar los emails en desarrollo:

```bash
# Instalar mailcatcher (solo una vez)
gem install mailcatcher

# Ejecutar mailcatcher
mailcatcher
```

Una vez iniciado, podrás ver los emails en: http://localhost:1080

### 4. Habilitar Cache en Desarrollo

Para probar las funcionalidades de cache en desarrollo:

```bash
# Habilitar cache en desarrollo
bin/rails dev:cache
```

Este comando alterna entre habilitar/deshabilitar el cache en el entorno de desarrollo.

### 5. Ejecutar la Aplicación

```bash
# Ejecutar todos los servicios con foreman
./bin/dev
```

Esto iniciará automáticamente:
- Servidor Rails en http://localhost:3100
- Vite dev server para hot reloading de assets

### 6. Ejecutar Tests

```bash
# Ejecutar todos los tests
bundle exec rspec
```

### 7. Ejecutar Jobs en Segundo Plano

```bash
# Ejecutar jobs manualmente
bundle exec rake invoices:send_daily_top_invoices_report
bundle exec rake invoices:send_daily_top_sell_dates_report
```


## Acceso a la Aplicación

Una vez ejecutados todos los pasos:

- **Aplicación Principal**: http://localhost:3100
- **Mailcatcher**: http://localhost:1080 (para ver emails de desarrollo)
- **Interfaz de Facturas**: http://localhost:3100/invoices

## Funcionalidades Disponibles

1. **Listado de Facturas**: Visualiza todas las facturas con filtros por fecha y ordenamiento
2. **Cache de Consultas**: Las consultas se almacenan en cache para mejorar el rendimiento
3. **Reportes Automáticos**: Jobs que se ejecutan diariamente para enviar reportes por email
4. **Interfaz Responsiva**: Diseño adaptable construido con Tailwind CSS
