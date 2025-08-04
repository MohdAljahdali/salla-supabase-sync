# 🚀 Deployment Guide for Vercel

This guide provides step-by-step instructions for deploying the Salla Supabase Sync application to Vercel.

## 📋 Pre-Deployment Checklist

### ✅ Code Preparation
- [ ] All code is committed and pushed to GitHub
- [ ] Environment variables are configured
- [ ] Build process works locally (`npm run build`)
- [ ] All tests pass (`npm run test`)
- [ ] No TypeScript errors (`npm run lint`)

### ✅ External Services Setup
- [ ] Salla Partner account created
- [ ] Salla app registered and configured
- [ ] Supabase project created and configured
- [ ] Database tables created
- [ ] API keys obtained

### ✅ Configuration Files
- [ ] `.env.example` file created
- [ ] `vercel.json` configuration file present
- [ ] `next.config.ts` optimized for production
- [ ] `.gitignore` properly configured

## 🔧 Environment Variables Setup

### Required Environment Variables

Before deploying, ensure you have all these environment variables ready:

```env
# Salla API Configuration
SALLA_CLIENT_ID=your_salla_client_id_here
SALLA_CLIENT_SECRET=your_salla_client_secret_here
SALLA_WEBHOOK_SECRET=your_salla_webhook_secret_here
SALLA_API_BASE_URL=https://api.salla.dev

# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Database Configuration
DATABASE_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres

# Application Configuration
NEXT_PUBLIC_APP_URL=https://your-app.vercel.app
NEXT_PUBLIC_APP_NAME="Salla Supabase Sync"

# Authentication
NEXTAUTH_SECRET=your_secure_random_string_here
NEXTAUTH_URL=https://your-app.vercel.app

# Optional: Redis Configuration
REDIS_URL=your_redis_url_here

# Optional: Email Configuration
SMTP_HOST=your_smtp_host
SMTP_PORT=587
SMTP_USER=your_smtp_user
SMTP_PASSWORD=your_smtp_password
SMTP_FROM=noreply@yourdomain.com

# Logging and Monitoring
LOG_LEVEL=info
SENTRY_DSN=your_sentry_dsn_here

# Production Environment
NODE_ENV=production
```

### How to Generate Secure Secrets

```bash
# Generate NEXTAUTH_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Or use online generator
# https://generate-secret.vercel.app/32
```

## 🚀 Deployment Steps

### Step 1: Prepare Your Repository

1. **Ensure your code is ready**
   ```bash
   # Test build locally
   npm run build
   
   # Check for any errors
   npm run lint
   
   # Run tests if available
   npm run test
   ```

2. **Commit and push your changes**
   ```bash
   git add .
   git commit -m "feat: prepare for Vercel deployment"
   git push origin main
   ```

### Step 2: Connect to Vercel

