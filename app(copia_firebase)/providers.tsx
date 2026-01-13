
'use client';

import { FirebaseClientProvider } from '@/firebase';
import AppShell from '@/components/AppShell';
import { ThemeProvider } from 'next-themes';
import React from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      disableTransitionOnChange
    >
      <FirebaseClientProvider>
          <AppShell>{children}</AppShell>
      </FirebaseClientProvider>
    </ThemeProvider>
  );
}
