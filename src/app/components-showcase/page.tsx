import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { Separator } from "@/components/ui/separator";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Slider } from "@/components/ui/slider";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Toggle } from "@/components/ui/toggle";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { AlertCircle, CheckCircle2, User, Settings } from "lucide-react";

/**
 * Comprehensive showcase page for all shadcn/ui components
 * Demonstrates the full range of available UI components
 */
export default function ComponentsShowcase() {
  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-7xl mx-auto space-y-12">
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-5xl font-bold text-foreground">
            معرض مكونات shadcn/ui
          </h1>
          <p className="text-xl text-muted-foreground">
            جميع المكونات المتاحة في مكتبة shadcn/ui
          </p>
          <div className="flex justify-center gap-2">
            <Badge variant="default">46 مكون</Badge>
            <Badge variant="secondary">مثبت بالكامل</Badge>
            <Badge variant="outline">جاهز للاستخدام</Badge>
          </div>
        </div>

        {/* Alerts Section */}
        <section className="space-y-6">
          <h2 className="text-3xl font-semibold">التنبيهات والرسائل</h2>
          <div className="grid gap-4">
            <Alert>
              <CheckCircle2 className="h-4 w-4" />
              <AlertTitle>تم التثبيت بنجاح!</AlertTitle>
              <AlertDescription>
                تم تثبيت جميع مكونات shadcn/ui بنجاح (46 مكون).
              </AlertDescription>
            </Alert>
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertTitle>تنبيه مهم</AlertTitle>
              <AlertDescription>
                تأكد من قراءة التوثيق قبل استخدام المكونات المتقدمة.
              </AlertDescription>
            </Alert>
          </div>
        </section>

        {/* Form Components */}
        <section className="space-y-6">
          <h2 className="text-3xl font-semibold">مكونات النماذج</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>المدخلات الأساسية</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="email">البريد الإلكتروني</Label>
                  <Input id="email" type="email" placeholder="أدخل بريدك الإلكتروني" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="message">الرسالة</Label>
                  <Textarea id="message" placeholder="اكتب رسالتك هنا..." />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>الخيارات والتحديد</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>اختر البلد</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="اختر بلدك" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="sa">السعودية</SelectItem>
                      <SelectItem value="ae">الإمارات</SelectItem>
                      <SelectItem value="eg">مصر</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-3">
                  <Label>نوع الحساب</Label>
                  <RadioGroup defaultValue="personal">
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="personal" id="personal" />
                      <Label htmlFor="personal">شخصي</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="business" id="business" />
                      <Label htmlFor="business">تجاري</Label>
                    </div>
                  </RadioGroup>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>التبديل والخيارات</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center space-x-2">
                  <Checkbox id="terms" />
                  <Label htmlFor="terms">أوافق على الشروط والأحكام</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <Switch id="notifications" />
                  <Label htmlFor="notifications">تفعيل الإشعارات</Label>
                </div>
                <div className="space-y-2">
                  <Label>مستوى الصوت</Label>
                  <Slider defaultValue={[50]} max={100} step={1} />
                </div>
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Display Components */}
        <section className="space-y-6">
          <h2 className="text-3xl font-semibold">مكونات العرض</h2>
          <div className="grid gap-6">
            <Card>
              <CardHeader>
                <CardTitle>الشارات والأفاتار</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-4 flex-wrap">
                  <Avatar>
                    <AvatarImage src="https://github.com/shadcn.png" />
                    <AvatarFallback>CN</AvatarFallback>
                  </Avatar>
                  <div className="flex gap-2">
                    <Badge>افتراضي</Badge>
                    <Badge variant="secondary">ثانوي</Badge>
                    <Badge variant="outline">محدد</Badge>
                    <Badge variant="destructive">تدميري</Badge>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>شريط التقدم والهيكل العظمي</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>التقدم: 65%</Label>
                  <Progress value={65} />
                </div>
                <Separator />
                <div className="space-y-2">
                  <Label>تحميل المحتوى...</Label>
                  <div className="space-y-2">
                    <Skeleton className="h-4 w-full" />
                    <Skeleton className="h-4 w-3/4" />
                    <Skeleton className="h-4 w-1/2" />
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Interactive Components */}
        <section className="space-y-6">
          <h2 className="text-3xl font-semibold">المكونات التفاعلية</h2>
          <div className="grid gap-6">
            <Card>
              <CardHeader>
                <CardTitle>الأزرار والتبديل</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-4">
                  <Button>افتراضي</Button>
                  <Button variant="secondary">ثانوي</Button>
                  <Button variant="outline">محدد</Button>
                  <Button variant="ghost">شبح</Button>
                  <Button variant="link">رابط</Button>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Button variant="outline" size="icon">
                          <Settings className="h-4 w-4" />
                        </Button>
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>الإعدادات</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                  <Toggle aria-label="تبديل الخط المائل">
                    <User className="h-4 w-4" />
                  </Toggle>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>التبويبات</CardTitle>
              </CardHeader>
              <CardContent>
                <Tabs defaultValue="overview" className="w-full">
                  <TabsList className="grid w-full grid-cols-3">
                    <TabsTrigger value="overview">نظرة عامة</TabsTrigger>
                    <TabsTrigger value="analytics">التحليلات</TabsTrigger>
                    <TabsTrigger value="settings">الإعدادات</TabsTrigger>
                  </TabsList>
                  <TabsContent value="overview" className="space-y-4">
                    <p className="text-muted-foreground">
                      هذا محتوى تبويب النظرة العامة. يمكنك إضافة أي محتوى هنا.
                    </p>
                  </TabsContent>
                  <TabsContent value="analytics" className="space-y-4">
                    <p className="text-muted-foreground">
                      هذا محتوى تبويب التحليلات. يمكن عرض الرسوم البيانية والإحصائيات هنا.
                    </p>
                  </TabsContent>
                  <TabsContent value="settings" className="space-y-4">
                    <p className="text-muted-foreground">
                      هذا محتوى تبويب الإعدادات. يمكن إضافة خيارات التكوين هنا.
                    </p>
                  </TabsContent>
                </Tabs>
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Data Display */}
        <section className="space-y-6">
          <h2 className="text-3xl font-semibold">عرض البيانات</h2>
          <Card>
            <CardHeader>
              <CardTitle>جدول البيانات</CardTitle>
              <CardDescription>مثال على جدول بيانات باستخدام مكون Table</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>الاسم</TableHead>
                    <TableHead>البريد الإلكتروني</TableHead>
                    <TableHead>الحالة</TableHead>
                    <TableHead>تاريخ التسجيل</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <TableRow>
                    <TableCell>أحمد محمد</TableCell>
                    <TableCell>ahmed@example.com</TableCell>
                    <TableCell>
                      <Badge variant="default">نشط</Badge>
                    </TableCell>
                    <TableCell>2024-01-15</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>فاطمة علي</TableCell>
                    <TableCell>fatima@example.com</TableCell>
                    <TableCell>
                      <Badge variant="secondary">معلق</Badge>
                    </TableCell>
                    <TableCell>2024-01-10</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>محمد سالم</TableCell>
                    <TableCell>mohammed@example.com</TableCell>
                    <TableCell>
                      <Badge variant="outline">غير نشط</Badge>
                    </TableCell>
                    <TableCell>2024-01-05</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </section>

        {/* Summary */}
        <section className="text-center space-y-4">
          <h2 className="text-3xl font-semibold">ملخص المكونات المثبتة</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {[
              'Accordion', 'Alert', 'Alert Dialog', 'Aspect Ratio', 'Avatar', 'Badge',
              'Breadcrumb', 'Button', 'Calendar', 'Card', 'Carousel', 'Chart',
              'Checkbox', 'Collapsible', 'Command', 'Context Menu', 'Dialog', 'Drawer',
              'Dropdown Menu', 'Form', 'Hover Card', 'Input', 'Input OTP', 'Label',
              'Menubar', 'Navigation Menu', 'Pagination', 'Popover', 'Progress', 'Radio Group',
              'Resizable', 'Scroll Area', 'Select', 'Separator', 'Sheet', 'Sidebar',
              'Skeleton', 'Slider', 'Sonner', 'Switch', 'Table', 'Tabs',
              'Textarea', 'Toggle', 'Toggle Group', 'Tooltip'
            ].map((component) => (
              <Badge key={component} variant="outline" className="text-xs">
                {component}
              </Badge>
            ))}
          </div>
          <p className="text-lg text-muted-foreground mt-6">
            🎉 تم تثبيت جميع المكونات بنجاح! يمكنك الآن استخدام أي مكون من مكونات shadcn/ui في مشروعك.
          </p>
        </section>
      </div>
    </div>
  );
}