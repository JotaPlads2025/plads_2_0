
import type { Metadata, Viewport } from 'next';
import './globals.css';
import { poppins, ptSans } from './fonts';
import { cn } from '@/lib/utils';
import { ProvidersLayout } from '@/components/providers-layout';

export const metadata: Metadata = {
  title: 'Plads Pro',
  description: 'Instructor dashboard for Plads',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: 'cover',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" suppressHydrationWarning>
      <body
        className={cn(
          'font-body bg-background text-foreground antialiased',
          poppins.variable,
          ptSans.variable
        )}
      >
        <ProvidersLayout>{children}</ProvidersLayout>
      </body>
    </html>
  );
}
