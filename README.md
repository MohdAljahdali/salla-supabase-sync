# Salla Supabase Sync Application

🚀 A modern Next.js application for synchronizing data between Salla stores and Supabase database with a beautiful admin dashboard.

## 📋 Project Overview

This application provides a comprehensive solution for fetching data from Salla e-commerce platform and storing it in Supabase database. It features a modern UI built with shadcn/ui components and supports real-time data synchronization.

## 🛠 Technology Stack

- **Frontend Framework**: Next.js 15+ (App Router)
- **UI Library**: shadcn/ui components
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth SSR
- **Styling**: Tailwind CSS
- **Language**: TypeScript
- **Deployment**: Vercel

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ installed
- npm, yarn, pnpm, or bun package manager
- Salla Partner account with API access
- Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/MohdAljahdali/salla-supabase-sync.git
   cd salla-supabase-sync
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   # or
   pnpm install
   # or
   bun install
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env.local
   ```
   
   Fill in your environment variables in `.env.local`:
   ```env
   # Salla API Configuration
   SALLA_CLIENT_ID=your_salla_client_id
   SALLA_CLIENT_SECRET=your_salla_client_secret
   SALLA_WEBHOOK_SECRET=your_salla_webhook_secret
   
   # Supabase Configuration
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   
   # Application Configuration
   NEXT_PUBLIC_APP_URL=http://localhost:3000
   NEXTAUTH_SECRET=your_nextauth_secret
   ```

4. **Run the development server**
   ```bash
   npm run dev
   # or
   yarn dev
   # or
   pnpm dev
   # or
   bun dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000) to see the application.

## 📁 Project Structure

```
salla-sync/
├── src/
│   ├── app/                 # Next.js App Router pages
│   ├── components/          # Reusable UI components
│   │   └── ui/             # shadcn/ui components
│   ├── hooks/              # Custom React hooks
│   ├── lib/                # Utility functions and configurations
│   └── types/              # TypeScript type definitions
├── public/                 # Static assets
├── .env.example           # Environment variables template
├── vercel.json            # Vercel deployment configuration
└── salla-supabase-todo-plan-en.md  # Project development plan
```

## 🔧 Configuration

### Salla API Setup

1. Create a Salla Partner account
2. Register your application in Salla Partner Portal
3. Obtain your Client ID, Client Secret, and Webhook Secret
4. Configure webhook endpoints in your Salla app settings

### Supabase Setup

1. Create a new Supabase project
2. Set up your database tables (refer to the project plan)
3. Configure Row Level Security (RLS)
4. Obtain your project URL and API keys

## 🚀 Deployment on Vercel

### Prerequisites for Deployment

- GitHub repository with your code
- Vercel account
- Environment variables configured

### Step-by-Step Deployment

1. **Push your code to GitHub**
   ```bash
   git add .
   git commit -m "Prepare for Vercel deployment"
   git push origin main
   ```

2. **Connect to Vercel**
   - Go to [Vercel Dashboard](https://vercel.com/dashboard)
   - Click "New Project"
   - Import your GitHub repository

3. **Configure Environment Variables**
   In Vercel dashboard, add all environment variables from your `.env.local`:
   - `SALLA_CLIENT_ID`
   - `SALLA_CLIENT_SECRET`
   - `SALLA_WEBHOOK_SECRET`
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `NEXTAUTH_SECRET`
   - `NEXT_PUBLIC_APP_URL` (set to your Vercel domain)

4. **Deploy**
   - Click "Deploy"
   - Wait for the build to complete
   - Your app will be available at `https://your-app.vercel.app`

### Vercel Configuration Features

Our `vercel.json` includes:
- **Security Headers**: XSS protection, content type options, frame options
- **CORS Configuration**: For API endpoints
- **Function Timeouts**: Extended timeouts for webhook processing
- **Cron Jobs**: Automated data synchronization and cleanup
- **Redirects & Rewrites**: URL management

## 🔄 Data Synchronization

The application supports:
- **Real-time sync** via Salla webhooks
- **Scheduled sync** via Vercel cron jobs (every 6 hours)
- **Manual sync** through the admin dashboard
- **Incremental sync** for performance optimization

## 🎨 UI Components

Built with shadcn/ui components including:
- Data tables with sorting and filtering
- Interactive charts and graphs
- Real-time notifications
- Responsive design
- Dark/light mode support
- RTL support for Arabic content

## 📊 Features

- **Admin Dashboard**: Comprehensive analytics and management
- **Product Management**: Full CRUD operations
- **Order Processing**: Order tracking and management
- **Customer Management**: Customer profiles and analytics
- **Inventory Tracking**: Real-time stock monitoring
- **Financial Reports**: Revenue and profit analysis
- **Webhook Integration**: Real-time data updates
- **Multi-store Support**: Manage multiple Salla stores

## 🔒 Security

- Environment variable protection
- API rate limiting
- Webhook signature verification
- Row Level Security (RLS) in Supabase
- CORS configuration
- Security headers

## 📈 Performance

- Next.js App Router for optimal performance
- Image optimization
- Code splitting
- Caching strategies
- Database query optimization

## 🧪 Testing

Run tests with:
```bash
npm run test
# or
yarn test
```

## 📝 Development Plan

Refer to `salla-supabase-todo-plan-en.md` for the complete development roadmap and progress tracking.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the project documentation
- Review the development plan

## 🔗 Links

- [Salla API Documentation](https://docs.salla.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [shadcn/ui Documentation](https://ui.shadcn.com/)
- [Vercel Documentation](https://vercel.com/docs)

---

**Built with ❤️ using Next.js, Supabase, and shadcn/ui**
