
'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import CreateClassForm from '@/components/create-class-form';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function NewClassPage() {
  return (
    <div className="flex flex-col gap-8">
        <div className='flex items-center gap-4'>
            <Link href="/classes">
                <Button variant="outline" size="icon">
                    <ArrowLeft className="h-4 w-4" />
                </Button>
            </Link>
            <h1 className="font-headline text-3xl font-semibold">Crear Nueva Clase</h1>
        </div>
      
      <Card>
        <CardHeader>
          <CardTitle>Detalles de la Clase</CardTitle>
          <CardDescription>
            Completa la información a continuación para publicar tu nueva clase en la plataforma.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <CreateClassForm />
        </CardContent>
      </Card>
    </div>
  );
}
