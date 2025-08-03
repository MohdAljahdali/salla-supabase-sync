import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { AlertCircle, CheckCircle2 } from "lucide-react";

/**
 * Home page component demonstrating shadcn/ui integration
 * Tests Button and Card components functionality
 */
export default function Home() {
  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-4xl mx-auto space-y-8">
        {/* Header Section */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold text-foreground">
            Salla Supabase Sync Project
          </h1>
          <p className="text-lg text-muted-foreground">
            Next.js + Tailwind CSS + shadcn/ui Integration Test
          </p>
          <div className="flex justify-center gap-2">
            <Badge variant="default">Production Ready</Badge>
            <Badge variant="secondary">TypeScript</Badge>
            <Badge variant="outline">shadcn/ui</Badge>
          </div>
        </div>

        {/* Alert Section */}
        <div className="space-y-4">
          <Alert>
            <CheckCircle2 className="h-4 w-4" />
            <AlertTitle>تم التثبيت بنجاح!</AlertTitle>
            <AlertDescription>
              تم تثبيت وتكوين shadcn/ui بنجاح. جميع المكونات تعمل بشكل صحيح.
            </AlertDescription>
          </Alert>
          
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>تنبيه مهم</AlertTitle>
            <AlertDescription>
              تأكد من تكوين متغيرات البيئة قبل الانتقال للمرحلة التالية.
            </AlertDescription>
          </Alert>
        </div>

        {/* Cards Section */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <Card className="border-2 border-primary/20 hover:border-primary/40 transition-colors">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                Next.js 15
                <Badge variant="secondary">v15</Badge>
              </CardTitle>
              <CardDescription>
                Latest version with App Router and React Server Components
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Configured with TypeScript and optimized for performance.
              </p>
            </CardContent>
          </Card>

          <Card className="border-2 border-secondary/20 hover:border-secondary/40 transition-colors">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                Tailwind CSS v4
                <Badge variant="outline">CSS</Badge>
              </CardTitle>
              <CardDescription>
                Modern utility-first CSS framework
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Configured with CSS variables and dark mode support.
              </p>
            </CardContent>
          </Card>

          <Card className="border-2 border-accent/20 hover:border-accent/40 transition-colors">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                shadcn/ui
                <Badge variant="default">UI</Badge>
              </CardTitle>
              <CardDescription>
                Beautiful and accessible React components
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Built with Radix UI primitives and Tailwind CSS.
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Buttons Section */}
        <div className="space-y-4">
          <h2 className="text-2xl font-semibold text-center text-foreground">
            shadcn/ui Button Variants
          </h2>
          <div className="flex flex-wrap gap-4 justify-center">
            <Button variant="default" size="lg">
              Primary Button
            </Button>
            <Button variant="secondary" size="lg">
              Secondary Button
            </Button>
            <Button variant="outline" size="lg">
              Outline Button
            </Button>
            <Button variant="destructive" size="lg">
              Destructive Button
            </Button>
            <Button variant="ghost" size="lg">
              Ghost Button
            </Button>
            <Button variant="link" size="lg">
              Link Button
            </Button>
          </div>
          <div className="flex flex-wrap gap-2 justify-center">
            <Button size="sm">Small</Button>
            <Button size="default">Default</Button>
            <Button size="lg">Large</Button>
            <Button size="icon">🚀</Button>
          </div>
        </div>

        {/* Status Section */}
        <div className="text-center space-y-2">
          <p className="text-sm text-muted-foreground">
            ✅ Next.js 15 + TypeScript configured
          </p>
          <p className="text-sm text-muted-foreground">
            ✅ Tailwind CSS v4 installed and working
          </p>
          <p className="text-sm text-muted-foreground">
            ✅ shadcn/ui components ready to use
          </p>
        </div>
      </div>
    </div>
  );
}
