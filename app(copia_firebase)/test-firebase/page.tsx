'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Loader2, Beaker, Check, ShieldAlert } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useFirestore, useUser } from '@/firebase';
import { addDoc, collection } from 'firebase/firestore';
import type { Booking } from '@/lib/types';
import Link from 'next/link';

export default function TestFirebasePage() {
  const [isBooking, setIsBooking] = useState(false);
  const { toast } = useToast();
  const firestore = useFirestore();
  const { user } = useUser();

  const handleTestBooking = async () => {
    if (!firestore) {
      toast({
        variant: 'destructive',
        title: 'Error de Firestore',
        description: 'No se pudo conectar con Firestore. Revisa la configuración.',
      });
      return;
    }
    if (!user) {
        toast({
            variant: 'destructive',
            title: 'Usuario no autenticado',
            description: 'Debes iniciar sesión para realizar esta prueba.',
          });
          return;
    }

    setIsBooking(true);

    const testBooking: Omit<Booking, 'id'> = {
        classId: 'test-class-001',
        className: 'Clase de Prueba',
        classLevel: 'Básico',
        instructorId: 'test-instructor-id',
        studentId: user.uid,
        studentName: user.displayName || 'Estudiante de Prueba',
        bookingDate: new Date().toISOString(),
        classDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // One week from now
        attendanceStatus: 'Confirmada',
    };

    try {
      const bookingsCollectionRef = collection(firestore, 'bookings');
      const docRef = await addDoc(bookingsCollectionRef, testBooking);
      
      toast({
        title: '¡Reserva de prueba exitosa!',
        description: (
          <div className="flex flex-col gap-2">
            <p>Documento de reserva creado en la colección /bookings.</p>
            <p className="font-mono text-xs bg-muted p-1 rounded">ID: {docRef.id}</p>
            <Link href="https://console.firebase.google.com/" target="_blank" className="w-full">
                <Button size="sm" className="w-full mt-2">
                    Ver en Consola de Firebase
                </Button>
            </Link>
          </div>
        ),
        duration: 10000,
      });

    } catch (error: any) {
        console.error("Error creating test booking:", error);
        if (error.code === 'permission-denied') {
             toast({
                variant: 'destructive',
                title: 'Error de Permisos en Firestore',
                description: 'No tienes permisos para escribir en /bookings. Revisa tus Reglas de Seguridad.',
            });
        } else {
            toast({
                variant: 'destructive',
                title: 'Error al crear la reserva de prueba',
                description: error.message || 'Hubo un problema al intentar escribir en Firestore.',
            });
        }
    } finally {
      setIsBooking(false);
    }
  };

  return (
    <div className="flex flex-col gap-8">
      <h1 className="font-headline text-3xl font-semibold">Página de Pruebas</h1>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Beaker className="h-6 w-6 text-primary" />
            Prueba de Creación de Reserva
          </CardTitle>
          <CardDescription>
            Este botón simula el proceso de reserva de un usuario. Creará un nuevo documento en la colección <code className="bg-muted px-1 py-0.5 rounded">/bookings</code> en tu base de datos de Firestore.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-start gap-4">
            {user ? (
                <div className="flex items-center gap-2 text-sm text-green-600 bg-green-50 dark:bg-green-900/20 p-3 rounded-md border border-green-200 dark:border-green-800">
                    <Check className="h-5 w-5"/>
                    <p>Sesión iniciada como <strong>{user.displayName}</strong>. ¡Listo para probar!</p>
                </div>
            ) : (
                <div className="flex items-center gap-2 text-sm text-amber-600 bg-amber-50 dark:bg-amber-900/20 p-3 rounded-md border border-amber-200 dark:border-amber-800">
                    <ShieldAlert className="h-5 w-5"/>
                    <p>Debes <Link href="/login" className="font-bold underline">iniciar sesión</Link> para poder realizar la prueba.</p>
                </div>
            )}
            <Button onClick={handleTestBooking} disabled={isBooking || !user}>
              {isBooking ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : (
                <Beaker className="mr-2 h-4 w-4" />
              )}
              Crear Reserva de Prueba
            </Button>
            <p className="text-sm text-muted-foreground">
              Después de hacer clic, ve a tu <a href="https://console.firebase.google.com/" target="_blank" rel="noopener noreferrer" className="text-primary underline">Consola de Firebase</a>
              , navega a Firestore Database y verifica que el nuevo documento exista en la colección `bookings`.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
