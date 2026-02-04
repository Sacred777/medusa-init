# Medusa E-commerce Platform

## Project Overview

This project is a full-stack e-commerce platform built with MedusaJS as the backend and Next.js as the frontend storefront. It follows a headless commerce architecture, allowing for flexible frontend development while leveraging Medusa's robust commerce capabilities.

### Architecture Components

1. **medusa-store (Backend)**:
   - Framework: MedusaJS v2.12.6
   - Database: PostgreSQL (running in Docker)
   - Caching: Redis (running in Docker)
   - Admin Panel: Built-in Medusa admin
   - Configuration: Docker Compose for local deployment

2. **medusa-storefront (Frontend)**:
   - Framework: Next.js 15.3.8 (using App Router)
   - Styling: Tailwind CSS
   - UI Components: @medusajs/ui
   - SDK: @medusajs/js-sdk for API communication

## Building and Running

### Backend Setup (medusa-store)

1. Navigate to the backend directory:
   ```bash
   cd medusa-store
   ```

2. Install dependencies:
   ```bash
   yarn install
   ```

3. Copy the environment template:
   ```bash
   cp .env.template .env
   ```
   
   Note: Comment out the DATABASE_URL, REDIS_URL, and DB_NAME variables in .env since they're defined in docker-compose.yml

4. Start services using Docker:
   ```bash
   yarn docker:up
   ```

5. Create an admin user:
   ```bash
   docker compose exec medusa yarn medusa user -e admin@example.com -p supersecret
   ```

### Frontend Setup (medusa-storefront)

1. Navigate to the storefront directory:
   ```bash
   cd medusa-storefront
   ```

2. Install dependencies:
   ```bash
   yarn install
   ```

3. Copy the environment template:
   ```bash
   cp .env.template .env.local
   ```

4. Configure environment variables in `.env.local`:
   - `MEDUSA_BACKEND_URL=http://localhost:9000`
   - `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=[your_publishable_key_from_admin_panel]`
   - `NEXT_PUBLIC_BASE_URL=http://localhost:8000`
   - `NEXT_PUBLIC_DEFAULT_REGION=us`

5. Start the development server:
   ```bash
   yarn dev
   ```

The storefront will be accessible at http://localhost:8000

## Development Conventions

- Use Yarn as the package manager
- Follow the environment variable configuration as described in the README
- Use Docker for consistent local development environments
- The project follows standard Next.js and MedusaJS conventions
- TypeScript is used throughout the codebase
- Tailwind CSS is used for styling with Medusa's UI components

## Key Features

- Full e-commerce functionality (products, categories, cart, checkout)
- User accounts and order management
- Admin panel for managing products and orders
- Stripe payment integration
- Internationalization support
- Responsive design with Tailwind CSS

## Troubleshooting

Common issues and solutions:

1. **CORS Issues**: Ensure STORE_CORS includes your storefront URL and ADMIN_CORS includes your admin URL
2. **Database Connection**: Verify Docker containers are running and DATABASE_URL matches docker-compose.yml settings
3. **Publishable Key Issues**: Ensure the key is properly copied from the admin panel and associated with the correct sales channel

## Stopping Services

To stop the backend Docker services:
```bash
cd medusa-store
yarn docker:down
```

To stop the frontend, use Ctrl+C in the terminal where it's running.