1. **Go to Vercel Dashboard**
   - Visit [vercel.com/dashboard](https://vercel.com/dashboard)
   - Sign in with your GitHub account

2. **Import Project**
   - Click "New Project"
   - Select "Import Git Repository"
   - Choose your `salla-supabase-sync` repository
   - Click "Import"

### Step 3: Configure Project Settings

1. **Project Configuration**
   - **Project Name**: `salla-supabase-sync`
   - **Framework Preset**: Next.js (auto-detected)
   - **Root Directory**: `./` (default)
   - **Build Command**: `npm run build` (default)
   - **Output Directory**: `.next` (default)
   - **Install Command**: `npm install` (default)

2. **Advanced Settings** (if needed)
   - **Node.js Version**: 18.x (recommended)
   - **Package Manager**: npm

### Step 4: Add Environment Variables

In the Vercel dashboard, go to your project settings and add all environment variables:

1. **Navigate to Environment Variables**
   - Go to your project dashboard
   - Click on "Settings" tab
   - Click on "Environment Variables"

2. **Add Each Variable**
   For each environment variable, add:
   - **Name**: Variable name (e.g., `SALLA_CLIENT_ID`)
   - **Value**: Variable value
   - **Environment**: Select all (Production, Preview, Development)

3. **Important Variables to Add**
   ```
   SALLA_CLIENT_ID
   SALLA_CLIENT_SECRET
   SALLA_WEBHOOK_SECRET
   NEXT_PUBLIC_SUPABASE_URL
   NEXT_PUBLIC_SUPABASE_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY
   NEXTAUTH_SECRET
   NEXT_PUBLIC_APP_URL (set to your Vercel domain)
   NODE_ENV (set to "production")
   ```

### Step 5: Deploy

1. **Initial Deployment**
   - Click "Deploy" button
   - Wait for the build process to complete
   - Monitor the build logs for any errors

2. **Verify Deployment**
   - Once deployed, you'll get a URL like `https://salla-supabase-sync.vercel.app`
   - Click "Visit" to test your application

## 🔧 Post-Deployment Configuration

### Update Salla Webhook URLs

1. **Go to Salla Partner Portal**
   - Navigate to your app settings
   - Update webhook URLs to point to your Vercel domain:
     ```
     https://your-app.vercel.app/api/webhooks/salla
     ```

2. **Test Webhook Endpoints**
   - Verify webhook signature validation
   - Test with sample webhook events

### Update Supabase Settings

1. **Update CORS Settings**
   - Add your Vercel domain to allowed origins
   - Update redirect URLs for authentication

2. **Update RLS Policies**
   - Ensure policies work with production environment
   - Test database connections

### Configure Custom Domain (Optional)

1. **Add Custom Domain**
   - Go to project settings in Vercel
   - Click "Domains"
   - Add your custom domain
   - Configure DNS records as instructed

2. **Update Environment Variables**
   - Update `NEXT_PUBLIC_APP_URL` to your custom domain
   - Update `NEXTAUTH_URL` to your custom domain

## 📊 Monitoring and Maintenance

### Vercel Analytics

1. **Enable Analytics**
   - Go to project settings
   - Enable Vercel Analytics
   - Monitor performance metrics

### Function Logs

1. **Monitor Function Logs**
   - Go to "Functions" tab in your project
   - Monitor API route performance
   - Check for errors and timeouts

### Cron Jobs Monitoring

1. **Monitor Scheduled Functions**
   - Check cron job execution in logs
   - Verify data synchronization is working
   - Monitor for failures

## 🚨 Troubleshooting

### Common Issues

1. **Build Failures**
   ```bash
   # Check for TypeScript errors
   npm run build
   
   # Fix any type errors
   npm run lint
   ```

2. **Environment Variable Issues**
   - Verify all required variables are set
   - Check variable names for typos
   - Ensure values are correct

3. **Database Connection Issues**
   - Verify Supabase URL and keys
   - Check database permissions
   - Test connection locally first

4. **Webhook Issues**
   - Verify webhook URLs are correct
   - Check webhook signature validation
   - Monitor webhook logs

### Debug Steps

1. **Check Build Logs**
   - Review build output in Vercel dashboard
   - Look for specific error messages

2. **Check Function Logs**
   - Monitor API route execution
   - Check for runtime errors

3. **Test Locally**
   ```bash
   # Test production build locally
   npm run build
   npm run start
   ```

## 🔄 Continuous Deployment

### Automatic Deployments

Vercel automatically deploys when you push to your main branch:

1. **Push Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin main
   ```

2. **Monitor Deployment**
   - Check Vercel dashboard for deployment status
   - Review build logs
   - Test deployed changes

### Preview Deployments

Vercel creates preview deployments for pull requests:

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git push origin feature/new-feature
   ```

2. **Create Pull Request**
   - Vercel automatically creates preview deployment
   - Test changes in preview environment
   - Merge when ready

## 📈 Performance Optimization

### Vercel Configuration

Our `vercel.json` includes optimizations:

- **Function Timeouts**: Extended for webhook processing
- **Caching**: Optimized for static assets
- **Security Headers**: Enhanced security
- **Redirects**: SEO-friendly URLs

### Monitoring Performance

1. **Core Web Vitals**
   - Monitor in Vercel Analytics
   - Optimize based on metrics

2. **Function Performance**
   - Monitor execution time
   - Optimize slow functions

## 🔐 Security Considerations

### Environment Variables
- Never commit secrets to repository
- Use Vercel's secure environment variable storage
- Rotate secrets regularly

### API Security
- Implement rate limiting
- Validate webhook signatures
- Use HTTPS only

### Database Security
- Use Row Level Security (RLS)
- Limit database permissions
- Monitor access logs

## 📞 Support

If you encounter issues during deployment:

1. **Check Documentation**
   - Review this deployment guide
   - Check Vercel documentation
   - Review project README

2. **Community Support**
   - Vercel Discord community
   - GitHub issues
   - Stack Overflow

3. **Professional Support**
   - Vercel Pro support (if subscribed)
   - Supabase support
   - Salla developer support

---

**Happy Deploying! 🚀**